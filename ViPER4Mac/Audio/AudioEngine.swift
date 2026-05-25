import Accelerate
import AudioToolbox
import CoreAudio
import Foundation

private let logger = AppLogger(category: "AudioEngine")

final class AudioEngine {
  static let shared = AudioEngine()

  let viperBridge = ViPERBridge()

  private(set) var outputDeviceID: AudioDeviceID = kAudioObjectUnknown
  private let channelCount: UInt32 = 2

  private var isRunning = false
  private var deviceListenerInstalled = false
  private var deviceListChangedListenerInstalled = false
  var onOutputDeviceChanged: (() -> Void)?

  var processingEnabled = true

  private var tapID: AudioObjectID = kAudioObjectUnknown
  private var aggregateDeviceID: AudioObjectID = kAudioObjectUnknown
  private var ioProcID: AudioDeviceIOProcID?
  private var tapUUID: NSUUID?

  private var callbackCount: UInt64 = 0

  private init() {}

  deinit {
    stop()
  }

  // MARK: - Public Interface

  func start() {
    guard !isRunning else { return }

    guard let realDevice = findRealOutputDevice() else {
      logger.error("No real output device found.")
      return
    }
    outputDeviceID = realDevice

    let sampleRate = getSampleRate(for: outputDeviceID)
    viperBridge.setSamplingRate(UInt32(sampleRate))
    logger.info("AudioEngine: output=\(realDevice) rate=\(sampleRate)")

    guard createTap() else {
      logger.error("Failed to create process tap")
      return
    }

    guard createAggregateDevice() else {
      logger.error("Failed to create aggregate device")
      destroyTap()
      return
    }

    guard createIOProc() else {
      logger.error("Failed to create IOProc")
      destroyAggregateDevice()
      destroyTap()
      return
    }

    let status = AudioDeviceStart(aggregateDeviceID, ioProcID!)
    if status != noErr {
      logger.error("AudioDeviceStart failed: \(status)")
      destroyIOProc()
      destroyAggregateDevice()
      destroyTap()
      return
    }

    isRunning = true
    installDeviceListListener()
    logger.info(
      "Audio engine started. Output=\(outputDeviceID) DSP=\(processingEnabled)"
    )
  }

  func stop() {
    guard isRunning else { return }

    removeDeviceListListener()
    teardownPipeline()

    isRunning = false
    callbackCount = 0
    logger.info("Audio engine stopped")
  }

  var outputDeviceName: String {
    guard outputDeviceID != kAudioObjectUnknown else { return "None" }
    return getDeviceName(outputDeviceID)
  }

  // MARK: - Process Tap

  private func getCurrentProcessObjectID() -> AudioObjectID? {
    var addr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var pid = pid_t(ProcessInfo.processInfo.processIdentifier)
    var processObjectID: AudioObjectID = kAudioObjectUnknown
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    let status = AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &addr,
      UInt32(MemoryLayout<pid_t>.size),
      &pid,
      &size,
      &processObjectID
    )
    if status != noErr {
      logger.error("TranslatePIDToProcessObject failed: \(status)")
      return nil
    }
    return processObjectID
  }

  private func createTap() -> Bool {
    guard let processObjID = getCurrentProcessObjectID() else {
      logger.error("Could not get process object ID for current process")
      return false
    }

    let desc = CATapDescription(
      __stereoGlobalTapButExcludeProcesses: [NSNumber(value: processObjID)]
    )
    desc.muteBehavior = .muted
    desc.isPrivate = true
    desc.name = "ViPER4Mac Tap"

    tapUUID = desc.uuid as NSUUID

    var newTapID: AudioObjectID = kAudioObjectUnknown
    let status = AudioHardwareCreateProcessTap(desc, &newTapID)
    if status != noErr {
      logger.error("AudioHardwareCreateProcessTap failed: \(status)")
      return false
    }
    tapID = newTapID
    logger.info("Process tap created: \(tapID) uuid=\(desc.uuid.uuidString)")
    return true
  }

  private func destroyTap() {
    guard tapID != kAudioObjectUnknown else { return }
    let status = AudioHardwareDestroyProcessTap(tapID)
    if status != noErr {
      logger.error("AudioHardwareDestroyProcessTap failed: \(status)")
    }
    tapID = kAudioObjectUnknown
    tapUUID = nil
  }

  // MARK: - Aggregate Device

  private func createAggregateDevice() -> Bool {
    guard let uuid = tapUUID else {
      logger.error("No tap UUID available")
      return false
    }

    let outputUID = getDeviceUID(outputDeviceID)
    guard !outputUID.isEmpty else {
      logger.error("Could not get UID for output device \(outputDeviceID)")
      return false
    }

    let tapDict: [String: Any] = [
      kAudioSubTapUIDKey: uuid.uuidString,
      kAudioSubTapDriftCompensationKey: 1,
    ]

    let subDeviceDict: [String: Any] = [
      kAudioSubDeviceUIDKey: outputUID,
    ]

    let aggDesc: [String: Any] = [
      kAudioAggregateDeviceNameKey: "ViPER4Mac Aggregate",
      kAudioAggregateDeviceUIDKey: "com.viper4mac.aggregate.\(UUID().uuidString)",
      kAudioAggregateDeviceMainSubDeviceKey: outputUID,
      kAudioAggregateDeviceIsPrivateKey: true,
      kAudioAggregateDeviceTapAutoStartKey: true,
      kAudioAggregateDeviceTapListKey: [tapDict],
      kAudioAggregateDeviceSubDeviceListKey: [subDeviceDict],
    ]

    var newAggID: AudioObjectID = kAudioObjectUnknown
    let status = AudioHardwareCreateAggregateDevice(aggDesc as CFDictionary, &newAggID)
    if status != noErr {
      logger.error("AudioHardwareCreateAggregateDevice failed: \(status)")
      return false
    }
    aggregateDeviceID = newAggID
    logger.info("Aggregate device created: \(aggregateDeviceID) mainSub=\(outputUID)")
    return true
  }

  private func destroyAggregateDevice() {
    guard aggregateDeviceID != kAudioObjectUnknown else { return }
    let status = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
    if status != noErr {
      logger.error("AudioHardwareDestroyAggregateDevice failed: \(status)")
    }
    aggregateDeviceID = kAudioObjectUnknown
  }

  // MARK: - IOProc

  private func createIOProc() -> Bool {
    var procID: AudioDeviceIOProcID?

    let ch = Int(channelCount)

    let status = AudioDeviceCreateIOProcIDWithBlock(
      &procID,
      aggregateDeviceID,
      nil
    ) { [weak self] _, inInputData, _, outOutputData, _ in
      guard let self else { return }

      self.callbackCount += 1

      let inABL = UnsafeMutableAudioBufferListPointer(
        UnsafeMutablePointer(mutating: inInputData)
      )
      let outABL = UnsafeMutableAudioBufferListPointer(outOutputData)

      guard let inBuf = inABL.first,
            let outBuf = outABL.first,
            let inData = inBuf.mData,
            let outData = outBuf.mData
      else { return }

      let outBytes = Int(outBuf.mDataByteSize)
      let inBytes = Int(inBuf.mDataByteSize)
      let copyBytes = min(inBytes, outBytes)

      memcpy(outData, inData, copyBytes)

      let frameCount = copyBytes / (MemoryLayout<Float>.size * ch)
      let sampleCount = frameCount * ch
      let floatPtr = outData.assumingMemoryBound(to: Float.self)

      var maxSample: Float = 0.0
      vDSP_maxmgv(floatPtr, 1, &maxSample, vDSP_Length(sampleCount))

      let hasAudio = maxSample > 1e-6
      if self.processingEnabled && hasAudio {
        self.viperBridge.processAudio(floatPtr, frameCount: UInt32(frameCount))
      }

      if self.callbackCount % 5000 == 1 {
        let fillLevel = inBytes > 0 ? (copyBytes * 100 / inBytes) : 0
        logger.debug(
          "IOPROC: frames=\(frameCount) fill=\(fillLevel)% max=\(maxSample)"
        )
      }
    }

    if status != noErr {
      logger.error("AudioDeviceCreateIOProcIDWithBlock failed: \(status)")
      return false
    }
    ioProcID = procID
    return true
  }

  private func destroyIOProc() {
    guard let procID = ioProcID else { return }
    AudioDeviceDestroyIOProcID(aggregateDeviceID, procID)
    ioProcID = nil
  }

  // MARK: - Pipeline Teardown

  private func teardownPipeline() {
    if let procID = ioProcID {
      AudioDeviceStop(aggregateDeviceID, procID)
    }
    destroyIOProc()
    destroyAggregateDevice()
    destroyTap()
  }

  // MARK: - Device Change Handling

  private func installDeviceListListener() {
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    if !deviceListenerInstalled {
      var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      let status = AudioObjectAddPropertyListener(
        AudioObjectID(kAudioObjectSystemObject),
        &addr,
        engineDeviceChangedCallback,
        selfPtr
      )
      if status == noErr {
        deviceListenerInstalled = true
      } else {
        logger.error("Failed to install default device listener: \(status)")
      }
    }

    if !deviceListChangedListenerInstalled {
      var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      let status = AudioObjectAddPropertyListener(
        AudioObjectID(kAudioObjectSystemObject),
        &addr,
        engineDeviceListChangedCallback,
        selfPtr
      )
      if status == noErr {
        deviceListChangedListenerInstalled = true
      } else {
        logger.error("Failed to install device list listener: \(status)")
      }
    }

    logger.info("Engine device listeners installed")
  }

  private func removeDeviceListListener() {
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    if deviceListenerInstalled {
      var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      AudioObjectRemovePropertyListener(
        AudioObjectID(kAudioObjectSystemObject),
        &addr,
        engineDeviceChangedCallback,
        selfPtr
      )
      deviceListenerInstalled = false
    }

    if deviceListChangedListenerInstalled {
      var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      AudioObjectRemovePropertyListener(
        AudioObjectID(kAudioObjectSystemObject),
        &addr,
        engineDeviceListChangedCallback,
        selfPtr
      )
      deviceListChangedListenerInstalled = false
    }
  }

  func handleDefaultDeviceChanged() {
    guard isRunning else { return }
    let newDefault = getDefaultOutputDevice()

    if newDefault == outputDeviceID { return }
    if !hasOutputStreams(newDefault) { return }
    if !isDeviceAlive(newDefault) {
      logger.info("Ignoring change to dead device: \(getDeviceName(newDefault))")
      return
    }
    switchOutputDevice(to: newDefault)
  }

  func handleDeviceListChanged() {
    guard isRunning else { return }

    let allDevices = getAllDeviceIDs()
    let outputStillExists =
      allDevices.contains(outputDeviceID)
        && hasOutputStreams(outputDeviceID)
        && isDeviceAlive(outputDeviceID)

    if outputStillExists {
      let newDefault = getDefaultOutputDevice()
      if newDefault != outputDeviceID
        && hasOutputStreams(newDefault)
        && isDeviceAlive(newDefault)
      {
        switchOutputDevice(to: newDefault)
      }
      return
    }

    guard let fallback = findRealOutputDevice() else {
      logger.error("Device disappeared but no fallback output found")
      return
    }

    logger.info(
      "Output device disappeared: \(getDeviceName(outputDeviceID)) -> \(getDeviceName(fallback))"
    )
    switchOutputDevice(to: fallback)
  }

  func switchOutputDevice(to newDevice: AudioDeviceID) {
    let oldName = getDeviceName(outputDeviceID)
    let newName = getDeviceName(newDevice)
    logger.info("Switching output: \(oldName) -> \(newName)")

    teardownPipeline()

    outputDeviceID = newDevice

    let sampleRate = getSampleRate(for: outputDeviceID)
    viperBridge.setSamplingRate(UInt32(sampleRate))

    guard createTap() else {
      logger.error("Failed to create tap for new device")
      return
    }

    guard createAggregateDevice() else {
      logger.error("Failed to create aggregate device for new device")
      destroyTap()
      return
    }

    guard createIOProc() else {
      logger.error("Failed to create IOProc for new device")
      destroyAggregateDevice()
      destroyTap()
      return
    }

    let status = AudioDeviceStart(aggregateDeviceID, ioProcID!)
    if status != noErr {
      logger.error("Failed to start aggregate device for new device: \(status)")
      destroyIOProc()
      destroyAggregateDevice()
      destroyTap()
      return
    }

    callbackCount = 0
    onOutputDeviceChanged?()
    logger.info("Output re-routed to \(newName) rate=\(sampleRate)")
  }

  // MARK: - Device Discovery

  private func findRealOutputDevice() -> AudioDeviceID? {
    let currentDefault = getDefaultOutputDevice()
    if hasOutputStreams(currentDefault)
      && isDeviceAlive(currentDefault)
    {
      return currentDefault
    }

    let deviceIDs = getAllDeviceIDs()
    for deviceID in deviceIDs {
      if hasOutputStreams(deviceID) && isDeviceAlive(deviceID) {
        return deviceID
      }
    }
    return nil
  }

  private func getAllDeviceIDs() -> [AudioDeviceID] {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize
    ) == noErr
    else { return [] }

    let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize, &deviceIDs
    ) == noErr
    else { return [] }

    return deviceIDs
  }

  private func getDeviceUID(_ deviceID: AudioDeviceID) -> String {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceUID,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var uid: CFString = "" as CFString
    var dataSize = UInt32(MemoryLayout<CFString>.size)
    guard AudioObjectGetPropertyData(
      deviceID, &propAddr, 0, nil, &dataSize, &uid
    ) == noErr
    else { return "" }
    return uid as String
  }

  private func hasOutputStreams(_ deviceID: AudioDeviceID) -> Bool {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreams,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
      deviceID, &propAddr, 0, nil, &dataSize
    ) == noErr
    else { return false }
    return dataSize > 0
  }

  private func isDeviceAlive(_ deviceID: AudioDeviceID) -> Bool {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceIsAlive,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var isAlive: UInt32 = 0
    var dataSize = UInt32(MemoryLayout<UInt32>.size)
    let status = AudioObjectGetPropertyData(deviceID, &propAddr, 0, nil, &dataSize, &isAlive)
    if status != noErr { return false }
    return isAlive != 0
  }

  private func getDefaultOutputDevice() -> AudioDeviceID {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var deviceID: AudioDeviceID = kAudioObjectUnknown
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize, &deviceID
    )
    return deviceID
  }

  private func getSampleRate(for deviceID: AudioDeviceID) -> Float64 {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyNominalSampleRate,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var sampleRate: Float64 = 48000.0
    var dataSize = UInt32(MemoryLayout<Float64>.size)
    AudioObjectGetPropertyData(deviceID, &propAddr, 0, nil, &dataSize, &sampleRate)
    return sampleRate
  }

  func getDeviceName(_ deviceID: AudioDeviceID) -> String {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioObjectPropertyName,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var name: CFString = "" as CFString
    var dataSize = UInt32(MemoryLayout<CFString>.size)
    guard AudioObjectGetPropertyData(
      deviceID, &propAddr, 0, nil, &dataSize, &name
    ) == noErr
    else { return "Unknown" }
    return name as String
  }
}

// MARK: - Engine Device Change Callback

private let engineDeviceChangedCallback: AudioObjectPropertyListenerProc = {
  _, _, _, clientData -> OSStatus in
  guard let clientData else { return noErr }
  let engine = Unmanaged<AudioEngine>.fromOpaque(clientData).takeUnretainedValue()

  DispatchQueue.main.async {
    engine.handleDefaultDeviceChanged()
  }

  return noErr
}

private let engineDeviceListChangedCallback: AudioObjectPropertyListenerProc = {
  _, _, _, clientData -> OSStatus in
  guard let clientData else { return noErr }
  let engine = Unmanaged<AudioEngine>.fromOpaque(clientData).takeUnretainedValue()

  DispatchQueue.main.async {
    engine.handleDeviceListChanged()
  }

  return noErr
}
