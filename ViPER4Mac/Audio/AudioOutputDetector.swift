import CoreAudio
import Foundation

private let logger = AppLogger(category: "AudioOutputDetector")

final class AudioOutputDetector {
  static let shared = AudioOutputDetector()

  enum OutputType: Int {
    case headphone = 0
    case speaker = 1
  }

  private(set) var currentOutputType: OutputType = .speaker
  var onOutputTypeChanged: ((OutputType) -> Void)?

  private var listenerInstalled = false

  private init() {
    currentOutputType = detectOutputType()
  }

  func start() {
    guard !listenerInstalled else { return }

    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    let selfPtr = Unmanaged.passUnretained(self).toOpaque()
    let status = AudioObjectAddPropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &addr,
      defaultDeviceChangedCallback,
      selfPtr
    )

    if status == noErr {
      listenerInstalled = true
      logger.info("Device change listener installed")
    } else {
      logger.error("Failed to install device listener: \(status)")
    }
  }

  func stop() {
    guard listenerInstalled else { return }

    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    let selfPtr = Unmanaged.passUnretained(self).toOpaque()
    AudioObjectRemovePropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &addr,
      defaultDeviceChangedCallback,
      selfPtr
    )
    listenerInstalled = false
  }

  func checkAndNotify() {
    let newType = detectOutputType()
    if newType != currentOutputType {
      logger.info("Output type changed: \(currentOutputType.rawValue) -> \(newType.rawValue)")
      currentOutputType = newType
      onOutputTypeChanged?(newType)
    }
  }

  private func detectOutputType() -> OutputType {
    let deviceID = getDefaultOutputDevice()
    guard deviceID != kAudioObjectUnknown else { return .speaker }

    let uid = getDeviceUID(deviceID)
    if uid == "ViPER4Mac_VirtualDevice" {
      return detectFromRealOutput()
    }

    return classifyDevice(deviceID)
  }

  private func detectFromRealOutput() -> OutputType {
    let engineOutput = AudioEngine.shared.outputDeviceID
    if engineOutput != kAudioObjectUnknown {
      return classifyDevice(engineOutput)
    }
    let devices = getAllDeviceIDs()
    let viperUID = "ViPER4Mac_VirtualDevice"
    for device in devices {
      if getDeviceUID(device) == viperUID { continue }
      if !hasOutputStreams(device) { continue }
      return classifyDevice(device)
    }
    return .speaker
  }

  private func classifyDevice(_ deviceID: AudioDeviceID) -> OutputType {
    let transportType = getTransportType(deviceID)

    switch transportType {
    case kAudioDeviceTransportTypeUSB:
      return .headphone
    case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
      return .headphone
    case kAudioDeviceTransportTypeBuiltIn:
      return classifyBuiltInDevice(deviceID)
    default:
      return .speaker
    }
  }

  private func classifyBuiltInDevice(_ deviceID: AudioDeviceID) -> OutputType {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDataSource,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSource: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)

    let status = AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &dataSource)
    guard status == noErr else { return .speaker }

    let hdpn = fourCharCode("hdpn")
    if dataSource == hdpn {
      return .headphone
    }
    return .speaker
  }

  private func fourCharCode(_ str: String) -> UInt32 {
    let chars = Array(str.utf8)
    guard chars.count == 4 else { return 0 }
    return UInt32(chars[0]) << 24 | UInt32(chars[1]) << 16 | UInt32(chars[2]) << 8
      | UInt32(chars[3])
  }

  // MARK: - CoreAudio Helpers

  private func getDefaultOutputDevice() -> AudioDeviceID {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var deviceID: AudioDeviceID = kAudioObjectUnknown
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID
    )
    return deviceID
  }

  private func getTransportType(_ deviceID: AudioDeviceID) -> UInt32 {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyTransportType,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var transportType: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &transportType)
    return transportType
  }

  private func getDeviceUID(_ deviceID: AudioDeviceID) -> String {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceUID,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var uid: CFString = "" as CFString
    var size = UInt32(MemoryLayout<CFString>.size)
    guard AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &uid) == noErr else {
      return ""
    }
    return uid as String
  }

  private func getAllDeviceIDs() -> [AudioDeviceID] {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize
    ) == noErr
    else { return [] }

    let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize, &deviceIDs
    ) == noErr
    else { return [] }
    return deviceIDs
  }

  private func hasOutputStreams(_ deviceID: AudioDeviceID) -> Bool {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreams,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(deviceID, &addr, 0, nil, &dataSize) == noErr else {
      return false
    }
    return dataSize > 0
  }
}

private let defaultDeviceChangedCallback: AudioObjectPropertyListenerProc = {
  _, _, _, clientData -> OSStatus in
  guard let clientData else { return noErr }
  let detector = Unmanaged<AudioOutputDetector>.fromOpaque(clientData).takeUnretainedValue()

  DispatchQueue.main.async {
    detector.checkAndNotify()
  }

  return noErr
}
