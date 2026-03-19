import AudioToolbox
import CoreAudio
import Foundation

private let logger = AppLogger(category: "AudioEngine")

private let kOutputBus: AudioUnitElement = 0

struct OutputDeviceInfo: Identifiable, Equatable {
  let id: AudioDeviceID
  let name: String
  let uid: String
}

final class AudioEngine {
  static let shared = AudioEngine()

  let viperBridge = ViPERBridge()
  private let viperDeviceUID = "ViPER4Mac_VirtualDevice" as CFString

  private var inputDeviceID: AudioDeviceID = kAudioObjectUnknown
  private(set) var outputDeviceID: AudioDeviceID = kAudioObjectUnknown
  private var originalDefaultDeviceID: AudioDeviceID = kAudioObjectUnknown

  private var outputUnit: AudioUnit?
  private var inputIOProcID: AudioDeviceIOProcID?

  private var isRunning = false
  private var settingDevice = false
  private var deviceListenerInstalled = false
  private var deviceListChangedListenerInstalled = false
  private var volumeListenerInstalled = false
  var onOutputDeviceChanged: (() -> Void)?

  var processingEnabled = true {
    didSet {
      guard isRunning, processingEnabled != oldValue else { return }
      if processingEnabled {
        settingDevice = true
        setDefaultOutputDevice(inputDeviceID)
        setDefaultSystemOutputDevice(inputDeviceID)
        settingDevice = false
      } else {
        settingDevice = true
        setDefaultOutputDevice(outputDeviceID)
        setDefaultSystemOutputDevice(outputDeviceID)
        settingDevice = false
      }
    }
  }

  fileprivate var inputCallbackCount: UInt64 = 0
  fileprivate var outputCallbackCount: UInt64 = 0

  private var ringBuffer: UnsafeMutablePointer<Float>?
  private let ringCapacityFrames = 16384
  let channelCount: UInt32 = 2
  private var ringWritePos: Int = 0
  private var ringReadPos: Int = 0
  private var ringLock = os_unfair_lock()

  private var inputASBD = AudioStreamBasicDescription()
  fileprivate var sharedRingPtr: UnsafeMutableRawPointer?
  private let shmSize: Int =
    MemoryLayout<UInt64>.size * 2 + 16384 * 2 * MemoryLayout<Float>.size
  fileprivate var lastNonSilentTime: UInt64 = 0

  fileprivate var dspTempBuffer: UnsafeMutablePointer<Float>?
  private let dspTempBufferFrames = 4096

  private init() {
    let totalSamples = ringCapacityFrames * Int(channelCount)
    ringBuffer = UnsafeMutablePointer<Float>.allocate(capacity: totalSamples)
    ringBuffer?.initialize(repeating: 0.0, count: totalSamples)

    let tempSamples = dspTempBufferFrames * Int(channelCount)
    dspTempBuffer = UnsafeMutablePointer<Float>.allocate(capacity: tempSamples)
    dspTempBuffer?.initialize(repeating: 0.0, count: tempSamples)
  }

  deinit {
    stop()
    ringBuffer?.deallocate()
    dspTempBuffer?.deallocate()
  }

  func start() {
    guard !isRunning else { return }

    guard let viperDevice = findViPERDevice() else {
      logger.error("Virtual device not found. Is the driver installed?")
      return
    }
    inputDeviceID = viperDevice

    let currentDefault = getDefaultOutputDevice()
    let viperUID = viperDeviceUID as String
    if getDeviceUID(currentDefault) != viperUID {
      originalDefaultDeviceID = currentDefault
    }

    guard let realDevice = findRealOutputDevice() else {
      logger.error("No real output device found.")
      return
    }
    outputDeviceID = realDevice

    if originalDefaultDeviceID == kAudioObjectUnknown {
      originalDefaultDeviceID = realDevice
    }

    matchSampleRates()
    let sampleRate = getSampleRate(for: outputDeviceID)
    viperBridge.setSamplingRate(UInt32(sampleRate))
    logger.info("AudioEngine: virtual=\(viperDevice) output=\(realDevice) rate=\(sampleRate)")

    mapSharedMemory()

    guard setupInputIOProc() else {
      logger.error("Input IOProc setup failed")
      return
    }

    let sRate = getSampleRate(for: outputDeviceID)
    inputASBD.mSampleRate = sRate
    inputASBD.mFormatID = kAudioFormatLinearPCM
    inputASBD.mFormatFlags =
      kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked
    inputASBD.mBitsPerChannel = 32
    inputASBD.mChannelsPerFrame = channelCount
    inputASBD.mBytesPerFrame = channelCount * UInt32(MemoryLayout<Float>.size)
    inputASBD.mFramesPerPacket = 1
    inputASBD.mBytesPerPacket = inputASBD.mBytesPerFrame

    guard setupOutputUnit() else {
      logger.error("Output AUHAL setup failed")
      teardownInputIOProc()
      return
    }

    settingDevice = true
    setDefaultOutputDevice(inputDeviceID)
    setDefaultSystemOutputDevice(inputDeviceID)
    settingDevice = false

    var status = AudioDeviceStart(inputDeviceID, inputIOProcID!)
    if status != noErr {
      logger.error("AudioDeviceStart failed: \(status)")
      settingDevice = true
      setDefaultOutputDevice(outputDeviceID)
      setDefaultSystemOutputDevice(outputDeviceID)
      settingDevice = false
      teardownInputIOProc()
      disposeOutputUnit()
      return
    }

    status = AudioOutputUnitStart(outputUnit!)
    if status != noErr {
      logger.error("AudioOutputUnitStart failed: \(status)")
      AudioDeviceStop(inputDeviceID, inputIOProcID!)
      settingDevice = true
      setDefaultOutputDevice(outputDeviceID)
      setDefaultSystemOutputDevice(outputDeviceID)
      settingDevice = false
      teardownInputIOProc()
      disposeOutputUnit()
      return
    }

    isRunning = true
    installDeviceListListener()
    installVolumeListeners()
    logger.info(
      "Audio engine started. Virtual=\(inputDeviceID) Output=\(outputDeviceID) DSP=\(processingEnabled)"
    )
  }

  func stop() {
    guard isRunning else { return }

    removeDeviceListListener()
    removeVolumeListeners()

    if let procID = inputIOProcID {
      AudioDeviceStop(inputDeviceID, procID)
    }
    if let unit = outputUnit {
      AudioOutputUnitStop(unit)
    }

    teardownInputIOProc()
    disposeOutputUnit()
    unmapSharedMemory()

    var restoreDevice = originalDefaultDeviceID
    let viperUID = viperDeviceUID as String
    if restoreDevice == kAudioObjectUnknown || getDeviceUID(restoreDevice) == viperUID {
      restoreDevice = outputDeviceID
    }
    if restoreDevice != kAudioObjectUnknown && getDeviceUID(restoreDevice) != viperUID {
      settingDevice = true
      setDefaultOutputDevice(restoreDevice)
      setDefaultSystemOutputDevice(restoreDevice)
      settingDevice = false
    }

    ringWritePos = 0
    ringReadPos = 0
    inputCallbackCount = 0
    outputCallbackCount = 0

    isRunning = false
    logger.info("Audio engine stopped, restored output to device \(restoreDevice)")
  }

  // MARK: - Shared Memory

  private func mapSharedMemory() {
    let fd = Darwin.open("/tmp/com.viper4mac.shm", O_RDWR)
    if fd < 0 {
      logger.error("open shm file failed: \(errno)")
      return
    }
    let ptr = Darwin.mmap(nil, shmSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    Darwin.close(fd)
    if ptr == MAP_FAILED {
      logger.error("mmap failed: \(errno)")
      return
    }
    sharedRingPtr = ptr
    logger.info("Shared memory mapped, size=\(shmSize)")
  }

  private func unmapSharedMemory() {
    if let ptr = sharedRingPtr {
      munmap(ptr, shmSize)
      sharedRingPtr = nil
    }
  }

  // MARK: - Input via IOProc (captures from virtual device)

  private func setupInputIOProc() -> Bool {
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    var procID: AudioDeviceIOProcID?
    let status = AudioDeviceCreateIOProcID(
      inputDeviceID,
      inputIOProcCallback,
      selfPtr,
      &procID
    )
    if status != noErr {
      logger.error("setupInputIOProc: CreateIOProcID err=\(status)")
      return false
    }
    inputIOProcID = procID
    return true
  }

  private func teardownInputIOProc() {
    if let procID = inputIOProcID {
      AudioDeviceDestroyIOProcID(inputDeviceID, procID)
      inputIOProcID = nil
    }
  }

  // MARK: - Output AUHAL (plays to real device)

  private func setupOutputUnit() -> Bool {
    var desc = AudioComponentDescription(
      componentType: kAudioUnitType_Output,
      componentSubType: kAudioUnitSubType_HALOutput,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )

    guard let component = AudioComponentFindNext(nil, &desc) else {
      logger.error("setupOutputUnit: component not found")
      return false
    }

    var unit: AudioUnit?
    var status = AudioComponentInstanceNew(component, &unit)
    guard status == noErr, let unit else {
      logger.error("setupOutputUnit: instance err=\(status)")
      return false
    }

    var deviceID = outputDeviceID
    status = AudioUnitSetProperty(
      unit,
      kAudioOutputUnitProperty_CurrentDevice,
      kAudioUnitScope_Global,
      kOutputBus,
      &deviceID,
      UInt32(MemoryLayout<AudioDeviceID>.size)
    )
    if status != noErr {
      logger.error("setupOutputUnit: SetDevice err=\(status)")
      AudioComponentInstanceDispose(unit)
      return false
    }

    var asbd = inputASBD
    status = AudioUnitSetProperty(
      unit,
      kAudioUnitProperty_StreamFormat,
      kAudioUnitScope_Input,
      kOutputBus,
      &asbd,
      UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    )
    if status != noErr {
      logger.error("setupOutputUnit: SetStreamFormat err=\(status)")
      AudioComponentInstanceDispose(unit)
      return false
    }

    let selfPtr = Unmanaged.passUnretained(self).toOpaque()
    var callbackStruct = AURenderCallbackStruct(
      inputProc: outputCallback,
      inputProcRefCon: selfPtr
    )
    status = AudioUnitSetProperty(
      unit,
      kAudioUnitProperty_SetRenderCallback,
      kAudioUnitScope_Input,
      kOutputBus,
      &callbackStruct,
      UInt32(MemoryLayout<AURenderCallbackStruct>.size)
    )
    if status != noErr {
      logger.error("setupOutputUnit: SetRenderCallback err=\(status)")
      AudioComponentInstanceDispose(unit)
      return false
    }

    status = AudioUnitInitialize(unit)
    if status != noErr {
      logger.error("setupOutputUnit: Initialize err=\(status)")
      AudioComponentInstanceDispose(unit)
      return false
    }

    outputUnit = unit
    return true
  }

  // MARK: - Dispose

  private func disposeOutputUnit() {
    if let unit = outputUnit {
      AudioUnitUninitialize(unit)
      AudioComponentInstanceDispose(unit)
      outputUnit = nil
    }
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

  private func installVolumeListeners() {
    guard inputDeviceID != kAudioObjectUnknown else { return }
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    var volAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyVolumeScalar,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var muteAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )

    let s1 = AudioObjectAddPropertyListener(
      inputDeviceID, &volAddr, engineVolumeChangedCallback, selfPtr
    )
    let s2 = AudioObjectAddPropertyListener(
      inputDeviceID, &muteAddr, engineVolumeChangedCallback, selfPtr
    )
    if s1 == noErr && s2 == noErr {
      volumeListenerInstalled = true
      logger.info("Volume/mute listeners installed on virtual device")
    } else {
      logger.error("Failed to install volume listeners: vol=\(s1) mute=\(s2)")
    }

    syncVolumeToOutput()
  }

  private func removeVolumeListeners() {
    guard volumeListenerInstalled, inputDeviceID != kAudioObjectUnknown else { return }
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    var volAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyVolumeScalar,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var muteAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )

    AudioObjectRemovePropertyListener(inputDeviceID, &volAddr, engineVolumeChangedCallback, selfPtr)
    AudioObjectRemovePropertyListener(
      inputDeviceID, &muteAddr, engineVolumeChangedCallback, selfPtr
    )
    volumeListenerInstalled = false
  }

  func syncVolumeToOutput() {
    guard inputDeviceID != kAudioObjectUnknown,
          outputDeviceID != kAudioObjectUnknown
    else { return }

    var volAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyVolumeScalar,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var volume: Float32 = 1.0
    var size = UInt32(MemoryLayout<Float32>.size)
    AudioObjectGetPropertyData(inputDeviceID, &volAddr, 0, nil, &size, &volume)

    var muteAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var muted: UInt32 = 0
    var muteSize = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectGetPropertyData(inputDeviceID, &muteAddr, 0, nil, &muteSize, &muted)

    var outVolAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyVolumeScalar,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var outMuteAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioObjectPropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )

    AudioObjectSetPropertyData(
      outputDeviceID, &outVolAddr, 0, nil,
      UInt32(MemoryLayout<Float32>.size), &volume
    )
    AudioObjectSetPropertyData(
      outputDeviceID, &outMuteAddr, 0, nil,
      UInt32(MemoryLayout<UInt32>.size), &muted
    )

    logger.info("Volume synced to output: vol=\(volume) muted=\(muted)")
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
    guard isRunning, !settingDevice else { return }
    let newDefault = getDefaultOutputDevice()
    let viperUID = viperDeviceUID as String

    if getDeviceUID(newDefault) == viperUID {
      if processingEnabled {
        return
      }
      guard let fallback = findRealOutputDevice() else {
        logger.error("No fallback output found")
        return
      }
      if fallback == outputDeviceID { return }
      switchOutputDevice(to: fallback)
      return
    }

    if newDefault == outputDeviceID { return }
    if !hasOutputStreams(newDefault) { return }
    if !isDeviceAlive(newDefault) {
      logger.info("Ignoring change to dead device: \(getDeviceName(newDefault))")
      return
    }
    switchOutputDevice(to: newDefault)
  }

  func handleDeviceListChanged() {
    guard isRunning, !settingDevice else { return }

    let viperUID = viperDeviceUID as String
    let allDevices = getAllDeviceIDs()
    let outputStillExists =
      allDevices.contains(outputDeviceID)
        && hasOutputStreams(outputDeviceID)
        && getDeviceUID(outputDeviceID) != viperUID
        && isDeviceAlive(outputDeviceID)

    if outputStillExists {
      let newDefault = getDefaultOutputDevice()
      if getDeviceUID(newDefault) != viperUID
        && newDefault != outputDeviceID
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

    if let unit = outputUnit {
      AudioOutputUnitStop(unit)
    }
    disposeOutputUnit()

    outputDeviceID = newDevice
    originalDefaultDeviceID = newDevice

    matchSampleRates()
    let sampleRate = getSampleRate(for: outputDeviceID)
    viperBridge.setSamplingRate(UInt32(sampleRate))
    inputASBD.mSampleRate = sampleRate

    guard setupOutputUnit() else {
      logger.error("Failed to setup output unit for new device")
      return
    }

    let status = AudioOutputUnitStart(outputUnit!)
    if status != noErr {
      logger.error("Failed to start output unit for new device: \(status)")
      disposeOutputUnit()
      return
    }

    os_unfair_lock_lock(&ringLock)
    ringWritePos = 0
    ringReadPos = 0
    os_unfair_lock_unlock(&ringLock)

    if processingEnabled {
      settingDevice = true
      setDefaultOutputDevice(inputDeviceID)
      setDefaultSystemOutputDevice(inputDeviceID)
      settingDevice = false
    }

    onOutputDeviceChanged?()
    logger.info("Output re-routed to \(newName) rate=\(sampleRate)")
  }

  // MARK: - Ring Buffer

  fileprivate func writeToRing(_ data: UnsafePointer<Float>, frameCount: Int) {
    guard let ring = ringBuffer else { return }
    let samplesToWrite = frameCount * Int(channelCount)
    let capacity = ringCapacityFrames * Int(channelCount)

    os_unfair_lock_lock(&ringLock)
    for i in 0 ..< samplesToWrite {
      ring[(ringWritePos + i) % capacity] = data[i]
    }
    ringWritePos = (ringWritePos + samplesToWrite) % capacity
    os_unfair_lock_unlock(&ringLock)
  }

  fileprivate func readFromRing(_ data: UnsafeMutablePointer<Float>, frameCount: Int) {
    guard let ring = ringBuffer else { return }
    let samplesToRead = frameCount * Int(channelCount)
    let capacity = ringCapacityFrames * Int(channelCount)

    os_unfair_lock_lock(&ringLock)
    for i in 0 ..< samplesToRead {
      data[i] = ring[(ringReadPos + i) % capacity]
    }
    ringReadPos = (ringReadPos + samplesToRead) % capacity
    os_unfair_lock_unlock(&ringLock)
  }

  fileprivate func availableFrames() -> Int {
    let capacity = ringCapacityFrames * Int(channelCount)
    os_unfair_lock_lock(&ringLock)
    let available = (ringWritePos - ringReadPos + capacity) % capacity
    os_unfair_lock_unlock(&ringLock)
    return available / Int(channelCount)
  }

  // MARK: - Device Discovery

  private func findViPERDevice() -> AudioDeviceID? {
    let deviceIDs = getAllDeviceIDs()
    for deviceID in deviceIDs {
      if getDeviceUID(deviceID) == viperDeviceUID as String {
        return deviceID
      }
    }
    return nil
  }

  private func findRealOutputDevice() -> AudioDeviceID? {
    let currentDefault = getDefaultOutputDevice()
    let viperUID = viperDeviceUID as String
    if getDeviceUID(currentDefault) != viperUID
      && hasOutputStreams(currentDefault)
      && isDeviceAlive(currentDefault)
    {
      return currentDefault
    }

    let deviceIDs = getAllDeviceIDs()
    for deviceID in deviceIDs {
      if getDeviceUID(deviceID) == viperUID { continue }
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

  private func setDefaultOutputDevice(_ deviceID: AudioDeviceID) {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var id = deviceID
    AudioObjectSetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil,
      UInt32(MemoryLayout<AudioDeviceID>.size), &id
    )
  }

  private func setDefaultSystemOutputDevice(_ deviceID: AudioDeviceID) {
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var id = deviceID
    AudioObjectSetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil,
      UInt32(MemoryLayout<AudioDeviceID>.size), &id
    )
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

  var outputDeviceName: String {
    guard outputDeviceID != kAudioObjectUnknown else { return "None" }
    return getDeviceName(outputDeviceID)
  }

  var virtualDeviceInstalled: Bool {
    findViPERDevice() != nil
  }

  var lastNonSilentTimeMs: UInt64 {
    lastNonSilentTime
  }

  func getAvailableOutputDevices() -> [OutputDeviceInfo] {
    let viperUID = viperDeviceUID as String
    return getAllDeviceIDs().compactMap { deviceID in
      let uid = getDeviceUID(deviceID)
      guard uid != viperUID,
            hasOutputStreams(deviceID),
            isDeviceAlive(deviceID)
      else { return nil }
      return OutputDeviceInfo(id: deviceID, name: getDeviceName(deviceID), uid: uid)
    }
  }

  private func matchSampleRates() {
    let outputRate = getSampleRate(for: outputDeviceID)
    var propAddr = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyNominalSampleRate,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var rate = outputRate
    AudioObjectSetPropertyData(
      inputDeviceID, &propAddr, 0, nil,
      UInt32(MemoryLayout<Float64>.size), &rate
    )
  }
}

// MARK: - IOProc Callback (input from virtual device)

private let inputIOProcCallback: AudioDeviceIOProc = {
  _, _, _, _, outputData, _, clientData -> OSStatus in
  guard let clientData else { return noErr }
  let engine = Unmanaged<AudioEngine>.fromOpaque(clientData).takeUnretainedValue()

  engine.inputCallbackCount += 1

  let ch = Int(engine.channelCount)

  guard let shmPtr = engine.sharedRingPtr else {
    if engine.inputCallbackCount == 1 {
      logger.error("IOPROC: no shared memory")
    }
    return noErr
  }

  let ringCapacity = 16384 * 2
  let writePosPtr = shmPtr.assumingMemoryBound(to: UInt64.self)
  let readPosPtr = shmPtr.advanced(by: MemoryLayout<UInt64>.size).assumingMemoryBound(
    to: UInt64.self
  )
  let samplesBase = shmPtr.advanced(by: MemoryLayout<UInt64>.size * 2).assumingMemoryBound(
    to: Float.self
  )

  let outBufList = UnsafeMutableAudioBufferListPointer(outputData)
  let frameCount: Int
  if let firstBuf = outBufList.first {
    frameCount = Int(firstBuf.mDataByteSize) / (MemoryLayout<Float>.size * ch)
  } else {
    frameCount = 512
  }

  OSMemoryBarrier()
  let wp = writePosPtr.pointee
  let rp = readPosPtr.pointee
  let samplesToRead = frameCount * ch
  let available = Int((wp &- rp) % UInt64(ringCapacity))

  if available < samplesToRead {
    if engine.inputCallbackCount % 5000 == 1 {
      logger.debug("IOPROC: underrun avail=\(available) need=\(samplesToRead)")
    }
    return noErr
  }

  guard let tempBuf = engine.dspTempBuffer else { return noErr }
  let maxFrames = 4096
  let actualFrames = min(frameCount, maxFrames)
  let actualSamples = actualFrames * ch

  let readStart = Int(rp)
  for i in 0 ..< actualSamples {
    let idx = (readStart + i) % ringCapacity
    tempBuf[i] = samplesBase[idx]
  }
  let newRp = (rp &+ UInt64(actualSamples)) % UInt64(ringCapacity)
  readPosPtr.pointee = newRp
  OSMemoryBarrier()

  var maxSample: Float = 0.0
  for i in 0 ..< actualSamples {
    let s = abs(tempBuf[i])
    if s > maxSample { maxSample = s }
  }
  if maxSample > 1e-6 {
    engine.lastNonSilentTime = UInt64(Date().timeIntervalSince1970 * 1000)
  }
  if engine.inputCallbackCount % 5000 == 1 {
    logger.debug("IOPROC: frames=\(actualFrames) max=\(maxSample) avail=\(available)")
  }

  if engine.processingEnabled {
    engine.viperBridge.processAudio(tempBuf, frameCount: UInt32(actualFrames))
  }

  engine.writeToRing(tempBuf, frameCount: actualFrames)

  return noErr
}

// MARK: - Output AUHAL Render Callback

private let outputCallback: AURenderCallback = {
  inRefCon, _, _, _, inNumberFrames, ioData -> OSStatus in
  let engine = Unmanaged<AudioEngine>.fromOpaque(inRefCon).takeUnretainedValue()
  engine.outputCallbackCount += 1

  guard let ioData else { return noErr }
  let abl = UnsafeMutableAudioBufferListPointer(ioData)
  guard let firstBuffer = abl.first, let dataPtr = firstBuffer.mData else { return noErr }

  let floatPtr = dataPtr.assumingMemoryBound(to: Float.self)
  let frameCount = Int(inNumberFrames)
  let avail = engine.availableFrames()

  if avail >= frameCount {
    engine.readFromRing(floatPtr, frameCount: frameCount)
  } else {
    memset(dataPtr, 0, Int(firstBuffer.mDataByteSize))
  }

  if engine.outputCallbackCount % 5000 == 1 {
    var maxOut: Float = 0.0
    let sampleCount = frameCount * Int(engine.channelCount)
    for i in 0 ..< sampleCount {
      let s = abs(floatPtr[i])
      if s > maxOut { maxOut = s }
    }
    logger.debug("OUTPUT: frames=\(frameCount) avail=\(avail) max=\(maxOut)")
  }

  return noErr
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

private let engineVolumeChangedCallback: AudioObjectPropertyListenerProc = {
  _, _, _, clientData -> OSStatus in
  guard let clientData else { return noErr }
  let engine = Unmanaged<AudioEngine>.fromOpaque(clientData).takeUnretainedValue()

  DispatchQueue.main.async {
    engine.syncVolumeToOutput()
  }

  return noErr
}
