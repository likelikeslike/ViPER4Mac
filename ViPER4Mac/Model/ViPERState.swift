import Combine
import CoreAudio
import Foundation
import ServiceManagement

private let logger = AppLogger(category: "ViPERState")

private enum Param {
  static let SET_RESET_STATUS = 0x10002
  static let FX_TYPE_SWITCH = 0x10003

  static let HP_CONVOLVER_ENABLE = 0x10100
  static let HP_CONVOLVER_SET_KERNEL = 0x10101
  static let HP_CONVOLVER_PREPARE_BUFFER = 0x10102
  static let HP_CONVOLVER_SET_BUFFER = 0x10103
  static let HP_CONVOLVER_COMMIT_BUFFER = 0x10104
  static let HP_CONVOLVER_CROSS_CHANNEL = 0x10105
  static let HP_DDC_ENABLE = 0x10110
  static let HP_DDC_COEFFICIENTS = 0x10111
  static let HP_EQ_ENABLE = 0x10120
  static let HP_EQ_BAND_LEVEL = 0x10121
  static let HP_EQ_BAND_COUNT = 0x10122
  static let HP_REVERB_ENABLE = 0x10130
  static let HP_REVERB_ROOM_SIZE = 0x10131
  static let HP_REVERB_ROOM_WIDTH = 0x10132
  static let HP_REVERB_ROOM_DAMPENING = 0x10133
  static let HP_REVERB_ROOM_WET_SIGNAL = 0x10134
  static let HP_REVERB_ROOM_DRY_SIGNAL = 0x10135
  static let HP_AGC_ENABLE = 0x10140
  static let HP_AGC_RATIO = 0x10141
  static let HP_AGC_VOLUME = 0x10142
  static let HP_AGC_MAX_SCALER = 0x10143
  static let HP_DYNAMIC_SYSTEM_ENABLE = 0x10150
  static let HP_DYNAMIC_SYSTEM_X_COEFFICIENTS = 0x10151
  static let HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS = 0x10152
  static let HP_DYNAMIC_SYSTEM_SIDE_GAIN = 0x10153
  static let HP_DYNAMIC_SYSTEM_STRENGTH = 0x10154
  static let HP_BASS_ENABLE = 0x10160
  static let HP_BASS_MODE = 0x10161
  static let HP_BASS_FREQUENCY = 0x10162
  static let HP_BASS_GAIN = 0x10163
  static let HP_BASS_ANTI_POP = 0x10168
  static let HP_BASS_MONO_ENABLE = 0x10164
  static let HP_BASS_MONO_MODE = 0x10165
  static let HP_BASS_MONO_FREQUENCY = 0x10166
  static let HP_BASS_MONO_GAIN = 0x10167
  static let HP_BASS_MONO_ANTI_POP = 0x10169
  static let HP_CLARITY_ENABLE = 0x10170
  static let HP_CLARITY_MODE = 0x10171
  static let HP_CLARITY_GAIN = 0x10172
  static let HP_HEADPHONE_SURROUND_ENABLE = 0x10180
  static let HP_HEADPHONE_SURROUND_STRENGTH = 0x10181
  static let HP_SPECTRUM_EXTENSION_ENABLE = 0x10190
  static let HP_SPECTRUM_EXTENSION_BARK = 0x10191
  static let HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT = 0x10192
  static let HP_FIELD_SURROUND_ENABLE = 0x101A0
  static let HP_FIELD_SURROUND_WIDENING = 0x101A1
  static let HP_FIELD_SURROUND_MID_IMAGE = 0x101A2
  static let HP_FIELD_SURROUND_DEPTH = 0x101A3
  static let HP_DIFF_SURROUND_ENABLE = 0x101B0
  static let HP_DIFF_SURROUND_DELAY = 0x101B1
  static let HP_CURE_ENABLE = 0x101C0
  static let HP_CURE_STRENGTH = 0x101C1
  static let HP_TUBE_SIMULATOR_ENABLE = 0x101D0
  static let HP_ANALOGX_ENABLE = 0x101E0
  static let HP_ANALOGX_MODE = 0x101E1
  static let HP_OUTPUT_VOLUME = 0x101F0
  static let HP_CHANNEL_PAN = 0x101F1
  static let HP_LIMITER = 0x101F2
  static let HP_FET_COMPRESSOR_ENABLE = 0x10200
  static let HP_FET_COMPRESSOR_THRESHOLD = 0x10201
  static let HP_FET_COMPRESSOR_RATIO = 0x10202
  static let HP_FET_COMPRESSOR_KNEE = 0x10203
  static let HP_FET_COMPRESSOR_AUTO_KNEE = 0x10204
  static let HP_FET_COMPRESSOR_GAIN = 0x10205
  static let HP_FET_COMPRESSOR_AUTO_GAIN = 0x10206
  static let HP_FET_COMPRESSOR_ATTACK = 0x10207
  static let HP_FET_COMPRESSOR_AUTO_ATTACK = 0x10208
  static let HP_FET_COMPRESSOR_RELEASE = 0x10209
  static let HP_FET_COMPRESSOR_AUTO_RELEASE = 0x1020A
  static let HP_FET_COMPRESSOR_KNEE_MULTI = 0x1020B
  static let HP_FET_COMPRESSOR_MAX_ATTACK = 0x1020C
  static let HP_FET_COMPRESSOR_MAX_RELEASE = 0x1020D
  static let HP_FET_COMPRESSOR_CREST = 0x1020E
  static let HP_FET_COMPRESSOR_ADAPT = 0x1020F
  static let HP_FET_COMPRESSOR_NO_CLIP = 0x10210

  static let SPK_CONVOLVER_ENABLE = 0x10300
  static let SPK_CONVOLVER_SET_KERNEL = 0x10301
  static let SPK_CONVOLVER_PREPARE_BUFFER = 0x10302
  static let SPK_CONVOLVER_SET_BUFFER = 0x10303
  static let SPK_CONVOLVER_COMMIT_BUFFER = 0x10304
  static let SPK_CONVOLVER_CROSS_CHANNEL = 0x10305
  static let SPK_DDC_ENABLE = 0x10310
  static let SPK_DDC_COEFFICIENTS = 0x10311
  static let SPK_EQ_ENABLE = 0x10320
  static let SPK_EQ_BAND_LEVEL = 0x10321
  static let SPK_EQ_BAND_COUNT = 0x10322
  static let SPK_REVERB_ENABLE = 0x10330
  static let SPK_REVERB_ROOM_SIZE = 0x10331
  static let SPK_REVERB_ROOM_WIDTH = 0x10332
  static let SPK_REVERB_ROOM_DAMPENING = 0x10333
  static let SPK_REVERB_ROOM_WET_SIGNAL = 0x10334
  static let SPK_REVERB_ROOM_DRY_SIGNAL = 0x10335
  static let SPK_AGC_ENABLE = 0x10340
  static let SPK_AGC_RATIO = 0x10341
  static let SPK_AGC_VOLUME = 0x10342
  static let SPK_AGC_MAX_SCALER = 0x10343
  static let SPK_DYNAMIC_SYSTEM_ENABLE = 0x10350
  static let SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS = 0x10351
  static let SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS = 0x10352
  static let SPK_DYNAMIC_SYSTEM_SIDE_GAIN = 0x10353
  static let SPK_DYNAMIC_SYSTEM_STRENGTH = 0x10354
  static let SPK_BASS_ENABLE = 0x10360
  static let SPK_BASS_MODE = 0x10361
  static let SPK_BASS_FREQUENCY = 0x10362
  static let SPK_BASS_GAIN = 0x10363
  static let SPK_BASS_ANTI_POP = 0x10368
  static let SPK_BASS_MONO_ENABLE = 0x10364
  static let SPK_BASS_MONO_MODE = 0x10365
  static let SPK_BASS_MONO_FREQUENCY = 0x10366
  static let SPK_BASS_MONO_GAIN = 0x10367
  static let SPK_BASS_MONO_ANTI_POP = 0x10369
  static let SPK_CLARITY_ENABLE = 0x10370
  static let SPK_CLARITY_MODE = 0x10371
  static let SPK_CLARITY_GAIN = 0x10372
  static let SPK_HEADPHONE_SURROUND_ENABLE = 0x10380
  static let SPK_HEADPHONE_SURROUND_STRENGTH = 0x10381
  static let SPK_SPECTRUM_EXTENSION_ENABLE = 0x10390
  static let SPK_SPECTRUM_EXTENSION_BARK = 0x10391
  static let SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT = 0x10392
  static let SPK_FIELD_SURROUND_ENABLE = 0x103A0
  static let SPK_FIELD_SURROUND_WIDENING = 0x103A1
  static let SPK_FIELD_SURROUND_MID_IMAGE = 0x103A2
  static let SPK_FIELD_SURROUND_DEPTH = 0x103A3
  static let SPK_DIFF_SURROUND_ENABLE = 0x103B0
  static let SPK_DIFF_SURROUND_DELAY = 0x103B1
  static let SPK_CURE_ENABLE = 0x103C0
  static let SPK_CURE_STRENGTH = 0x103C1
  static let SPK_TUBE_SIMULATOR_ENABLE = 0x103D0
  static let SPK_ANALOGX_ENABLE = 0x103E0
  static let SPK_ANALOGX_MODE = 0x103E1
  static let SPK_OUTPUT_VOLUME = 0x103F0
  static let SPK_CHANNEL_PAN = 0x103F1
  static let SPK_LIMITER = 0x103F2
  static let SPK_FET_COMPRESSOR_ENABLE = 0x10400
  static let SPK_FET_COMPRESSOR_THRESHOLD = 0x10401
  static let SPK_FET_COMPRESSOR_RATIO = 0x10402
  static let SPK_FET_COMPRESSOR_KNEE = 0x10403
  static let SPK_FET_COMPRESSOR_AUTO_KNEE = 0x10404
  static let SPK_FET_COMPRESSOR_GAIN = 0x10405
  static let SPK_FET_COMPRESSOR_AUTO_GAIN = 0x10406
  static let SPK_FET_COMPRESSOR_ATTACK = 0x10407
  static let SPK_FET_COMPRESSOR_AUTO_ATTACK = 0x10408
  static let SPK_FET_COMPRESSOR_RELEASE = 0x10409
  static let SPK_FET_COMPRESSOR_AUTO_RELEASE = 0x1040A
  static let SPK_FET_COMPRESSOR_KNEE_MULTI = 0x1040B
  static let SPK_FET_COMPRESSOR_MAX_ATTACK = 0x1040C
  static let SPK_FET_COMPRESSOR_MAX_RELEASE = 0x1040D
  static let SPK_FET_COMPRESSOR_CREST = 0x1040E
  static let SPK_FET_COMPRESSOR_ADAPT = 0x1040F
  static let SPK_FET_COMPRESSOR_NO_CLIP = 0x10410
  static let SPK_SPEAKER_CORRECTION_ENABLE = 0x10420
}

struct EqPreset: Codable {
  let name: String
  let bandCount: Int
  let bands: [Float]
}

struct DynSysPreset: Codable {
  let name: String
  let xLow: Int
  let xHigh: Int
  let yLow: Int
  let yHigh: Int
  let sideGainLow: Int
  let sideGainHigh: Int
}

final class ViPERState: ObservableObject {
  static let shared = ViPERState()

  var bridge: ViPERBridge {
    AudioEngine.shared.viperBridge
  }

  static let outputVolumeValues = [
    1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
    110, 120, 130, 140, 150, 160, 170, 180, 190, 200,
  ]
  static let limiterValues = [30, 50, 70, 80, 90, 100]
  static let agcRatioValues = [50, 100, 300]
  static let agcMaxGainValues = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 3000]
  static let vseBarkValues = [2200, 2800, 3400, 4000, 4600, 5200, 5800, 6400, 7000, 7600, 8200]
  static let diffSurroundDelayValues = (1 ... 20).map { $0 * 100 }
  static let fieldSurroundWideningValues = [0, 100, 200, 300, 400, 500, 600, 700, 800]
  static let bassGainDbLabels = [
    "3.5", "6.0", "8.0", "9.5", "10.9", "12.0",
    "13.1", "14.0", "14.8", "15.6", "16.1", "17.0",
    "17.5", "18.1", "18.6", "19.1", "19.5", "20.0", "20.4", "20.8",
  ]
  static let subwooferGainDbLabels = [
    "1.9", "8.0", "11.5", "14.0", "15.9", "17.5",
    "18.8", "20.0", "21.0", "21.9", "22.8", "23.5",
    "24.2", "24.9", "25.5", "26.0", "26.5", "27.0", "27.5", "28.0",
  ]
  static let clarityGainDbLabels = [
    "0.0", "3.5", "6.0", "8.0", "10.0", "11.0",
    "12.0", "13.0", "14.0", "14.8",
  ]
  static let dynamicSystemDevices: [(name: String, coeffs: String)] = [
    ("Extreme Headphone (v2)", "140;6200;40;60;10;80"),
    ("High-End Headphone (v2)", "180;5800;55;80;10;70"),
    ("Common Headphone (v2)", "300;5600;60;105;10;50"),
    ("Low-End Headphone (v2)", "600;5400;60;105;10;20"),
    ("Common Earphone (v2)", "100;5600;40;80;50;50"),
    ("Extreme Headphone (v1)", "1200;6200;40;80;0;20"),
    ("High-End Headphone (v1)", "1000;6200;40;80;0;10"),
    ("Common Headphone (v1)", "800;6200;40;80;10;0"),
    ("Common Earphone (v1)", "400;6200;40;80;10;0"),
    ("Apple Earphone", "1200;6200;50;90;15;10"),
    ("Monster Earphone", "1000;6200;50;90;30;10"),
    ("Motorola Earphone", "1100;6200;60;100;20;0"),
    ("Philips Earphone", "1200;6200;50;100;10;50"),
    ("SHP2000", "1200;6200;60;100;0;30"),
    ("SHP9000", "1200;6200;40;80;0;30"),
    ("Unknown Type I", "1000;6200;60;100;0;0"),
    ("Unknown Type II", "1000;6200;60;120;0;0"),
    ("Unknown Type III", "1000;6200;80;140;0;0"),
    ("Unknown Type IV", "800;6200;80;140;0;0"),
    ("Unknown Type V", "0;0;0;0;0;0"),
    ("pittvandewitt flavor #1", "180;5400;40;60;50;0"),
    ("pittvandewitt flavor #2", "1200;6000;40;60;0;80"),
    ("pittvandewitt flavor #3", "140;5400;40;60;0;0"),
  ]

  struct ModeState: Codable {
    var mode: Int = 0
    var outputVolume: Int = 11
    var channelPan: Int = 0
    var limiter: Int = 5
    var convolutionEnabled = false
    var convolutionCrossChannel: Int = 0
    var convolutionKernelPath: String = ""
    var vheEnabled = false
    var vheQuality: Int = 0
    var ddcEnabled = false
    var ddcFilePath: String = ""
    var spectrumExtensionEnabled = false
    var spectrumExtensionBark: Int = 9
    var spectrumExtensionBarkReconstruct: Int = 0
    var equalizerEnabled = false
    var equalizerBandCount: Int = 10
    var equalizerBands: [Float] = Array(repeating: 0.0, count: 10)
    var equalizerBandsMap: [Int: [Float]] = [10: Array(repeating: 0.0, count: 10)]
    var fieldSurroundEnabled = false
    var fieldSurroundWidening: Int = 0
    var fieldSurroundMidImage: Int = 5
    var fieldSurroundDepth: Int = 0
    var diffSurroundEnabled = false
    var diffSurroundDelay: Int = 4
    var reverberationEnabled = false
    var reverberationRoomSize: Int = 0
    var reverberationRoomWidth: Int = 0
    var reverberationRoomDampening: Int = 0
    var reverberationWetSignal: Int = 0
    var reverberationDrySignal: Int = 50
    var dynamicSystemEnabled = false
    var dynamicSystemDevice: Int = 0
    var dynamicSystemStrength: Int = 50
    var dsXLow: Int = 100
    var dsXHigh: Int = 5600
    var dsYLow: Int = 40
    var dsYHigh: Int = 80
    var dsSideGainLow: Int = 50
    var dsSideGainHigh: Int = 50
    var tubeSimulatorEnabled = false
    var analogXEnabled = false
    var analogXMode: Int = 0
    var cureEnabled = false
    var cureCrossfeedStrength: Int = 0
    var viperBassEnabled = false
    var viperBassMode: Int = 0
    var viperBassFrequency: Int = 55
    var viperBassGain: Int = 0
    var viperBassAntiPop: Bool = true
    var viperBassMonoEnabled = false
    var viperBassMonoMode: Int = 0
    var viperBassMonoFrequency: Int = 55
    var viperBassMonoGain: Int = 0
    var viperBassMonoAntiPop: Bool = true
    var viperClarityEnabled = false
    var viperClarityMode: Int = 0
    var viperClarityGain: Int = 1
    var speakerCorrectionEnabled = false
    var playbackGainEnabled = false
    var playbackGainStrength: Int = 0
    var playbackGainMaxGain: Int = 3
    var playbackGainOutputThreshold: Int = 3
    var fetCompressorEnabled = false
    var fetCompressorThreshold: Int = 100
    var fetCompressorRatio: Int = 100
    var fetCompressorAutoKnee = true
    var fetCompressorKnee: Int = 0
    var fetCompressorKneeMulti: Int = 0
    var fetCompressorAutoGain = true
    var fetCompressorGain: Int = 0
    var fetCompressorAutoAttack = true
    var fetCompressorAttack: Int = 20
    var fetCompressorMaxAttack: Int = 80
    var fetCompressorAutoRelease = true
    var fetCompressorRelease: Int = 50
    var fetCompressorMaxRelease: Int = 100
    var fetCompressorCrest: Int = 100
    var fetCompressorAdapt: Int = 50
    var fetCompressorNoClip = true
  }

  private var headphoneState = ModeState()
  private var speakerState = ModeState()
  private var suppressDispatch = false

  @Published var isEnabled = true
  @Published var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled {
    didSet {
      do {
        if launchAtLogin {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
      } catch {
        launchAtLogin = SMAppService.mainApp.status == .enabled
      }
    }
  }

  @Published var fxType: FXType = .headphone

  @Published var outputVolume: Int = 11
  @Published var channelPan: Int = 0
  @Published var limiter: Int = 5

  @Published var convolutionEnabled = false
  @Published var convolutionCrossChannel: Int = 0
  @Published var convolutionKernelPath: String = ""

  @Published var vheEnabled = false
  @Published var vheQuality: Int = 0

  @Published var ddcEnabled = false
  @Published var ddcFilePath: String = ""

  @Published var spectrumExtensionEnabled = false
  @Published var spectrumExtensionBark: Int = 9
  @Published var spectrumExtensionBarkReconstruct: Int = 0

  @Published var equalizerEnabled = false
  @Published var equalizerBandCount: Int = 10
  @Published var equalizerBands: [Float] = Array(repeating: 0.0, count: 10)
  var equalizerBandsMap: [Int: [Float]] = [10: Array(repeating: 0.0, count: 10)]

  @Published var fieldSurroundEnabled = false
  @Published var fieldSurroundWidening: Int = 0
  @Published var fieldSurroundMidImage: Int = 5
  @Published var fieldSurroundDepth: Int = 0

  @Published var diffSurroundEnabled = false
  @Published var diffSurroundDelay: Int = 4

  @Published var reverberationEnabled = false
  @Published var reverberationRoomSize: Int = 0
  @Published var reverberationRoomWidth: Int = 0
  @Published var reverberationRoomDampening: Int = 0
  @Published var reverberationWetSignal: Int = 0
  @Published var reverberationDrySignal: Int = 50

  @Published var dynamicSystemEnabled = false
  @Published var dynamicSystemDevice: Int = 0
  @Published var dynamicSystemStrength: Int = 50
  @Published var dsXLow: Int = 100
  @Published var dsXHigh: Int = 5600
  @Published var dsYLow: Int = 40
  @Published var dsYHigh: Int = 80
  @Published var dsSideGainLow: Int = 50
  @Published var dsSideGainHigh: Int = 50

  @Published var fetCompressorEnabled = false
  @Published var fetCompressorThreshold: Int = 100
  @Published var fetCompressorRatio: Int = 100
  @Published var fetCompressorAutoKnee = true
  @Published var fetCompressorKnee: Int = 0
  @Published var fetCompressorKneeMulti: Int = 0
  @Published var fetCompressorAutoGain = true
  @Published var fetCompressorGain: Int = 0
  @Published var fetCompressorAutoAttack = true
  @Published var fetCompressorAttack: Int = 20
  @Published var fetCompressorMaxAttack: Int = 80
  @Published var fetCompressorAutoRelease = true
  @Published var fetCompressorRelease: Int = 50
  @Published var fetCompressorMaxRelease: Int = 100
  @Published var fetCompressorCrest: Int = 100
  @Published var fetCompressorAdapt: Int = 50
  @Published var fetCompressorNoClip = true

  @Published var viperBassEnabled = false
  @Published var viperBassMode: Int = 0
  @Published var viperBassFrequency: Int = 55
  @Published var viperBassGain: Int = 0
  @Published var viperBassAntiPop: Bool = true

  @Published var viperBassMonoEnabled = false
  @Published var viperBassMonoMode: Int = 0
  @Published var viperBassMonoFrequency: Int = 55
  @Published var viperBassMonoGain: Int = 0
  @Published var viperBassMonoAntiPop: Bool = true

  @Published var viperClarityEnabled = false
  @Published var viperClarityMode: Int = 0
  @Published var viperClarityGain: Int = 1

  @Published var cureEnabled = false
  @Published var cureCrossfeedStrength: Int = 0

  @Published var tubeSimulatorEnabled = false

  @Published var analogXEnabled = false
  @Published var analogXMode: Int = 0

  @Published var speakerCorrectionEnabled = false

  @Published var ddcFiles: [String] = []
  @Published var kernelFiles: [String] = []
  @Published var presetFiles: [String] = []
  @Published var eqPresetFiles: [String] = []
  @Published var dsPresetFiles: [String] = []

  @Published var driverInstalled = false
  @Published var isProcessing = false
  @Published var currentSampleRate: UInt32 = 0
  @Published var outputDeviceName: String = "None"
  @Published var driverVersion: String = "N/A"
  private var statusTimer: Timer?

  @Published var availableOutputDevices: [OutputDeviceInfo] = []
  @Published var selectedOutputDeviceID: AudioDeviceID = 0 {
    didSet {
      guard selectedOutputDeviceID != oldValue,
            selectedOutputDeviceID != 0,
            selectedOutputDeviceID != AudioEngine.shared.outputDeviceID
      else { return }
      AudioEngine.shared.switchOutputDevice(to: selectedOutputDeviceID)
    }
  }

  @Published var playbackGainEnabled = false
  @Published var playbackGainStrength: Int = 0
  @Published var playbackGainMaxGain: Int = 3
  @Published var playbackGainOutputThreshold: Int = 3

  enum FXType: Int {
    case headphone = 0
    case speaker = 1
  }

  private(set) var activeDeviceType: FXType = .headphone

  private var isSpk: Bool {
    fxType == .speaker
  }

  private var isActiveSpk: Bool {
    activeDeviceType == .speaker
  }

  private var cancellables = Set<AnyCancellable>()

  private init() {
    let detected = AudioOutputDetector.shared.currentOutputType
    activeDeviceType = detected == .headphone ? .headphone : .speaker
    fxType = activeDeviceType
    refreshFileLists()
    restoreSettings()
    setupBindings()
    reloadActiveFiles()
    dispatchFullModeState()
    startStatusTimer()
    logger.info("Init: device=\(activeDeviceType == .headphone ? "headphone" : "speaker")")
  }

  private func startStatusTimer() {
    refreshDriverStatus()
    statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.refreshDriverStatus()
    }
  }

  func refreshDriverStatus() {
    let engine = AudioEngine.shared
    driverInstalled = engine.virtualDeviceInstalled
    outputDeviceName = engine.outputDeviceName
    currentSampleRate = bridge.getSamplingRate()
    driverVersion = Self.readDriverVersion()
    availableOutputDevices = engine.getAvailableOutputDevices()
    selectedOutputDeviceID = engine.outputDeviceID
    let lastAudio = engine.lastNonSilentTimeMs
    if lastAudio == 0 {
      isProcessing = false
    } else {
      let now = UInt64(Date().timeIntervalSince1970 * 1000)
      isProcessing = now >= lastAudio ? (now - lastAudio < 2000) : false
    }
  }

  private static func readDriverVersion() -> String {
    let driverPath = "/Library/Audio/Plug-Ins/HAL/ViPER4Mac.driver"
    guard let bundle = Bundle(path: driverPath),
          let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    else { return "N/A" }
    return version
  }

  private func reloadActiveFiles() {
    if !ddcFilePath.isEmpty {
      let url = ProfileFileManager.shared.fileURL(name: ddcFilePath, type: .ddc)
      if FileManager.default.fileExists(atPath: url.path) {
        loadDDCFile(at: url)
      } else {
        logger.info("DDC file missing, clearing: \(ddcFilePath)")
        ddcFilePath = ""
        ddcEnabled = false
      }
    }
    if !convolutionKernelPath.isEmpty {
      let url = ProfileFileManager.shared.fileURL(name: convolutionKernelPath, type: .kernel)
      if FileManager.default.fileExists(atPath: url.path) {
        loadConvolverKernel(at: url)
      } else {
        logger.info("Convolver kernel missing, clearing: \(convolutionKernelPath)")
        convolutionKernelPath = ""
        convolutionEnabled = false
      }
    }
  }

  private func send(_ param: Int, _ val1: Int, _ val2: Int = 0, _ val3: Int = 0, _ val4: Int = 0) {
    logger.debug("DSP param=\(param) v1=\(val1) v2=\(val2) v3=\(val3) v4=\(val4)")
    bridge.setParameter(
      Int32(param), value1: Int32(val1), value2: Int32(val2),
      value3: Int32(val3), value4: Int32(val4)
    )
  }

  private func saveToMode(isSpk spk: Bool) {
    var s = ModeState()
    s.outputVolume = outputVolume
    s.channelPan = channelPan
    s.limiter = limiter
    s.convolutionEnabled = convolutionEnabled
    s.convolutionCrossChannel = convolutionCrossChannel
    s.convolutionKernelPath = convolutionKernelPath
    s.vheEnabled = vheEnabled
    s.vheQuality = vheQuality
    s.ddcEnabled = ddcEnabled
    s.ddcFilePath = ddcFilePath
    s.spectrumExtensionEnabled = spectrumExtensionEnabled
    s.spectrumExtensionBark = spectrumExtensionBark
    s.spectrumExtensionBarkReconstruct = spectrumExtensionBarkReconstruct
    s.equalizerEnabled = equalizerEnabled
    s.equalizerBandCount = equalizerBandCount
    s.equalizerBands = equalizerBands
    s.equalizerBandsMap = equalizerBandsMap
    s.fieldSurroundEnabled = fieldSurroundEnabled
    s.fieldSurroundWidening = fieldSurroundWidening
    s.fieldSurroundMidImage = fieldSurroundMidImage
    s.fieldSurroundDepth = fieldSurroundDepth
    s.diffSurroundEnabled = diffSurroundEnabled
    s.diffSurroundDelay = diffSurroundDelay
    s.reverberationEnabled = reverberationEnabled
    s.reverberationRoomSize = reverberationRoomSize
    s.reverberationRoomWidth = reverberationRoomWidth
    s.reverberationRoomDampening = reverberationRoomDampening
    s.reverberationWetSignal = reverberationWetSignal
    s.reverberationDrySignal = reverberationDrySignal
    s.dynamicSystemEnabled = dynamicSystemEnabled
    s.dynamicSystemDevice = dynamicSystemDevice
    s.dynamicSystemStrength = dynamicSystemStrength
    s.dsXLow = dsXLow
    s.dsXHigh = dsXHigh
    s.dsYLow = dsYLow
    s.dsYHigh = dsYHigh
    s.dsSideGainLow = dsSideGainLow
    s.dsSideGainHigh = dsSideGainHigh
    s.tubeSimulatorEnabled = tubeSimulatorEnabled
    s.analogXEnabled = analogXEnabled
    s.analogXMode = analogXMode
    s.cureEnabled = cureEnabled
    s.cureCrossfeedStrength = cureCrossfeedStrength
    s.viperBassEnabled = viperBassEnabled
    s.viperBassMode = viperBassMode
    s.viperBassFrequency = viperBassFrequency
    s.viperBassGain = viperBassGain
    s.viperBassAntiPop = viperBassAntiPop
    s.viperBassMonoEnabled = viperBassMonoEnabled
    s.viperBassMonoMode = viperBassMonoMode
    s.viperBassMonoFrequency = viperBassMonoFrequency
    s.viperBassMonoGain = viperBassMonoGain
    s.viperBassMonoAntiPop = viperBassMonoAntiPop
    s.viperClarityEnabled = viperClarityEnabled
    s.viperClarityMode = viperClarityMode
    s.viperClarityGain = viperClarityGain
    s.speakerCorrectionEnabled = speakerCorrectionEnabled
    s.playbackGainEnabled = playbackGainEnabled
    s.playbackGainStrength = playbackGainStrength
    s.playbackGainMaxGain = playbackGainMaxGain
    s.playbackGainOutputThreshold = playbackGainOutputThreshold
    s.fetCompressorEnabled = fetCompressorEnabled
    s.fetCompressorThreshold = fetCompressorThreshold
    s.fetCompressorRatio = fetCompressorRatio
    s.fetCompressorAutoKnee = fetCompressorAutoKnee
    s.fetCompressorKnee = fetCompressorKnee
    s.fetCompressorKneeMulti = fetCompressorKneeMulti
    s.fetCompressorAutoGain = fetCompressorAutoGain
    s.fetCompressorGain = fetCompressorGain
    s.fetCompressorAutoAttack = fetCompressorAutoAttack
    s.fetCompressorAttack = fetCompressorAttack
    s.fetCompressorMaxAttack = fetCompressorMaxAttack
    s.fetCompressorAutoRelease = fetCompressorAutoRelease
    s.fetCompressorRelease = fetCompressorRelease
    s.fetCompressorMaxRelease = fetCompressorMaxRelease
    s.fetCompressorCrest = fetCompressorCrest
    s.fetCompressorAdapt = fetCompressorAdapt
    s.fetCompressorNoClip = fetCompressorNoClip
    if spk { speakerState = s } else { headphoneState = s }
    logger.debug("Saved state to \(spk ? "speaker" : "headphone")")
  }

  private func loadModeToActive(_ s: ModeState) {
    logger.debug("Loading state from mode=\(s.mode)")
    suppressDispatch = true
    outputVolume = s.outputVolume
    channelPan = s.channelPan
    limiter = s.limiter
    convolutionEnabled = s.convolutionEnabled
    convolutionCrossChannel = s.convolutionCrossChannel
    convolutionKernelPath = s.convolutionKernelPath
    vheEnabled = s.vheEnabled
    vheQuality = s.vheQuality
    ddcEnabled = s.ddcEnabled
    ddcFilePath = s.ddcFilePath
    spectrumExtensionEnabled = s.spectrumExtensionEnabled
    spectrumExtensionBark = s.spectrumExtensionBark
    spectrumExtensionBarkReconstruct = s.spectrumExtensionBarkReconstruct
    equalizerEnabled = s.equalizerEnabled
    equalizerBandCount = s.equalizerBandCount
    equalizerBands = s.equalizerBands
    equalizerBandsMap = s.equalizerBandsMap
    fieldSurroundEnabled = s.fieldSurroundEnabled
    fieldSurroundWidening = s.fieldSurroundWidening
    fieldSurroundMidImage = s.fieldSurroundMidImage
    fieldSurroundDepth = s.fieldSurroundDepth
    diffSurroundEnabled = s.diffSurroundEnabled
    diffSurroundDelay = s.diffSurroundDelay
    reverberationEnabled = s.reverberationEnabled
    reverberationRoomSize = s.reverberationRoomSize
    reverberationRoomWidth = s.reverberationRoomWidth
    reverberationRoomDampening = s.reverberationRoomDampening
    reverberationWetSignal = s.reverberationWetSignal
    reverberationDrySignal = s.reverberationDrySignal
    dynamicSystemEnabled = s.dynamicSystemEnabled
    dynamicSystemDevice = s.dynamicSystemDevice
    dynamicSystemStrength = s.dynamicSystemStrength
    dsXLow = s.dsXLow
    dsXHigh = s.dsXHigh
    dsYLow = s.dsYLow
    dsYHigh = s.dsYHigh
    dsSideGainLow = s.dsSideGainLow
    dsSideGainHigh = s.dsSideGainHigh
    tubeSimulatorEnabled = s.tubeSimulatorEnabled
    analogXEnabled = s.analogXEnabled
    analogXMode = s.analogXMode
    cureEnabled = s.cureEnabled
    cureCrossfeedStrength = s.cureCrossfeedStrength
    viperBassEnabled = s.viperBassEnabled
    viperBassMode = s.viperBassMode
    viperBassFrequency = s.viperBassFrequency
    viperBassGain = s.viperBassGain
    viperBassAntiPop = s.viperBassAntiPop
    viperBassMonoEnabled = s.viperBassMonoEnabled
    viperBassMonoMode = s.viperBassMonoMode
    viperBassMonoFrequency = s.viperBassMonoFrequency
    viperBassMonoGain = s.viperBassMonoGain
    viperBassMonoAntiPop = s.viperBassMonoAntiPop
    viperClarityEnabled = s.viperClarityEnabled
    viperClarityMode = s.viperClarityMode
    viperClarityGain = s.viperClarityGain
    speakerCorrectionEnabled = s.speakerCorrectionEnabled
    playbackGainEnabled = s.playbackGainEnabled
    playbackGainStrength = s.playbackGainStrength
    playbackGainMaxGain = s.playbackGainMaxGain
    playbackGainOutputThreshold = s.playbackGainOutputThreshold
    fetCompressorEnabled = s.fetCompressorEnabled
    fetCompressorThreshold = s.fetCompressorThreshold
    fetCompressorRatio = s.fetCompressorRatio
    fetCompressorAutoKnee = s.fetCompressorAutoKnee
    fetCompressorKnee = s.fetCompressorKnee
    fetCompressorKneeMulti = s.fetCompressorKneeMulti
    fetCompressorAutoGain = s.fetCompressorAutoGain
    fetCompressorGain = s.fetCompressorGain
    fetCompressorAutoAttack = s.fetCompressorAutoAttack
    fetCompressorAttack = s.fetCompressorAttack
    fetCompressorMaxAttack = s.fetCompressorMaxAttack
    fetCompressorAutoRelease = s.fetCompressorAutoRelease
    fetCompressorRelease = s.fetCompressorRelease
    fetCompressorMaxRelease = s.fetCompressorMaxRelease
    fetCompressorCrest = s.fetCompressorCrest
    fetCompressorAdapt = s.fetCompressorAdapt
    fetCompressorNoClip = s.fetCompressorNoClip
    suppressDispatch = false
  }

  private func dispatchFullModeState() {
    logger.info("Dispatching full state: mode=\(isActiveSpk ? "speaker" : "headphone")")
    send(Param.SET_RESET_STATUS, 1)
    send(Param.FX_TYPE_SWITCH, activeDeviceType.rawValue)
    let spk = isActiveSpk
    let volParam = spk ? Param.SPK_OUTPUT_VOLUME : Param.HP_OUTPUT_VOLUME
    let limParam = spk ? Param.SPK_LIMITER : Param.HP_LIMITER
    let convEnParam = spk ? Param.SPK_CONVOLVER_ENABLE : Param.HP_CONVOLVER_ENABLE
    let convCcParam = spk ? Param.SPK_CONVOLVER_CROSS_CHANNEL : Param.HP_CONVOLVER_CROSS_CHANNEL
    let eqEnParam = spk ? Param.SPK_EQ_ENABLE : Param.HP_EQ_ENABLE
    let eqBandParam = spk ? Param.SPK_EQ_BAND_LEVEL : Param.HP_EQ_BAND_LEVEL
    let eqCountParam = spk ? Param.SPK_EQ_BAND_COUNT : Param.HP_EQ_BAND_COUNT
    let revEnParam = spk ? Param.SPK_REVERB_ENABLE : Param.HP_REVERB_ENABLE
    let revSizeParam = spk ? Param.SPK_REVERB_ROOM_SIZE : Param.HP_REVERB_ROOM_SIZE
    let revWidthParam = spk ? Param.SPK_REVERB_ROOM_WIDTH : Param.HP_REVERB_ROOM_WIDTH
    let revDampParam = spk ? Param.SPK_REVERB_ROOM_DAMPENING : Param.HP_REVERB_ROOM_DAMPENING
    let revWetParam = spk ? Param.SPK_REVERB_ROOM_WET_SIGNAL : Param.HP_REVERB_ROOM_WET_SIGNAL
    let revDryParam = spk ? Param.SPK_REVERB_ROOM_DRY_SIGNAL : Param.HP_REVERB_ROOM_DRY_SIGNAL
    let agcEnParam = spk ? Param.SPK_AGC_ENABLE : Param.HP_AGC_ENABLE
    let agcRatioParam = spk ? Param.SPK_AGC_RATIO : Param.HP_AGC_RATIO
    let agcVolParam = spk ? Param.SPK_AGC_VOLUME : Param.HP_AGC_VOLUME
    let agcMaxParam = spk ? Param.SPK_AGC_MAX_SCALER : Param.HP_AGC_MAX_SCALER
    let fetBase = spk ? Param.SPK_FET_COMPRESSOR_ENABLE : Param.HP_FET_COMPRESSOR_ENABLE

    send(volParam, Self.outputVolumeValues[safe: outputVolume] ?? 100)
    send(spk ? Param.SPK_CHANNEL_PAN : Param.HP_CHANNEL_PAN, channelPan)
    send(limParam, Self.limiterValues[safe: limiter] ?? 100)
    send(convEnParam, convolutionEnabled && !convolutionKernelPath.isEmpty ? 1 : 0)
    send(convCcParam, convolutionCrossChannel)
    send(eqEnParam, equalizerEnabled ? 1 : 0)
    send(eqCountParam, equalizerBandCount)
    for i in 0 ..< equalizerBands.count {
      send(eqBandParam, i, Int(equalizerBands[i] * 100))
    }
    send(revEnParam, reverberationEnabled ? 1 : 0)
    send(revSizeParam, reverberationRoomSize * 10)
    send(revWidthParam, reverberationRoomWidth * 10)
    send(revDampParam, reverberationRoomDampening)
    send(revWetParam, reverberationWetSignal)
    send(revDryParam, reverberationDrySignal)
    send(agcEnParam, playbackGainEnabled ? 1 : 0)
    send(agcRatioParam, Self.agcRatioValues[safe: playbackGainStrength] ?? 50)
    send(agcVolParam, Self.limiterValues[safe: playbackGainOutputThreshold] ?? 100)
    send(agcMaxParam, Self.agcMaxGainValues[safe: playbackGainMaxGain] ?? 100)
    send(fetBase, fetCompressorEnabled ? 100 : 0)
    send(fetBase + 1, fetCompressorThreshold)
    send(fetBase + 2, fetCompressorRatio)
    send(fetBase + 3, fetCompressorKnee)
    send(fetBase + 4, fetCompressorAutoKnee ? 100 : 0)
    send(fetBase + 5, fetCompressorGain)
    send(fetBase + 6, fetCompressorAutoGain ? 100 : 0)
    send(fetBase + 7, fetCompressorAttack)
    send(fetBase + 8, fetCompressorAutoAttack ? 100 : 0)
    send(fetBase + 9, fetCompressorRelease)
    send(fetBase + 10, fetCompressorAutoRelease ? 100 : 0)
    send(fetBase + 11, fetCompressorKneeMulti)
    send(fetBase + 12, fetCompressorMaxAttack)
    send(fetBase + 13, fetCompressorMaxRelease)
    send(fetBase + 14, fetCompressorCrest)
    send(fetBase + 15, fetCompressorAdapt)
    send(fetBase + 16, fetCompressorNoClip ? 100 : 0)

    send(spk ? Param.SPK_BASS_ENABLE : Param.HP_BASS_ENABLE, viperBassEnabled ? 1 : 0)
    send(spk ? Param.SPK_BASS_MODE : Param.HP_BASS_MODE, viperBassMode)
    send(spk ? Param.SPK_BASS_FREQUENCY : Param.HP_BASS_FREQUENCY, viperBassFrequency + 15)
    send(spk ? Param.SPK_BASS_GAIN : Param.HP_BASS_GAIN, viperBassGain * 50 + 50)
    send(spk ? Param.SPK_BASS_ANTI_POP : Param.HP_BASS_ANTI_POP, viperBassAntiPop ? 1 : 0)
    send(spk ? Param.SPK_BASS_MONO_ENABLE : Param.HP_BASS_MONO_ENABLE, viperBassMonoEnabled ? 1 : 0)
    send(spk ? Param.SPK_BASS_MONO_MODE : Param.HP_BASS_MONO_MODE, viperBassMonoMode)
    send(
      spk ? Param.SPK_BASS_MONO_FREQUENCY : Param.HP_BASS_MONO_FREQUENCY,
      viperBassMonoFrequency + 15
    )
    send(spk ? Param.SPK_BASS_MONO_GAIN : Param.HP_BASS_MONO_GAIN, viperBassMonoGain * 50 + 50)
    send(
      spk ? Param.SPK_BASS_MONO_ANTI_POP : Param.HP_BASS_MONO_ANTI_POP, viperBassMonoAntiPop ? 1 : 0
    )
    send(spk ? Param.SPK_CLARITY_ENABLE : Param.HP_CLARITY_ENABLE, viperClarityEnabled ? 1 : 0)
    send(spk ? Param.SPK_CLARITY_MODE : Param.HP_CLARITY_MODE, viperClarityMode)
    send(spk ? Param.SPK_CLARITY_GAIN : Param.HP_CLARITY_GAIN, viperClarityGain * 50)
    send(
      spk ? Param.SPK_FIELD_SURROUND_ENABLE : Param.HP_FIELD_SURROUND_ENABLE,
      fieldSurroundEnabled ? 1 : 0
    )
    send(
      spk ? Param.SPK_FIELD_SURROUND_WIDENING : Param.HP_FIELD_SURROUND_WIDENING,
      Self.fieldSurroundWideningValues[safe: fieldSurroundWidening] ?? 0
    )
    send(
      spk ? Param.SPK_FIELD_SURROUND_MID_IMAGE : Param.HP_FIELD_SURROUND_MID_IMAGE,
      fieldSurroundMidImage * 10 + 100
    )
    send(
      spk ? Param.SPK_FIELD_SURROUND_DEPTH : Param.HP_FIELD_SURROUND_DEPTH,
      fieldSurroundDepth * 75 + 200
    )
    send(
      spk ? Param.SPK_DIFF_SURROUND_ENABLE : Param.HP_DIFF_SURROUND_ENABLE,
      diffSurroundEnabled ? 1 : 0
    )
    send(
      spk ? Param.SPK_DIFF_SURROUND_DELAY : Param.HP_DIFF_SURROUND_DELAY,
      Self.diffSurroundDelayValues[safe: diffSurroundDelay] ?? 500
    )
    send(
      spk ? Param.SPK_DYNAMIC_SYSTEM_ENABLE : Param.HP_DYNAMIC_SYSTEM_ENABLE,
      dynamicSystemEnabled ? 1 : 0
    )
    send(
      spk ? Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS,
      dsXLow, dsXHigh
    )
    send(
      spk ? Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS,
      dsYLow, dsYHigh
    )
    send(
      spk ? Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN : Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN, dsSideGainLow,
      dsSideGainHigh
    )
    send(
      spk ? Param.SPK_DYNAMIC_SYSTEM_STRENGTH : Param.HP_DYNAMIC_SYSTEM_STRENGTH,
      dynamicSystemStrength * 20 + 100
    )
    send(
      spk ? Param.SPK_TUBE_SIMULATOR_ENABLE : Param.HP_TUBE_SIMULATOR_ENABLE,
      tubeSimulatorEnabled ? 1 : 0
    )
    send(spk ? Param.SPK_ANALOGX_ENABLE : Param.HP_ANALOGX_ENABLE, analogXEnabled ? 1 : 0)
    send(spk ? Param.SPK_ANALOGX_MODE : Param.HP_ANALOGX_MODE, analogXMode)
    send(spk ? Param.SPK_CURE_ENABLE : Param.HP_CURE_ENABLE, cureEnabled ? 1 : 0)
    send(spk ? Param.SPK_CURE_STRENGTH : Param.HP_CURE_STRENGTH, cureCrossfeedStrength)
    send(
      spk ? Param.SPK_HEADPHONE_SURROUND_ENABLE : Param.HP_HEADPHONE_SURROUND_ENABLE,
      vheEnabled ? 1 : 0
    )
    send(
      spk ? Param.SPK_HEADPHONE_SURROUND_STRENGTH : Param.HP_HEADPHONE_SURROUND_STRENGTH, vheQuality
    )
    send(
      spk ? Param.SPK_SPECTRUM_EXTENSION_ENABLE : Param.HP_SPECTRUM_EXTENSION_ENABLE,
      spectrumExtensionEnabled ? 1 : 0
    )
    send(
      spk ? Param.SPK_SPECTRUM_EXTENSION_BARK : Param.HP_SPECTRUM_EXTENSION_BARK,
      Self.vseBarkValues[safe: spectrumExtensionBark] ?? 7600
    )
    send(
      spk
        ? Param.SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT
        : Param.HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT,
      Int(Double(spectrumExtensionBarkReconstruct) * 5.6)
    )
    send(
      spk ? Param.SPK_DDC_ENABLE : Param.HP_DDC_ENABLE, ddcEnabled && !ddcFilePath.isEmpty ? 1 : 0
    )
    send(Param.SPK_SPEAKER_CORRECTION_ENABLE, speakerCorrectionEnabled ? 1 : 0)
  }

  func handleDeviceTypeChange(_ newType: AudioOutputDetector.OutputType) {
    let fxType: FXType = newType == .headphone ? .headphone : .speaker
    guard fxType != activeDeviceType else { return }
    logger.info("Device type changed: \(fxType.rawValue) active=\(activeDeviceType.rawValue)")

    saveToMode(isSpk: isSpk)
    activeDeviceType = fxType
    self.fxType = fxType
    let source = isActiveSpk ? speakerState : headphoneState
    loadModeToActive(source)
    dispatchFullModeState()
  }

  private func setupBindings() {
    $isEnabled.dropFirst().sink { on in
      AudioEngine.shared.processingEnabled = on
      logger.info("Processing \(on ? "enabled" : "disabled")")
    }.store(in: &cancellables)

    $fxType.dropFirst().sink { [weak self] newType in
      guard let self else { return }
      logger.info("FX tab switched to \(newType == .speaker ? "speaker" : "headphone")")
      let previousWasSpk = newType == .speaker ? false : true
      self.saveToMode(isSpk: previousWasSpk)
      let source = newType == .speaker ? self.speakerState : self.headphoneState
      self.loadModeToActive(source)
      self.reloadActiveFiles()
    }.store(in: &cancellables)

    $outputVolume.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.outputVolumeValues[safe: idx] ?? 100
      self.send(self.isActiveSpk ? Param.SPK_OUTPUT_VOLUME : Param.HP_OUTPUT_VOLUME, v)
    }.store(in: &cancellables)

    $channelPan.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CHANNEL_PAN : Param.HP_CHANNEL_PAN, v)
    }.store(in: &cancellables)

    $limiter.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.limiterValues[safe: idx] ?? 100
      self.send(self.isActiveSpk ? Param.SPK_LIMITER : Param.HP_LIMITER, v)
    }.store(in: &cancellables)

    $equalizerEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_EQ_ENABLE : Param.HP_EQ_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $viperBassEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_ENABLE : Param.HP_BASS_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $viperBassMode.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_MODE : Param.HP_BASS_MODE, v)
    }.store(in: &cancellables)

    $viperBassFrequency.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_FREQUENCY : Param.HP_BASS_FREQUENCY, v + 15)
    }.store(in: &cancellables)

    $viperBassGain.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_GAIN : Param.HP_BASS_GAIN, v * 50 + 50)
    }.store(in: &cancellables)

    $viperBassAntiPop.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_ANTI_POP : Param.HP_BASS_ANTI_POP, on ? 1 : 0)
    }.store(in: &cancellables)

    $viperBassMonoEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_BASS_MONO_ENABLE : Param.HP_BASS_MONO_ENABLE, on ? 1 : 0
      )
    }.store(in: &cancellables)

    $viperBassMonoMode.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_MONO_MODE : Param.HP_BASS_MONO_MODE, v)
    }.store(in: &cancellables)

    $viperBassMonoFrequency.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_BASS_MONO_FREQUENCY : Param.HP_BASS_MONO_FREQUENCY, v + 15
      )
    }.store(in: &cancellables)

    $viperBassMonoGain.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_BASS_MONO_GAIN : Param.HP_BASS_MONO_GAIN, v * 50 + 50)
    }.store(in: &cancellables)

    $viperBassMonoAntiPop.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_BASS_MONO_ANTI_POP : Param.HP_BASS_MONO_ANTI_POP, on ? 1 : 0
      )
    }.store(in: &cancellables)

    $viperClarityEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CLARITY_ENABLE : Param.HP_CLARITY_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $viperClarityMode.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CLARITY_MODE : Param.HP_CLARITY_MODE, v)
    }.store(in: &cancellables)

    $viperClarityGain.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CLARITY_GAIN : Param.HP_CLARITY_GAIN, v * 50)
    }.store(in: &cancellables)

    $fieldSurroundEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FIELD_SURROUND_ENABLE : Param.HP_FIELD_SURROUND_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $fieldSurroundWidening.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.fieldSurroundWideningValues[safe: idx] ?? 0
      self.send(
        self.isActiveSpk ? Param.SPK_FIELD_SURROUND_WIDENING : Param.HP_FIELD_SURROUND_WIDENING, v
      )
    }.store(in: &cancellables)

    $fieldSurroundMidImage.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FIELD_SURROUND_MID_IMAGE : Param.HP_FIELD_SURROUND_MID_IMAGE,
        v * 10 + 100
      )
    }.store(in: &cancellables)

    $fieldSurroundDepth.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FIELD_SURROUND_DEPTH : Param.HP_FIELD_SURROUND_DEPTH,
        v * 75 + 200
      )
    }.store(in: &cancellables)

    $diffSurroundEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_DIFF_SURROUND_ENABLE : Param.HP_DIFF_SURROUND_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $diffSurroundDelay.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.diffSurroundDelayValues[safe: idx] ?? 500
      self.send(self.isActiveSpk ? Param.SPK_DIFF_SURROUND_DELAY : Param.HP_DIFF_SURROUND_DELAY, v)
    }.store(in: &cancellables)

    $reverberationEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_REVERB_ENABLE : Param.HP_REVERB_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $reverberationRoomSize.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_REVERB_ROOM_SIZE : Param.HP_REVERB_ROOM_SIZE, v * 10)
    }.store(in: &cancellables)

    $reverberationRoomWidth.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_REVERB_ROOM_WIDTH : Param.HP_REVERB_ROOM_WIDTH, v * 10)
    }.store(in: &cancellables)

    $reverberationRoomDampening.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_REVERB_ROOM_DAMPENING : Param.HP_REVERB_ROOM_DAMPENING, v
      )
    }.store(in: &cancellables)

    $reverberationWetSignal.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_REVERB_ROOM_WET_SIGNAL : Param.HP_REVERB_ROOM_WET_SIGNAL, v
      )
    }.store(in: &cancellables)

    $reverberationDrySignal.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_REVERB_ROOM_DRY_SIGNAL : Param.HP_REVERB_ROOM_DRY_SIGNAL, v
      )
    }.store(in: &cancellables)

    $dynamicSystemEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_DYNAMIC_SYSTEM_ENABLE : Param.HP_DYNAMIC_SYSTEM_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $dynamicSystemDevice.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.applyDynamicSystemDevice(idx)
    }.store(in: &cancellables)

    $dynamicSystemStrength.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_DYNAMIC_SYSTEM_STRENGTH : Param.HP_DYNAMIC_SYSTEM_STRENGTH,
        v * 20 + 100
      )
    }.store(in: &cancellables)

    $dsXLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS, v,
        self.dsXHigh
      )
    }.store(in: &cancellables)

    $dsXHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS,
        self.dsXLow, v
      )
    }.store(in: &cancellables)

    $dsYLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS, v,
        self.dsYHigh
      )
    }.store(in: &cancellables)

    $dsYHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS : Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS,
        self.dsYLow, v
      )
    }.store(in: &cancellables)

    $dsSideGainLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN : Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN,
        v, self.dsSideGainHigh
      )
    }.store(in: &cancellables)

    $dsSideGainHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN : Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN,
        self.dsSideGainLow, v
      )
    }.store(in: &cancellables)

    $tubeSimulatorEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_TUBE_SIMULATOR_ENABLE : Param.HP_TUBE_SIMULATOR_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $analogXEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_ANALOGX_ENABLE : Param.HP_ANALOGX_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $analogXMode.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_ANALOGX_MODE : Param.HP_ANALOGX_MODE, v)
    }.store(in: &cancellables)

    $cureEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CURE_ENABLE : Param.HP_CURE_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $cureCrossfeedStrength.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_CURE_STRENGTH : Param.HP_CURE_STRENGTH, v)
    }.store(in: &cancellables)

    $vheEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_HEADPHONE_SURROUND_ENABLE : Param.HP_HEADPHONE_SURROUND_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $vheQuality.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_HEADPHONE_SURROUND_STRENGTH : Param.HP_HEADPHONE_SURROUND_STRENGTH, v
      )
    }.store(in: &cancellables)

    $spectrumExtensionEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_SPECTRUM_EXTENSION_ENABLE : Param.HP_SPECTRUM_EXTENSION_ENABLE,
        on ? 1 : 0
      )
    }.store(in: &cancellables)

    $spectrumExtensionBark.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.vseBarkValues[safe: idx] ?? 7600
      self.send(
        self.isActiveSpk ? Param.SPK_SPECTRUM_EXTENSION_BARK : Param.HP_SPECTRUM_EXTENSION_BARK, v
      )
    }.store(in: &cancellables)

    $spectrumExtensionBarkReconstruct.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT
          : Param.HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT, Int(Double(v) * 5.6)
      )
    }.store(in: &cancellables)

    $fetCompressorEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_ENABLE : Param.HP_FET_COMPRESSOR_ENABLE,
        on ? 100 : 0
      )
    }.store(in: &cancellables)
    $fetCompressorThreshold.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_THRESHOLD : Param.HP_FET_COMPRESSOR_THRESHOLD, v
      )
    }.store(in: &cancellables)
    $fetCompressorRatio.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_RATIO : Param.HP_FET_COMPRESSOR_RATIO, v
      )
    }.store(in: &cancellables)
    $fetCompressorAutoKnee.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_AUTO_KNEE : Param.HP_FET_COMPRESSOR_AUTO_KNEE,
        on ? 100 : 0
      )
    }.store(in: &cancellables)
    $fetCompressorKnee.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_KNEE : Param.HP_FET_COMPRESSOR_KNEE, v)
    }.store(in: &cancellables)
    $fetCompressorKneeMulti.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_KNEE_MULTI : Param.HP_FET_COMPRESSOR_KNEE_MULTI,
        v
      )
    }.store(in: &cancellables)
    $fetCompressorAutoGain.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_AUTO_GAIN : Param.HP_FET_COMPRESSOR_AUTO_GAIN,
        on ? 100 : 0
      )
    }.store(in: &cancellables)
    $fetCompressorGain.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_GAIN : Param.HP_FET_COMPRESSOR_GAIN, v)
    }.store(in: &cancellables)
    $fetCompressorAutoAttack.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_FET_COMPRESSOR_AUTO_ATTACK : Param.HP_FET_COMPRESSOR_AUTO_ATTACK, on ? 100 : 0
      )
    }.store(in: &cancellables)
    $fetCompressorAttack.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_ATTACK : Param.HP_FET_COMPRESSOR_ATTACK, v
      )
    }.store(in: &cancellables)
    $fetCompressorMaxAttack.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_MAX_ATTACK : Param.HP_FET_COMPRESSOR_MAX_ATTACK,
        v
      )
    }.store(in: &cancellables)
    $fetCompressorAutoRelease.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_FET_COMPRESSOR_AUTO_RELEASE : Param.HP_FET_COMPRESSOR_AUTO_RELEASE,
        on ? 100 : 0
      )
    }.store(in: &cancellables)
    $fetCompressorRelease.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_RELEASE : Param.HP_FET_COMPRESSOR_RELEASE, v
      )
    }.store(in: &cancellables)
    $fetCompressorMaxRelease.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk
          ? Param.SPK_FET_COMPRESSOR_MAX_RELEASE : Param.HP_FET_COMPRESSOR_MAX_RELEASE, v
      )
    }.store(in: &cancellables)
    $fetCompressorCrest.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_CREST : Param.HP_FET_COMPRESSOR_CREST, v
      )
    }.store(in: &cancellables)
    $fetCompressorAdapt.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_ADAPT : Param.HP_FET_COMPRESSOR_ADAPT, v
      )
    }.store(in: &cancellables)
    $fetCompressorNoClip.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_FET_COMPRESSOR_NO_CLIP : Param.HP_FET_COMPRESSOR_NO_CLIP,
        on ? 100 : 0
      )
    }.store(in: &cancellables)

    $speakerCorrectionEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(Param.SPK_SPEAKER_CORRECTION_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    $playbackGainEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.isActiveSpk ? Param.SPK_AGC_ENABLE : Param.HP_AGC_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)
    $playbackGainStrength.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.agcRatioValues[safe: idx] ?? 50
      self.send(self.isActiveSpk ? Param.SPK_AGC_RATIO : Param.HP_AGC_RATIO, v)
    }.store(in: &cancellables)
    $playbackGainMaxGain.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.agcMaxGainValues[safe: idx] ?? 100
      self.send(self.isActiveSpk ? Param.SPK_AGC_MAX_SCALER : Param.HP_AGC_MAX_SCALER, v)
    }.store(in: &cancellables)
    $playbackGainOutputThreshold.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let v = Self.limiterValues[safe: idx] ?? 100
      self.send(self.isActiveSpk ? Param.SPK_AGC_VOLUME : Param.HP_AGC_VOLUME, v)
    }.store(in: &cancellables)

    $convolutionEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let effective = on && !self.convolutionKernelPath.isEmpty ? 1 : 0
      self.send(
        self.isActiveSpk ? Param.SPK_CONVOLVER_ENABLE : Param.HP_CONVOLVER_ENABLE, effective
      )
    }.store(in: &cancellables)
    $convolutionCrossChannel.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(
        self.isActiveSpk ? Param.SPK_CONVOLVER_CROSS_CHANNEL : Param.HP_CONVOLVER_CROSS_CHANNEL, v
      )
    }.store(in: &cancellables)

    $ddcEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let effective = on && !self.ddcFilePath.isEmpty ? 1 : 0
      self.send(self.isActiveSpk ? Param.SPK_DDC_ENABLE : Param.HP_DDC_ENABLE, effective)
    }.store(in: &cancellables)
  }

  func sendEQBand(index: Int, level: Float) {
    equalizerBandsMap[equalizerBandCount] = equalizerBands
    let param = isActiveSpk ? Param.SPK_EQ_BAND_LEVEL : Param.HP_EQ_BAND_LEVEL
    send(param, index, Int(level * 100))
  }

  func setEQBandCount(_ count: Int) {
    let oldCount = equalizerBandCount
    logger.debug("EQ band count: \(oldCount) -> \(count)")
    equalizerBandsMap[oldCount] = equalizerBands

    equalizerBandCount = count
    let restored = equalizerBandsMap[count] ?? Array(repeating: 0.0, count: count)
    equalizerBands = restored

    let param = isActiveSpk ? Param.SPK_EQ_BAND_COUNT : Param.HP_EQ_BAND_COUNT
    send(param, count)
    let bandParam = isActiveSpk ? Param.SPK_EQ_BAND_LEVEL : Param.HP_EQ_BAND_LEVEL
    for i in 0 ..< count {
      send(bandParam, i, Int(restored[i] * 100))
    }
  }

  private func applyDynamicSystemDevice(_ index: Int) {
    guard index >= 0 && index < Self.dynamicSystemDevices.count else { return }
    let coeffs = Self.dynamicSystemDevices[index].coeffs
    let parts = coeffs.split(separator: ";").compactMap { Int($0) }
    guard parts.count >= 6 else { return }
    dsXLow = parts[0]
    dsXHigh = parts[1]
    dsYLow = parts[2]
    dsYHigh = parts[3]
    dsSideGainLow = parts[4]
    dsSideGainHigh = parts[5]
  }

  func loadDDCFile(at url: URL) {
    logger.info("Loading DDC: \(url.lastPathComponent)")
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
      logger.error("Failed to load DDC: \(url.lastPathComponent)")
      return
    }
    let lines = content.components(separatedBy: .newlines)

    var coeffs44100: [Float]?
    var coeffs48000: [Float]?

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("SR_44100:") {
        let str = String(trimmed.dropFirst("SR_44100:".count))
        coeffs44100 = str.split(separator: ",").compactMap {
          Float($0.trimmingCharacters(in: .whitespaces))
        }
      } else if trimmed.hasPrefix("SR_48000:") {
        let str = String(trimmed.dropFirst("SR_48000:".count))
        coeffs48000 = str.split(separator: ",").compactMap {
          Float($0.trimmingCharacters(in: .whitespaces))
        }
      }
    }

    guard let c44 = coeffs44100, let c48 = coeffs48000,
          c44.count == c48.count, c44.count % 5 == 0
    else {
      logger.error("Failed to load DDC: \(url.lastPathComponent)")
      return
    }

    let arrSize = c44.count
    let naturalSize = 4 + arrSize * 4 * 2
    let wireSize: Int
    if naturalSize <= 256 {
      wireSize = 256
    } else if naturalSize <= 1024 {
      wireSize = 1024
    } else {
      return
    }

    var buffer = Data(count: wireSize)
    buffer.replaceSubrange(
      0 ..< 4, with: withUnsafeBytes(of: Int32(arrSize).littleEndian) { Data($0) }
    )
    var offset = 4
    for f in c44 {
      buffer.replaceSubrange(
        offset ..< offset + 4, with: withUnsafeBytes(of: f.bitPattern.littleEndian) { Data($0) }
      )
      offset += 4
    }
    for f in c48 {
      buffer.replaceSubrange(
        offset ..< offset + 4, with: withUnsafeBytes(of: f.bitPattern.littleEndian) { Data($0) }
      )
      offset += 4
    }

    bridge.setParameterWithData(
      Int32(isActiveSpk ? Param.SPK_DDC_COEFFICIENTS : Param.HP_DDC_COEFFICIENTS),
      data: buffer as Data
    )
    ddcFilePath = url.lastPathComponent
  }

  func loadConvolverKernel(at url: URL) {
    guard let wavData = try? Data(contentsOf: url) else {
      logger.error("Failed to load convolver kernel: \(url.lastPathComponent)")
      return
    }
    guard let floats = decodeWavToFloat(wavData) else {
      logger.error("Failed to load convolver kernel: \(url.lastPathComponent)")
      return
    }
    let channelCount = getWavChannelCount(wavData)
    let totalFloats = floats.count
    logger.info(
      "Loading convolver kernel: \(url.lastPathComponent) samples=\(floats.count) ch=\(channelCount)"
    )

    let prepareParam =
      isActiveSpk ? Param.SPK_CONVOLVER_PREPARE_BUFFER : Param.HP_CONVOLVER_PREPARE_BUFFER
    let setBufferParam =
      isActiveSpk ? Param.SPK_CONVOLVER_SET_BUFFER : Param.HP_CONVOLVER_SET_BUFFER
    let commitParam =
      isActiveSpk ? Param.SPK_CONVOLVER_COMMIT_BUFFER : Param.HP_CONVOLVER_COMMIT_BUFFER

    send(prepareParam, totalFloats, channelCount)

    var floatBytes = Data(capacity: totalFloats * 4)
    for f in floats {
      withUnsafeBytes(of: f.bitPattern.littleEndian) { floatBytes.append(contentsOf: $0) }
    }

    let crcValue = Self.crc32(floatBytes)

    let maxFloatsPerChunk = 2046
    var offset = 0
    var chunkIndex = 0
    while offset < totalFloats {
      let remaining = totalFloats - offset
      let floatsInChunk = min(remaining, maxFloatsPerChunk)
      let chunkByteCount = floatsInChunk * 4

      var chunkBuffer = Data(count: 8192)
      chunkBuffer.replaceSubrange(
        0 ..< 4, with: withUnsafeBytes(of: Int32(chunkIndex).littleEndian) { Data($0) }
      )
      chunkBuffer.replaceSubrange(
        4 ..< 8, with: withUnsafeBytes(of: Int32(floatsInChunk).littleEndian) { Data($0) }
      )
      chunkBuffer.replaceSubrange(
        8 ..< 8 + chunkByteCount, with: floatBytes[offset * 4 ..< offset * 4 + chunkByteCount]
      )

      bridge.setParameterWithData(Int32(setBufferParam), data: chunkBuffer as Data)
      offset += floatsInChunk
      chunkIndex += 1
    }

    let kernelId = Int32(Self.stableHash(url.lastPathComponent) & 0x7FFF_FFFF)
    send(
      commitParam, totalFloats, Int(Int32(bitPattern: UInt32(truncatingIfNeeded: crcValue))),
      Int(kernelId)
    )

    convolutionKernelPath = url.lastPathComponent
  }

  func refreshFileLists() {
    ddcFiles = ProfileFileManager.shared.listFiles(type: .ddc)
    kernelFiles = ProfileFileManager.shared.listFiles(type: .kernel)
    presetFiles = ProfileFileManager.shared.listFiles(type: .preset)
      .map { ($0 as NSString).deletingPathExtension }
    eqPresetFiles = ProfileFileManager.shared.listFiles(type: .eqPreset)
      .map { ($0 as NSString).deletingPathExtension }
    dsPresetFiles = ProfileFileManager.shared.listFiles(type: .dynSysPreset)
      .map { ($0 as NSString).deletingPathExtension }
  }

  private static let hpKey = "ViPER4Mac.headphoneState"
  private static let spkKey = "ViPER4Mac.speakerState"
  private static let enabledKey = "ViPER4Mac.isEnabled"

  func saveSettings() {
    saveToMode(isSpk: isSpk)
    let encoder = JSONEncoder()
    if let hpData = try? encoder.encode(headphoneState) {
      UserDefaults.standard.set(hpData, forKey: Self.hpKey)
    }
    if let spkData = try? encoder.encode(speakerState) {
      UserDefaults.standard.set(spkData, forKey: Self.spkKey)
    }
    UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
    logger.info("Settings saved to UserDefaults")
  }

  private func restoreSettings() {
    let decoder = JSONDecoder()
    if let hpData = UserDefaults.standard.data(forKey: Self.hpKey),
       let hp = try? decoder.decode(ModeState.self, from: hpData)
    {
      headphoneState = hp
      logger.info("Restored headphone state from UserDefaults")
    }
    if let spkData = UserDefaults.standard.data(forKey: Self.spkKey),
       let spk = try? decoder.decode(ModeState.self, from: spkData)
    {
      speakerState = spk
      logger.info("Restored speaker state from UserDefaults")
    }
    if UserDefaults.standard.object(forKey: Self.enabledKey) != nil {
      isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }
    let source = isActiveSpk ? speakerState : headphoneState
    loadModeToActive(source)
  }

  func importDDC(from url: URL) {
    guard let name = ProfileFileManager.shared.importFile(from: url, type: .ddc) else { return }
    refreshFileLists()
    loadDDCByName(name)
    logger.info("Imported DDC: \(url.lastPathComponent)")
  }

  func importKernel(from url: URL) {
    guard let name = ProfileFileManager.shared.importFile(from: url, type: .kernel) else { return }
    refreshFileLists()
    loadKernelByName(name)
    logger.info("Imported kernel: \(url.lastPathComponent)")
  }

  func loadDDCByName(_ name: String) {
    let url = ProfileFileManager.shared.fileURL(name: name, type: .ddc)
    loadDDCFile(at: url)
    if ddcEnabled {
      send(isActiveSpk ? Param.SPK_DDC_ENABLE : Param.HP_DDC_ENABLE, 1)
    }
  }

  func loadKernelByName(_ name: String) {
    let url = ProfileFileManager.shared.fileURL(name: name, type: .kernel)
    loadConvolverKernel(at: url)
    if convolutionEnabled {
      send(isActiveSpk ? Param.SPK_CONVOLVER_ENABLE : Param.HP_CONVOLVER_ENABLE, 1)
    }
  }

  func deleteDDC(_ name: String) {
    logger.info("Deleting DDC: \(name)")
    ProfileFileManager.shared.deleteFile(name: name, type: .ddc)
    if ddcFilePath == name {
      ddcFilePath = ""
      ddcEnabled = false
    }
    refreshFileLists()
  }

  func deleteKernel(_ name: String) {
    logger.info("Deleting kernel: \(name)")
    ProfileFileManager.shared.deleteFile(name: name, type: .kernel)
    if convolutionKernelPath == name {
      convolutionKernelPath = ""
      convolutionEnabled = false
    }
    refreshFileLists()
  }

  func savePreset(name: String) {
    logger.info("Saving preset: \(name) mode=\(isSpk ? "speaker" : "headphone")")
    saveToMode(isSpk: isSpk)
    var current = isSpk ? speakerState : headphoneState
    current.mode = fxType.rawValue
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(current) else { return }
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .preset)
    try? data.write(to: url)
    refreshFileLists()
  }

  func loadPreset(name: String) {
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .preset)
    guard let data = try? Data(contentsOf: url),
          let preset = try? JSONDecoder().decode(ModeState.self, from: data)
    else { return }
    let targetSpk = preset.mode == FXType.speaker.rawValue
    logger.info(
      "Loading preset: \(name) targetMode=\(targetSpk ? "speaker" : "headphone") viewingSpk=\(isSpk) activeSpk=\(isActiveSpk)"
    )
    if targetSpk {
      speakerState = preset
    } else {
      headphoneState = preset
    }
    if (targetSpk && isSpk) || (!targetSpk && !isSpk) {
      loadModeToActive(preset)
      reloadActiveFiles()
    }
    if (targetSpk && isActiveSpk) || (!targetSpk && !isActiveSpk) {
      dispatchFullModeState()
    }
  }

  func deletePreset(name: String) {
    logger.info("Deleting preset: \(name)")
    ProfileFileManager.shared.deleteFile(name: "\(name).json", type: .preset)
    refreshFileLists()
  }

  func saveEqPreset(name: String) {
    let preset = EqPreset(name: name, bandCount: equalizerBandCount, bands: equalizerBands)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(preset) else { return }
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .eqPreset)
    try? data.write(to: url)
    refreshFileLists()
  }

  func loadEqPreset(name: String) {
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .eqPreset)
    guard let data = try? Data(contentsOf: url),
          let preset = try? JSONDecoder().decode(EqPreset.self, from: data)
    else { return }
    guard preset.bandCount == equalizerBandCount else { return }
    equalizerBands = preset.bands
    equalizerBandsMap[equalizerBandCount] = preset.bands
    let bandParam = isActiveSpk ? Param.SPK_EQ_BAND_LEVEL : Param.HP_EQ_BAND_LEVEL
    for i in 0 ..< preset.bands.count {
      send(bandParam, i, Int(preset.bands[i] * 100))
    }
  }

  func deleteEqPreset(name: String) {
    ProfileFileManager.shared.deleteFile(name: "\(name).json", type: .eqPreset)
    refreshFileLists()
  }

  func saveDsPreset(name: String) {
    let preset = DynSysPreset(
      name: name, xLow: dsXLow, xHigh: dsXHigh, yLow: dsYLow, yHigh: dsYHigh,
      sideGainLow: dsSideGainLow, sideGainHigh: dsSideGainHigh
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(preset) else { return }
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .dynSysPreset)
    try? data.write(to: url)
    refreshFileLists()
  }

  func loadDsPreset(name: String) {
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .dynSysPreset)
    guard let data = try? Data(contentsOf: url),
          let preset = try? JSONDecoder().decode(DynSysPreset.self, from: data)
    else { return }
    dsXLow = preset.xLow
    dsXHigh = preset.xHigh
    dsYLow = preset.yLow
    dsYHigh = preset.yHigh
    dsSideGainLow = preset.sideGainLow
    dsSideGainHigh = preset.sideGainHigh
  }

  func deleteDsPreset(name: String) {
    ProfileFileManager.shared.deleteFile(name: "\(name).json", type: .dynSysPreset)
    refreshFileLists()
  }

  func eqPresetsForCurrentBandCount() -> [String] {
    eqPresetFiles.filter { name in
      let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .eqPreset)
      guard let data = try? Data(contentsOf: url),
            let preset = try? JSONDecoder().decode(EqPreset.self, from: data)
      else { return false }
      return preset.bandCount == equalizerBandCount
    }
  }

  func exportPreset(name: String) -> URL? {
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .preset)
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    return url
  }

  func importPreset(from url: URL) {
    guard let data = try? Data(contentsOf: url),
          (try? JSONDecoder().decode(ModeState.self, from: data)) != nil
    else { return }
    _ = ProfileFileManager.shared.importFile(from: url, type: .preset)
    refreshFileLists()
    logger.info("Imported preset: \(url.lastPathComponent)")
  }

  private static func stableHash(_ string: String) -> Int {
    var hash: UInt32 = 0x811C_9DC5
    for byte in string.utf8 {
      hash ^= UInt32(byte)
      hash &*= 0x0100_0193
    }
    return Int(hash)
  }

  private static func crc32(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
      crc ^= UInt32(byte)
      for _ in 0 ..< 8 {
        crc = (crc >> 1) ^ (crc & 1 != 0 ? 0xEDB8_8320 : 0)
      }
    }
    return crc ^ 0xFFFF_FFFF
  }

  private func getWavChannelCount(_ data: Data) -> Int {
    guard data.count >= 44 else { return 1 }
    let channels: UInt16 = data.withUnsafeBytes { $0.load(fromByteOffset: 22, as: UInt16.self) }
    return Int(UInt16(littleEndian: channels))
  }

  private func decodeWavToFloat(_ data: Data) -> [Float]? {
    guard data.count >= 44 else { return nil }

    let riff = String(data: data[0 ..< 4], encoding: .ascii)
    let wave = String(data: data[8 ..< 12], encoding: .ascii)
    guard riff == "RIFF", wave == "WAVE" else { return nil }

    var audioFormat: UInt16 = 0
    var bitsPerSample: UInt16 = 0
    var dataBytes: Data?

    var pos = 12
    while pos + 8 <= data.count {
      let chunkId = String(data: data[pos ..< pos + 4], encoding: .ascii) ?? ""
      let chunkSize: UInt32 = data.withUnsafeBytes {
        $0.load(fromByteOffset: pos + 4, as: UInt32.self)
      }
      let size = Int(UInt32(littleEndian: chunkSize))
      let contentStart = pos + 8

      switch chunkId {
      case "fmt ":
        guard contentStart + 16 <= data.count else { return nil }
        audioFormat = data.withUnsafeBytes {
          $0.load(fromByteOffset: contentStart, as: UInt16.self)
        }
        audioFormat = UInt16(littleEndian: audioFormat)
        bitsPerSample = data.withUnsafeBytes {
          $0.load(fromByteOffset: contentStart + 14, as: UInt16.self)
        }
        bitsPerSample = UInt16(littleEndian: bitsPerSample)
      case "data":
        let end = min(contentStart + size, data.count)
        dataBytes = data[contentStart ..< end]
      default:
        break
      }
      pos = contentStart + size
      if pos % 2 != 0 { pos += 1 }
    }

    guard let pcmData = dataBytes else { return nil }

    if audioFormat == 3 && bitsPerSample == 32 {
      let count = pcmData.count / 4
      return pcmData.withUnsafeBytes { buf in
        (0 ..< count).map { buf.load(fromByteOffset: $0 * 4, as: Float.self) }
      }
    } else if audioFormat == 1 && bitsPerSample == 16 {
      let count = pcmData.count / 2
      return pcmData.withUnsafeBytes { buf in
        (0 ..< count).map {
          Float(Int16(littleEndian: buf.load(fromByteOffset: $0 * 2, as: Int16.self))) / 32768.0
        }
      }
    } else if audioFormat == 1 && bitsPerSample == 24 {
      let count = pcmData.count / 3
      var result = [Float](repeating: 0, count: count)
      pcmData.withUnsafeBytes { buf in
        for i in 0 ..< count {
          let b0 = Int32(buf.load(fromByteOffset: i * 3, as: UInt8.self))
          let b1 = Int32(buf.load(fromByteOffset: i * 3 + 1, as: UInt8.self))
          let b2 = Int32(buf.load(fromByteOffset: i * 3 + 2, as: UInt8.self))
          let val = (b2 << 24) | (b1 << 16) | (b0 << 8)
          result[i] = Float(val) / Float(Int32.max)
        }
      }
      return result
    }
    return nil
  }
}
