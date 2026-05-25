import Combine
import CoreAudio
import Foundation
import ServiceManagement
import SwiftUI

private let logger = AppLogger(category: "ViPERState")

private enum Param {
  static let SET_RESET_STATUS = 0x10002

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
  static let HP_DIFF_SURROUND_REVERSE = 0x101B2
  static let HP_DIFF_SURROUND_WET_DRY_MIX = 0x101B3
  static let HP_DIFF_SURROUND_LP_CUTOFF = 0x101B4

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

  static let HP_MULTIBAND_COMP_ENABLE = 0x10230
  static let HP_MULTIBAND_COMP_BAND_COUNT = 0x10231
  static let HP_MULTIBAND_COMP_CROSSOVER_FREQ = 0x10232
  static let HP_MULTIBAND_COMP_BAND_THRESHOLD = 0x10233
  static let HP_MULTIBAND_COMP_BAND_RATIO = 0x10234
  static let HP_MULTIBAND_COMP_BAND_KNEE = 0x10235
  static let HP_MULTIBAND_COMP_BAND_AUTO_KNEE = 0x10236
  static let HP_MULTIBAND_COMP_BAND_GAIN = 0x10237
  static let HP_MULTIBAND_COMP_BAND_AUTO_GAIN = 0x10238
  static let HP_MULTIBAND_COMP_BAND_ATTACK = 0x10239
  static let HP_MULTIBAND_COMP_BAND_AUTO_ATTACK = 0x1023A
  static let HP_MULTIBAND_COMP_BAND_RELEASE = 0x1023B
  static let HP_MULTIBAND_COMP_BAND_AUTO_RELEASE = 0x1023C
  static let HP_MULTIBAND_COMP_BAND_KNEE_MULTI = 0x1023D
  static let HP_MULTIBAND_COMP_BAND_MAX_ATTACK = 0x1023E
  static let HP_MULTIBAND_COMP_BAND_MAX_RELEASE = 0x1023F
  static let HP_MULTIBAND_COMP_BAND_CREST = 0x10240
  static let HP_MULTIBAND_COMP_BAND_ADAPT = 0x10241
  static let HP_MULTIBAND_COMP_BAND_NO_CLIP = 0x10242
  static let HP_MULTIBAND_COMP_BAND_ENABLE = 0x10243

  static let HP_STEREO_IMAGER_ENABLE = 0x10250
  static let HP_STEREO_IMAGER_LOW_WIDTH = 0x10251
  static let HP_STEREO_IMAGER_MID_WIDTH = 0x10252
  static let HP_STEREO_IMAGER_HIGH_WIDTH = 0x10253
  static let HP_STEREO_IMAGER_LOW_CROSSOVER = 0x10254
  static let HP_STEREO_IMAGER_HIGH_CROSSOVER = 0x10255

  static let HP_DYNAMIC_EQ_ENABLE = 0x10260
  static let HP_DYNAMIC_EQ_BAND_COUNT = 0x10261
  static let HP_DYNAMIC_EQ_BAND_FREQ = 0x10262
  static let HP_DYNAMIC_EQ_BAND_Q = 0x10263
  static let HP_DYNAMIC_EQ_BAND_GAIN = 0x10264
  static let HP_DYNAMIC_EQ_BAND_THRESHOLD = 0x10265
  static let HP_DYNAMIC_EQ_BAND_ATTACK = 0x10266
  static let HP_DYNAMIC_EQ_BAND_RELEASE = 0x10267
  static let HP_DYNAMIC_EQ_BAND_FILTER_TYPE = 0x10268

  static let HP_LUFS_ENABLE = 0x10270
  static let HP_LUFS_TARGET = 0x10271
  static let HP_LUFS_MAX_GAIN = 0x10272
  static let HP_LUFS_SPEED = 0x10273

  static let HP_PSYCHO_BASS_ENABLE = 0x10280
  static let HP_PSYCHO_BASS_CUTOFF = 0x10281
  static let HP_PSYCHO_BASS_INTENSITY = 0x10282
  static let HP_PSYCHO_BASS_HARMONIC_ORDER = 0x10283
  static let HP_PSYCHO_BASS_ORIGINAL_LEVEL = 0x10284

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
  static let SPK_DIFF_SURROUND_REVERSE = 0x103B2
  static let SPK_DIFF_SURROUND_WET_DRY_MIX = 0x103B3
  static let SPK_DIFF_SURROUND_LP_CUTOFF = 0x103B4

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

  static let SPK_MULTIBAND_COMP_ENABLE = 0x10430
  static let SPK_MULTIBAND_COMP_BAND_COUNT = 0x10431
  static let SPK_MULTIBAND_COMP_CROSSOVER_FREQ = 0x10432
  static let SPK_MULTIBAND_COMP_BAND_THRESHOLD = 0x10433
  static let SPK_MULTIBAND_COMP_BAND_RATIO = 0x10434
  static let SPK_MULTIBAND_COMP_BAND_KNEE = 0x10435
  static let SPK_MULTIBAND_COMP_BAND_AUTO_KNEE = 0x10436
  static let SPK_MULTIBAND_COMP_BAND_GAIN = 0x10437
  static let SPK_MULTIBAND_COMP_BAND_AUTO_GAIN = 0x10438
  static let SPK_MULTIBAND_COMP_BAND_ATTACK = 0x10439
  static let SPK_MULTIBAND_COMP_BAND_AUTO_ATTACK = 0x1043A
  static let SPK_MULTIBAND_COMP_BAND_RELEASE = 0x1043B
  static let SPK_MULTIBAND_COMP_BAND_AUTO_RELEASE = 0x1043C
  static let SPK_MULTIBAND_COMP_BAND_KNEE_MULTI = 0x1043D
  static let SPK_MULTIBAND_COMP_BAND_MAX_ATTACK = 0x1043E
  static let SPK_MULTIBAND_COMP_BAND_MAX_RELEASE = 0x1043F
  static let SPK_MULTIBAND_COMP_BAND_CREST = 0x10440
  static let SPK_MULTIBAND_COMP_BAND_ADAPT = 0x10441
  static let SPK_MULTIBAND_COMP_BAND_NO_CLIP = 0x10442
  static let SPK_MULTIBAND_COMP_BAND_ENABLE = 0x10443

  static let SPK_STEREO_IMAGER_ENABLE = 0x10450
  static let SPK_STEREO_IMAGER_LOW_WIDTH = 0x10451
  static let SPK_STEREO_IMAGER_MID_WIDTH = 0x10452
  static let SPK_STEREO_IMAGER_HIGH_WIDTH = 0x10453
  static let SPK_STEREO_IMAGER_LOW_CROSSOVER = 0x10454
  static let SPK_STEREO_IMAGER_HIGH_CROSSOVER = 0x10455

  static let SPK_DYNAMIC_EQ_ENABLE = 0x10460
  static let SPK_DYNAMIC_EQ_BAND_COUNT = 0x10461
  static let SPK_DYNAMIC_EQ_BAND_FREQ = 0x10462
  static let SPK_DYNAMIC_EQ_BAND_Q = 0x10463
  static let SPK_DYNAMIC_EQ_BAND_GAIN = 0x10464
  static let SPK_DYNAMIC_EQ_BAND_THRESHOLD = 0x10465
  static let SPK_DYNAMIC_EQ_BAND_ATTACK = 0x10466
  static let SPK_DYNAMIC_EQ_BAND_RELEASE = 0x10467
  static let SPK_DYNAMIC_EQ_BAND_FILTER_TYPE = 0x10468

  static let SPK_LUFS_ENABLE = 0x10470
  static let SPK_LUFS_TARGET = 0x10471
  static let SPK_LUFS_MAX_GAIN = 0x10472
  static let SPK_LUFS_SPEED = 0x10473

  static let SPK_PSYCHO_BASS_ENABLE = 0x10480
  static let SPK_PSYCHO_BASS_CUTOFF = 0x10481
  static let SPK_PSYCHO_BASS_INTENSITY = 0x10482
  static let SPK_PSYCHO_BASS_HARMONIC_ORDER = 0x10483
  static let SPK_PSYCHO_BASS_ORIGINAL_LEVEL = 0x10484
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

  struct BuiltinDsPreset {
    let key: String
    let name: LocalizedStringKey
    let coeffs: String
  }

  static let dynamicSystemDevices: [BuiltinDsPreset] = [
    BuiltinDsPreset(key: "ds_device_extreme_headphone_v2", name: "Extreme Headphone (v2)", coeffs: "140;6200;40;60;10;80"),
    BuiltinDsPreset(key: "ds_device_high_end_headphone_v2", name: "High-End Headphone (v2)", coeffs: "180;5800;55;80;10;70"),
    BuiltinDsPreset(key: "ds_device_common_headphone_v2", name: "Common Headphone (v2)", coeffs: "300;5600;60;105;10;50"),
    BuiltinDsPreset(key: "ds_device_low_end_headphone_v2", name: "Low-End Headphone (v2)", coeffs: "600;5400;60;105;10;20"),
    BuiltinDsPreset(key: "ds_device_common_earphone_v2", name: "Common Earphone (v2)", coeffs: "100;5600;40;80;50;50"),
    BuiltinDsPreset(key: "ds_device_extreme_headphone_v1", name: "Extreme Headphone (v1)", coeffs: "1200;6200;40;80;0;20"),
    BuiltinDsPreset(key: "ds_device_high_end_headphone_v1", name: "High-End Headphone (v1)", coeffs: "1000;6200;40;80;0;10"),
    BuiltinDsPreset(key: "ds_device_common_headphone_v1", name: "Common Headphone (v1)", coeffs: "800;6200;40;80;10;0"),
    BuiltinDsPreset(key: "ds_device_common_earphone_v1", name: "Common Earphone (v1)", coeffs: "400;6200;40;80;10;0"),
  ]

  struct OutputState: Codable {
    var volume: Int = 100
    var pan: Int = 0
    var limiter: Int = 100
  }

  struct AgcState: Codable {
    var enabled = false
    var strength: Int = 50
    var maxGain: Int = 100
    var outputThreshold: Int = 100
  }

  struct FetState: Codable {
    var enabled = false
    var threshold: Int = -18
    var ratio: Int = 100
    var autoKnee = true
    var knee: Int = 0
    var kneeMulti: Int = 0
    var autoGain = true
    var gain: Int = 0
    var autoAttack = true
    var attack: Int = 1
    var maxAttack: Int = 44
    var autoRelease = true
    var release: Int = 100
    var maxRelease: Int = 200
    var crest: Int = 100
    var adapt: Int = 50
    var noClip = true
  }

  struct MbcState: Codable {
    var enabled = false
    var crossovers: [Int] = [120, 500, 4000, 8000]
    var bandEnables: [Bool] = [true, true, true, true, true]
    var thresholds: [Int] = [-18, -18, -18, -18, -18]
    var ratios: [Int] = [50, 50, 50, 50, 50]
    var gains: [Int] = [24, 24, 24, 24, 24]
    var knees: [Int] = [0, 0, 0, 0, 0]
    var attacks: [Int] = [1, 1, 1, 1, 1]
    var releases: [Int] = [100, 100, 100, 100, 100]
    var autoGains: [Bool] = [true, true, true, true, true]
    var autoAttacks: [Bool] = [true, true, true, true, true]
    var autoReleases: [Bool] = [true, true, true, true, true]
    var autoKnees: [Bool] = [true, true, true, true, true]
    var kneeMultis: [Int] = [0, 0, 0, 0, 0]
    var maxAttacks: [Int] = [44, 44, 44, 44, 44]
    var maxReleases: [Int] = [200, 200, 200, 200, 200]
    var crests: [Int] = [100, 100, 100, 100, 100]
    var adapts: [Int] = [50, 50, 50, 50, 50]
    var noClips: [Bool] = [true, true, true, true, true]
  }

  struct DynEqState: Codable {
    var enabled = false
    var bandCount: Int = 3
    var freqs: [Int] = [400, 1000, 5000]
    var qs: [Int] = [150, 150, 200]
    var gains: [Int] = [0, 0, 0]
    var thresholds: [Int] = [-250, -250, -200]
    var attacks: [Int] = [10, 10, 10]
    var releases: [Int] = [100, 100, 100]
    var filterTypes: [Int] = [0, 0, 0]
  }

  struct StereoImagerState: Codable {
    var enabled = false
    var lowWidth: Int = 100
    var midWidth: Int = 100
    var highWidth: Int = 100
    var lowCrossover: Int = 200
    var highCrossover: Int = 4000
  }

  struct LufsState: Codable {
    var enabled = false
    var target: Int = 140
    var maxGain: Int = 60
    var speed: Int = 1
  }

  struct PsychoBassState: Codable {
    var enabled = false
    var cutoff: Int = 80
    var intensity: Int = 50
    var harmonicOrder: Int = 3
    var originalLevel: Int = 100
  }

  struct DdcState: Codable {
    var enabled = false
    var filePath: String = ""
  }

  struct VseState: Codable {
    var enabled = false
    var bark: Int = 7600
    var barkReconstruct: Int = 0
  }

  struct EqState: Codable {
    var enabled = false
    var bandCount: Int = 10
    var bands: [Float] = Array(repeating: 0.0, count: 10)
    var bandsMap: [Int: [Float]] = [10: Array(repeating: 0.0, count: 10)]
  }

  struct ConvolverState: Codable {
    var enabled = false
    var kernelPath: String = ""
    var crossChannel: Int = 0
  }

  struct FieldSurroundState: Codable {
    var enabled = false
    var widening: Int = 0
    var midImage: Int = 5
    var depth: Int = 0
  }

  struct DiffSurroundState: Codable {
    var enabled = false
    var delay: Int = 5
    var reverse: Bool = false
    var wetDryMix: Int = 100
    var lpCutoff: Int = 0
  }

  struct VheState: Codable {
    var enabled = false
    var quality: Int = 0
  }

  struct ReverbState: Codable {
    var enabled = false
    var roomSize: Int = 0
    var roomWidth: Int = 0
    var dampening: Int = 0
    var wet: Int = 0
    var dry: Int = 50
  }

  struct DynamicSystemState: Codable {
    var enabled = false
    var device: Int = 0
    var strength: Int = 50
    var xLow: Int = 100
    var xHigh: Int = 5600
    var yLow: Int = 40
    var yHigh: Int = 80
    var sideGainLow: Int = 50
    var sideGainHigh: Int = 50
  }

  struct BassState: Codable {
    var enabled = false
    var mode: Int = 0
    var frequency: Int = 55
    var gain: Int = 50
    var antiPop: Bool = true
    var monoEnabled = false
    var monoMode: Int = 0
    var monoFrequency: Int = 55
    var monoGain: Int = 50
    var monoAntiPop: Bool = true
  }

  struct ClarityState: Codable {
    var enabled = false
    var mode: Int = 0
    var gain: Int = 50
  }

  struct TubeState: Codable {
    var enabled = false
  }

  struct CureState: Codable {
    var enabled = false
    var strength: Int = 0
  }

  struct AnalogXState: Codable {
    var enabled = false
    var mode: Int = 0
  }

  struct SpeakerCorrectionState: Codable {
    var enabled = false
  }

  struct ModeState: Codable {
    var mode: Int = 0
    var output = OutputState()
    var agc = AgcState()
    var fet = FetState()
    var mbc = MbcState()
    var dynEq = DynEqState()
    var stereoImg = StereoImagerState()
    var lufs = LufsState()
    var psychoBass = PsychoBassState()
    var ddc = DdcState()
    var vse = VseState()
    var eq = EqState()
    var convolver = ConvolverState()
    var fieldSurround = FieldSurroundState()
    var diffSurround = DiffSurroundState()
    var vhe = VheState()
    var reverb = ReverbState()
    var dynamicSystem = DynamicSystemState()
    var bass = BassState()
    var clarity = ClarityState()
    var tube = TubeState()
    var cure = CureState()
    var analogX = AnalogXState()
    var speakerCorrection = SpeakerCorrectionState()
  }

  private var headphoneState = ModeState()
  private var speakerState = ModeState()
  private var suppressDispatch = false
  private var suppressFxTypeSink = false

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

  @Published var outputVolume: Int = 100
  @Published var channelPan: Int = 0
  @Published var limiter: Int = 100

  @Published var convolutionEnabled = false
  @Published var convolutionCrossChannel: Int = 0
  @Published var convolutionKernelPath: String = ""

  @Published var vheEnabled = false
  @Published var vheQuality: Int = 0

  @Published var ddcEnabled = false
  @Published var ddcFilePath: String = ""

  @Published var spectrumExtensionEnabled = false
  @Published var spectrumExtensionBark: Int = 7600
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
  @Published var diffSurroundDelay: Int = 5
  @Published var diffSurroundReverse: Bool = false
  @Published var diffSurroundWetDryMix: Int = 100
  @Published var diffSurroundLpCutoff: Int = 0

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
  @Published var fetCompressorThreshold: Int = -18
  @Published var fetCompressorRatio: Int = 100
  @Published var fetCompressorAutoKnee = true
  @Published var fetCompressorKnee: Int = 0
  @Published var fetCompressorKneeMulti: Int = 0
  @Published var fetCompressorAutoGain = true
  @Published var fetCompressorGain: Int = 0
  @Published var fetCompressorAutoAttack = true
  @Published var fetCompressorAttack: Int = 1
  @Published var fetCompressorMaxAttack: Int = 44
  @Published var fetCompressorAutoRelease = true
  @Published var fetCompressorRelease: Int = 100
  @Published var fetCompressorMaxRelease: Int = 200
  @Published var fetCompressorCrest: Int = 100
  @Published var fetCompressorAdapt: Int = 50
  @Published var fetCompressorNoClip = true

  @Published var stereoImgEnabled = false
  @Published var stereoImgLowWidth: Int = 100
  @Published var stereoImgMidWidth: Int = 100
  @Published var stereoImgHighWidth: Int = 100
  @Published var stereoImgLowCrossover: Int = 200
  @Published var stereoImgHighCrossover: Int = 4000

  @Published var lufsEnabled = false
  @Published var lufsTarget: Int = 140
  @Published var lufsMaxGain: Int = 60
  @Published var lufsSpeed: Int = 1

  @Published var psychoBassEnabled = false
  @Published var psychoBassCutoff: Int = 80
  @Published var psychoBassIntensity: Int = 50
  @Published var psychoBassHarmonicOrder: Int = 3
  @Published var psychoBassOriginalLevel: Int = 100

  @Published var dynEqEnabled = false
  @Published var dynEqBandCount: Int = 3
  @Published var dynEqSelectedBand: Int = 0
  @Published var dynEqFreqs: [Int] = [400, 1000, 5000]
  @Published var dynEqQs: [Int] = [150, 150, 200]
  @Published var dynEqGains: [Int] = [0, 0, 0]
  @Published var dynEqThresholds: [Int] = [-250, -250, -200]
  @Published var dynEqAttacks: [Int] = [10, 10, 10]
  @Published var dynEqReleases: [Int] = [100, 100, 100]
  @Published var dynEqFilterTypes: [Int] = [0, 0, 0]

  @Published var mbcEnabled = false
  @Published var mbcSelectedBand: Int = 0
  @Published var mbcCrossovers: [Int] = [120, 500, 4000, 8000]
  @Published var mbcThresholds: [Int] = [-18, -18, -18, -18, -18]
  @Published var mbcRatios: [Int] = [50, 50, 50, 50, 50]
  @Published var mbcGains: [Int] = [24, 24, 24, 24, 24]
  @Published var mbcKnees: [Int] = [0, 0, 0, 0, 0]
  @Published var mbcAttacks: [Int] = [1, 1, 1, 1, 1]
  @Published var mbcReleases: [Int] = [100, 100, 100, 100, 100]
  @Published var mbcAutoGains: [Bool] = [true, true, true, true, true]
  @Published var mbcAutoAttacks: [Bool] = [true, true, true, true, true]
  @Published var mbcAutoReleases: [Bool] = [true, true, true, true, true]
  @Published var mbcAutoKnees: [Bool] = [true, true, true, true, true]
  @Published var mbcKneeMultis: [Int] = [0, 0, 0, 0, 0]
  @Published var mbcMaxAttacks: [Int] = [44, 44, 44, 44, 44]
  @Published var mbcMaxReleases: [Int] = [200, 200, 200, 200, 200]
  @Published var mbcCrests: [Int] = [100, 100, 100, 100, 100]
  @Published var mbcAdapts: [Int] = [50, 50, 50, 50, 50]
  @Published var mbcBandEnables: [Bool] = [true, true, true, true, true]
  @Published var mbcNoClips: [Bool] = [true, true, true, true, true]

  @Published var viperBassEnabled = false
  @Published var viperBassMode: Int = 0
  @Published var viperBassFrequency: Int = 55
  @Published var viperBassGain: Int = 50
  @Published var viperBassAntiPop: Bool = true

  @Published var viperBassMonoEnabled = false
  @Published var viperBassMonoMode: Int = 0
  @Published var viperBassMonoFrequency: Int = 55
  @Published var viperBassMonoGain: Int = 50
  @Published var viperBassMonoAntiPop: Bool = true

  @Published var viperClarityEnabled = false
  @Published var viperClarityMode: Int = 0
  @Published var viperClarityGain: Int = 50

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

  @Published var currentDeviceUID: String = ""
  @Published var currentDeviceName: String = ""

  @Published var isProcessing = false
  @Published var currentSampleRate: UInt32 = 0
  @Published var outputDeviceName: String = "None"
  @Published var dspVersion: String = "N/A"
  private var lastProcessedFrames: UInt64 = 0
  private var statusTimer: Timer?

  @Published var playbackGainEnabled = false
  @Published var playbackGainStrength: Int = 50
  @Published var playbackGainMaxGain: Int = 100
  @Published var playbackGainOutputThreshold: Int = 100

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
    refreshEngineStatus()
    statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.refreshEngineStatus()
    }
  }

  func refreshEngineStatus() {
    let engine = AudioEngine.shared
    outputDeviceName = engine.outputDeviceName
    currentSampleRate = bridge.getSamplingRate()
    dspVersion = "\(bridge.getVersionName()) (\(bridge.getVersionCode()))"
    let processedFrames = bridge.getProcessedFrames()
    isProcessing = processedFrames > 0 && processedFrames != lastProcessedFrames
    lastProcessedFrames = processedFrames
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

  private static func fetThresholdToRaw(_ dB: Int) -> Int {
    Int((Double(dB) / -60.0 * 100.0).rounded())
  }

  private static func fetKneeToRaw(_ dB: Int) -> Int {
    Int((Double(dB) / 60.0 * 100.0).rounded())
  }

  private static func fetGainToRaw(_ dB: Int) -> Int {
    Int((Double(dB) / 60.0 * 100.0).rounded())
  }

  private static func fetAttackMsToRaw(_ ms: Int) -> Int {
    let sec = Double(ms) / 1000.0
    let value = (log(sec) + 9.21034) / 7.600903 * 100.0
    return min(max(Int(value.rounded()), 0), 200)
  }

  private static func fetReleaseMsToRaw(_ ms: Int) -> Int {
    let sec = Double(ms) / 1000.0
    let value = (log(sec) + 5.298317) / 5.991465 * 100.0
    return min(max(Int(value.rounded()), 0), 200)
  }

  static func bassFrequencyToRaw(_ value: Int) -> Int {
    value + 15
  }

  static func bassGainToRaw(_ value: Int) -> Int {
    value
  }

  static func clarityGainToRaw(_ value: Int) -> Int {
    value
  }

  static func fieldSurroundWideningToRaw(_ value: Int) -> Int {
    value * 100
  }

  static func fieldSurroundMidImageToRaw(_ value: Int) -> Int {
    value * 10 + 100
  }

  static func fieldSurroundDepthToRaw(_ value: Int) -> Int {
    value * 75 + 200
  }

  static func dynamicSystemStrengthToRaw(_ value: Int) -> Int {
    value * 20 + 100
  }

  static func diffSurroundDelayToRaw(_ ms: Int) -> Int {
    ms * 100
  }

  static func vseExciterToRaw(_ value: Int) -> Int {
    Int(Double(value) * 5.6)
  }

  private func send(_ param: Int, _ val1: Int, _ val2: Int = 0, _ val3: Int = 0, _ val4: Int = 0) {
    logger.debug("DSP param=\(param) v1=\(val1) v2=\(val2) v3=\(val3) v4=\(val4)")
    bridge.setParameter(
      Int32(param), value1: Int32(val1), value2: Int32(val2),
      value3: Int32(val3), value4: Int32(val4)
    )
  }

  private func p(_ hp: Int, _ spk: Int) -> Int {
    isActiveSpk ? spk : hp
  }

  private func saveToMode(isSpk spk: Bool) {
    var s = ModeState()
    s.output.volume = outputVolume
    s.output.pan = channelPan
    s.output.limiter = limiter
    s.convolver.enabled = convolutionEnabled
    s.convolver.crossChannel = convolutionCrossChannel
    s.convolver.kernelPath = convolutionKernelPath
    s.vhe.enabled = vheEnabled
    s.vhe.quality = vheQuality
    s.ddc.enabled = ddcEnabled
    s.ddc.filePath = ddcFilePath
    s.vse.enabled = spectrumExtensionEnabled
    s.vse.bark = spectrumExtensionBark
    s.vse.barkReconstruct = spectrumExtensionBarkReconstruct
    s.eq.enabled = equalizerEnabled
    s.eq.bandCount = equalizerBandCount
    s.eq.bands = equalizerBands
    s.eq.bandsMap = equalizerBandsMap
    s.fieldSurround.enabled = fieldSurroundEnabled
    s.fieldSurround.widening = fieldSurroundWidening
    s.fieldSurround.midImage = fieldSurroundMidImage
    s.fieldSurround.depth = fieldSurroundDepth
    s.diffSurround.enabled = diffSurroundEnabled
    s.diffSurround.delay = diffSurroundDelay
    s.diffSurround.reverse = diffSurroundReverse
    s.diffSurround.wetDryMix = diffSurroundWetDryMix
    s.diffSurround.lpCutoff = diffSurroundLpCutoff
    s.reverb.enabled = reverberationEnabled
    s.reverb.roomSize = reverberationRoomSize
    s.reverb.roomWidth = reverberationRoomWidth
    s.reverb.dampening = reverberationRoomDampening
    s.reverb.wet = reverberationWetSignal
    s.reverb.dry = reverberationDrySignal
    s.dynamicSystem.enabled = dynamicSystemEnabled
    s.dynamicSystem.device = dynamicSystemDevice
    s.dynamicSystem.strength = dynamicSystemStrength
    s.dynamicSystem.xLow = dsXLow
    s.dynamicSystem.xHigh = dsXHigh
    s.dynamicSystem.yLow = dsYLow
    s.dynamicSystem.yHigh = dsYHigh
    s.dynamicSystem.sideGainLow = dsSideGainLow
    s.dynamicSystem.sideGainHigh = dsSideGainHigh
    s.tube.enabled = tubeSimulatorEnabled
    s.cure.enabled = cureEnabled
    s.cure.strength = cureCrossfeedStrength
    s.analogX.enabled = analogXEnabled
    s.analogX.mode = analogXMode
    s.speakerCorrection.enabled = speakerCorrectionEnabled
    s.bass.enabled = viperBassEnabled
    s.bass.mode = viperBassMode
    s.bass.frequency = viperBassFrequency
    s.bass.gain = viperBassGain
    s.bass.antiPop = viperBassAntiPop
    s.bass.monoEnabled = viperBassMonoEnabled
    s.bass.monoMode = viperBassMonoMode
    s.bass.monoFrequency = viperBassMonoFrequency
    s.bass.monoGain = viperBassMonoGain
    s.bass.monoAntiPop = viperBassMonoAntiPop
    s.clarity.enabled = viperClarityEnabled
    s.clarity.mode = viperClarityMode
    s.clarity.gain = viperClarityGain
    s.agc.enabled = playbackGainEnabled
    s.agc.strength = playbackGainStrength
    s.agc.maxGain = playbackGainMaxGain
    s.agc.outputThreshold = playbackGainOutputThreshold
    s.fet.enabled = fetCompressorEnabled
    s.fet.threshold = fetCompressorThreshold
    s.fet.ratio = fetCompressorRatio
    s.fet.autoKnee = fetCompressorAutoKnee
    s.fet.knee = fetCompressorKnee
    s.fet.kneeMulti = fetCompressorKneeMulti
    s.fet.autoGain = fetCompressorAutoGain
    s.fet.gain = fetCompressorGain
    s.fet.autoAttack = fetCompressorAutoAttack
    s.fet.attack = fetCompressorAttack
    s.fet.maxAttack = fetCompressorMaxAttack
    s.fet.autoRelease = fetCompressorAutoRelease
    s.fet.release = fetCompressorRelease
    s.fet.maxRelease = fetCompressorMaxRelease
    s.fet.crest = fetCompressorCrest
    s.fet.adapt = fetCompressorAdapt
    s.fet.noClip = fetCompressorNoClip
    s.stereoImg.enabled = stereoImgEnabled
    s.stereoImg.lowWidth = stereoImgLowWidth
    s.stereoImg.midWidth = stereoImgMidWidth
    s.stereoImg.highWidth = stereoImgHighWidth
    s.stereoImg.lowCrossover = stereoImgLowCrossover
    s.stereoImg.highCrossover = stereoImgHighCrossover
    s.lufs.enabled = lufsEnabled
    s.lufs.target = lufsTarget
    s.lufs.maxGain = lufsMaxGain
    s.lufs.speed = lufsSpeed
    s.psychoBass.enabled = psychoBassEnabled
    s.psychoBass.cutoff = psychoBassCutoff
    s.psychoBass.intensity = psychoBassIntensity
    s.psychoBass.harmonicOrder = psychoBassHarmonicOrder
    s.psychoBass.originalLevel = psychoBassOriginalLevel
    s.dynEq.enabled = dynEqEnabled
    s.dynEq.bandCount = dynEqBandCount
    s.dynEq.freqs = dynEqFreqs
    s.dynEq.qs = dynEqQs
    s.dynEq.gains = dynEqGains
    s.dynEq.thresholds = dynEqThresholds
    s.dynEq.attacks = dynEqAttacks
    s.dynEq.releases = dynEqReleases
    s.dynEq.filterTypes = dynEqFilterTypes
    s.mbc.enabled = mbcEnabled
    s.mbc.crossovers = mbcCrossovers
    s.mbc.thresholds = mbcThresholds
    s.mbc.ratios = mbcRatios
    s.mbc.gains = mbcGains
    s.mbc.knees = mbcKnees
    s.mbc.attacks = mbcAttacks
    s.mbc.releases = mbcReleases
    s.mbc.autoGains = mbcAutoGains
    s.mbc.autoAttacks = mbcAutoAttacks
    s.mbc.autoReleases = mbcAutoReleases
    s.mbc.autoKnees = mbcAutoKnees
    s.mbc.kneeMultis = mbcKneeMultis
    s.mbc.maxAttacks = mbcMaxAttacks
    s.mbc.maxReleases = mbcMaxReleases
    s.mbc.crests = mbcCrests
    s.mbc.adapts = mbcAdapts
    s.mbc.bandEnables = mbcBandEnables
    s.mbc.noClips = mbcNoClips
    if spk { speakerState = s } else { headphoneState = s }
    logger.debug("Saved state to \(spk ? "speaker" : "headphone")")
  }

  private func loadModeToActive(_ s: ModeState) {
    logger.debug("Loading state from mode=\(s.mode)")
    suppressDispatch = true
    outputVolume = s.output.volume
    channelPan = s.output.pan
    limiter = s.output.limiter
    convolutionEnabled = s.convolver.enabled
    convolutionCrossChannel = s.convolver.crossChannel
    convolutionKernelPath = s.convolver.kernelPath
    vheEnabled = s.vhe.enabled
    vheQuality = s.vhe.quality
    ddcEnabled = s.ddc.enabled
    ddcFilePath = s.ddc.filePath
    spectrumExtensionEnabled = s.vse.enabled
    spectrumExtensionBark = s.vse.bark
    spectrumExtensionBarkReconstruct = s.vse.barkReconstruct
    equalizerEnabled = s.eq.enabled
    equalizerBandCount = s.eq.bandCount
    equalizerBands = s.eq.bands
    equalizerBandsMap = s.eq.bandsMap
    fieldSurroundEnabled = s.fieldSurround.enabled
    fieldSurroundWidening = s.fieldSurround.widening
    fieldSurroundMidImage = s.fieldSurround.midImage
    fieldSurroundDepth = s.fieldSurround.depth
    diffSurroundEnabled = s.diffSurround.enabled
    diffSurroundDelay = s.diffSurround.delay
    diffSurroundReverse = s.diffSurround.reverse
    diffSurroundWetDryMix = s.diffSurround.wetDryMix
    diffSurroundLpCutoff = s.diffSurround.lpCutoff
    reverberationEnabled = s.reverb.enabled
    reverberationRoomSize = s.reverb.roomSize
    reverberationRoomWidth = s.reverb.roomWidth
    reverberationRoomDampening = s.reverb.dampening
    reverberationWetSignal = s.reverb.wet
    reverberationDrySignal = s.reverb.dry
    dynamicSystemEnabled = s.dynamicSystem.enabled
    dynamicSystemDevice = s.dynamicSystem.device
    dynamicSystemStrength = s.dynamicSystem.strength
    dsXLow = s.dynamicSystem.xLow
    dsXHigh = s.dynamicSystem.xHigh
    dsYLow = s.dynamicSystem.yLow
    dsYHigh = s.dynamicSystem.yHigh
    dsSideGainLow = s.dynamicSystem.sideGainLow
    dsSideGainHigh = s.dynamicSystem.sideGainHigh
    tubeSimulatorEnabled = s.tube.enabled
    cureEnabled = s.cure.enabled
    cureCrossfeedStrength = s.cure.strength
    analogXEnabled = s.analogX.enabled
    analogXMode = s.analogX.mode
    speakerCorrectionEnabled = s.speakerCorrection.enabled
    viperBassEnabled = s.bass.enabled
    viperBassMode = s.bass.mode
    viperBassFrequency = s.bass.frequency
    viperBassGain = s.bass.gain
    viperBassAntiPop = s.bass.antiPop
    viperBassMonoEnabled = s.bass.monoEnabled
    viperBassMonoMode = s.bass.monoMode
    viperBassMonoFrequency = s.bass.monoFrequency
    viperBassMonoGain = s.bass.monoGain
    viperBassMonoAntiPop = s.bass.monoAntiPop
    viperClarityEnabled = s.clarity.enabled
    viperClarityMode = s.clarity.mode
    viperClarityGain = s.clarity.gain
    playbackGainEnabled = s.agc.enabled
    playbackGainStrength = s.agc.strength
    playbackGainMaxGain = s.agc.maxGain
    playbackGainOutputThreshold = s.agc.outputThreshold
    fetCompressorEnabled = s.fet.enabled
    fetCompressorThreshold = s.fet.threshold
    fetCompressorRatio = s.fet.ratio
    fetCompressorAutoKnee = s.fet.autoKnee
    fetCompressorKnee = s.fet.knee
    fetCompressorKneeMulti = s.fet.kneeMulti
    fetCompressorAutoGain = s.fet.autoGain
    fetCompressorGain = s.fet.gain
    fetCompressorAutoAttack = s.fet.autoAttack
    fetCompressorAttack = s.fet.attack
    fetCompressorMaxAttack = s.fet.maxAttack
    fetCompressorAutoRelease = s.fet.autoRelease
    fetCompressorRelease = s.fet.release
    fetCompressorMaxRelease = s.fet.maxRelease
    fetCompressorCrest = s.fet.crest
    fetCompressorAdapt = s.fet.adapt
    fetCompressorNoClip = s.fet.noClip
    stereoImgEnabled = s.stereoImg.enabled
    stereoImgLowWidth = s.stereoImg.lowWidth
    stereoImgMidWidth = s.stereoImg.midWidth
    stereoImgHighWidth = s.stereoImg.highWidth
    stereoImgLowCrossover = s.stereoImg.lowCrossover
    stereoImgHighCrossover = s.stereoImg.highCrossover
    lufsEnabled = s.lufs.enabled
    lufsTarget = s.lufs.target
    lufsMaxGain = s.lufs.maxGain
    lufsSpeed = s.lufs.speed
    psychoBassEnabled = s.psychoBass.enabled
    psychoBassCutoff = s.psychoBass.cutoff
    psychoBassIntensity = s.psychoBass.intensity
    psychoBassHarmonicOrder = s.psychoBass.harmonicOrder
    psychoBassOriginalLevel = s.psychoBass.originalLevel
    dynEqEnabled = s.dynEq.enabled
    dynEqBandCount = s.dynEq.bandCount
    dynEqFreqs = s.dynEq.freqs
    dynEqQs = s.dynEq.qs
    dynEqGains = s.dynEq.gains
    dynEqThresholds = s.dynEq.thresholds
    dynEqAttacks = s.dynEq.attacks
    dynEqReleases = s.dynEq.releases
    dynEqFilterTypes = s.dynEq.filterTypes
    mbcEnabled = s.mbc.enabled
    mbcCrossovers = s.mbc.crossovers
    mbcThresholds = s.mbc.thresholds
    mbcRatios = s.mbc.ratios
    mbcGains = s.mbc.gains
    mbcKnees = s.mbc.knees
    mbcAttacks = s.mbc.attacks
    mbcReleases = s.mbc.releases
    mbcAutoGains = s.mbc.autoGains
    mbcAutoAttacks = s.mbc.autoAttacks
    mbcAutoReleases = s.mbc.autoReleases
    mbcAutoKnees = s.mbc.autoKnees
    mbcKneeMultis = s.mbc.kneeMultis
    mbcMaxAttacks = s.mbc.maxAttacks
    mbcMaxReleases = s.mbc.maxReleases
    mbcCrests = s.mbc.crests
    mbcAdapts = s.mbc.adapts
    mbcBandEnables = s.mbc.bandEnables
    mbcNoClips = s.mbc.noClips
    suppressDispatch = false
  }

  private func dispatchFullModeState() {
    logger.info("Dispatching full state: mode=\(isActiveSpk ? "speaker" : "headphone")")
    send(Param.SET_RESET_STATUS, 1)

    send(p(Param.HP_CONVOLVER_ENABLE, Param.SPK_CONVOLVER_ENABLE), convolutionEnabled && !convolutionKernelPath.isEmpty ? 1 : 0)
    send(p(Param.HP_CONVOLVER_CROSS_CHANNEL, Param.SPK_CONVOLVER_CROSS_CHANNEL), convolutionCrossChannel)

    send(p(Param.HP_DDC_ENABLE, Param.SPK_DDC_ENABLE), ddcEnabled && !ddcFilePath.isEmpty ? 1 : 0)

    send(p(Param.HP_EQ_ENABLE, Param.SPK_EQ_ENABLE), equalizerEnabled ? 1 : 0)
    send(p(Param.HP_EQ_BAND_COUNT, Param.SPK_EQ_BAND_COUNT), equalizerBandCount)
    for i in 0 ..< equalizerBands.count {
      send(p(Param.HP_EQ_BAND_LEVEL, Param.SPK_EQ_BAND_LEVEL), i, Int(equalizerBands[i] * 100))
    }

    send(p(Param.HP_REVERB_ENABLE, Param.SPK_REVERB_ENABLE), reverberationEnabled ? 1 : 0)
    send(p(Param.HP_REVERB_ROOM_SIZE, Param.SPK_REVERB_ROOM_SIZE), reverberationRoomSize * 10)
    send(p(Param.HP_REVERB_ROOM_WIDTH, Param.SPK_REVERB_ROOM_WIDTH), reverberationRoomWidth * 10)
    send(p(Param.HP_REVERB_ROOM_DAMPENING, Param.SPK_REVERB_ROOM_DAMPENING), reverberationRoomDampening)
    send(p(Param.HP_REVERB_ROOM_WET_SIGNAL, Param.SPK_REVERB_ROOM_WET_SIGNAL), reverberationWetSignal)
    send(p(Param.HP_REVERB_ROOM_DRY_SIGNAL, Param.SPK_REVERB_ROOM_DRY_SIGNAL), reverberationDrySignal)

    send(p(Param.HP_AGC_ENABLE, Param.SPK_AGC_ENABLE), playbackGainEnabled ? 1 : 0)
    send(p(Param.HP_AGC_RATIO, Param.SPK_AGC_RATIO), playbackGainStrength)
    send(p(Param.HP_AGC_VOLUME, Param.SPK_AGC_VOLUME), playbackGainOutputThreshold)
    send(p(Param.HP_AGC_MAX_SCALER, Param.SPK_AGC_MAX_SCALER), playbackGainMaxGain)

    send(p(Param.HP_DYNAMIC_SYSTEM_ENABLE, Param.SPK_DYNAMIC_SYSTEM_ENABLE), dynamicSystemEnabled ? 1 : 0)
    send(p(Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS), dsXLow, dsXHigh)
    send(p(Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS), dsYLow, dsYHigh)
    send(p(Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN, Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN), dsSideGainLow, dsSideGainHigh)
    send(p(Param.HP_DYNAMIC_SYSTEM_STRENGTH, Param.SPK_DYNAMIC_SYSTEM_STRENGTH), Self.dynamicSystemStrengthToRaw(dynamicSystemStrength))

    send(p(Param.HP_BASS_ENABLE, Param.SPK_BASS_ENABLE), viperBassEnabled ? 1 : 0)
    send(p(Param.HP_BASS_MODE, Param.SPK_BASS_MODE), viperBassMode)
    send(p(Param.HP_BASS_FREQUENCY, Param.SPK_BASS_FREQUENCY), Self.bassFrequencyToRaw(viperBassFrequency))
    send(p(Param.HP_BASS_GAIN, Param.SPK_BASS_GAIN), viperBassGain)
    send(p(Param.HP_BASS_ANTI_POP, Param.SPK_BASS_ANTI_POP), viperBassAntiPop ? 1 : 0)

    send(p(Param.HP_BASS_MONO_ENABLE, Param.SPK_BASS_MONO_ENABLE), viperBassMonoEnabled ? 1 : 0)
    send(p(Param.HP_BASS_MONO_MODE, Param.SPK_BASS_MONO_MODE), viperBassMonoMode)
    send(p(Param.HP_BASS_MONO_FREQUENCY, Param.SPK_BASS_MONO_FREQUENCY), Self.bassFrequencyToRaw(viperBassMonoFrequency))
    send(p(Param.HP_BASS_MONO_GAIN, Param.SPK_BASS_MONO_GAIN), viperBassMonoGain)
    send(p(Param.HP_BASS_MONO_ANTI_POP, Param.SPK_BASS_MONO_ANTI_POP), viperBassMonoAntiPop ? 1 : 0)

    send(p(Param.HP_CLARITY_ENABLE, Param.SPK_CLARITY_ENABLE), viperClarityEnabled ? 1 : 0)
    send(p(Param.HP_CLARITY_MODE, Param.SPK_CLARITY_MODE), viperClarityMode)
    send(p(Param.HP_CLARITY_GAIN, Param.SPK_CLARITY_GAIN), viperClarityGain)

    send(p(Param.HP_HEADPHONE_SURROUND_ENABLE, Param.SPK_HEADPHONE_SURROUND_ENABLE), vheEnabled ? 1 : 0)
    send(p(Param.HP_HEADPHONE_SURROUND_STRENGTH, Param.SPK_HEADPHONE_SURROUND_STRENGTH), vheQuality)

    send(p(Param.HP_SPECTRUM_EXTENSION_ENABLE, Param.SPK_SPECTRUM_EXTENSION_ENABLE), spectrumExtensionEnabled ? 1 : 0)
    send(p(Param.HP_SPECTRUM_EXTENSION_BARK, Param.SPK_SPECTRUM_EXTENSION_BARK), spectrumExtensionBark)
    send(p(Param.HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT, Param.SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT), Self.vseExciterToRaw(spectrumExtensionBarkReconstruct))

    send(p(Param.HP_FIELD_SURROUND_ENABLE, Param.SPK_FIELD_SURROUND_ENABLE), fieldSurroundEnabled ? 1 : 0)
    send(p(Param.HP_FIELD_SURROUND_WIDENING, Param.SPK_FIELD_SURROUND_WIDENING), Self.fieldSurroundWideningToRaw(fieldSurroundWidening))
    send(p(Param.HP_FIELD_SURROUND_MID_IMAGE, Param.SPK_FIELD_SURROUND_MID_IMAGE), Self.fieldSurroundMidImageToRaw(fieldSurroundMidImage))
    send(p(Param.HP_FIELD_SURROUND_DEPTH, Param.SPK_FIELD_SURROUND_DEPTH), Self.fieldSurroundDepthToRaw(fieldSurroundDepth))

    send(p(Param.HP_DIFF_SURROUND_ENABLE, Param.SPK_DIFF_SURROUND_ENABLE), diffSurroundEnabled ? 1 : 0)
    send(p(Param.HP_DIFF_SURROUND_DELAY, Param.SPK_DIFF_SURROUND_DELAY), Self.diffSurroundDelayToRaw(diffSurroundDelay))
    send(p(Param.HP_DIFF_SURROUND_REVERSE, Param.SPK_DIFF_SURROUND_REVERSE), diffSurroundReverse ? 1 : 0)
    send(p(Param.HP_DIFF_SURROUND_WET_DRY_MIX, Param.SPK_DIFF_SURROUND_WET_DRY_MIX), diffSurroundWetDryMix)
    send(p(Param.HP_DIFF_SURROUND_LP_CUTOFF, Param.SPK_DIFF_SURROUND_LP_CUTOFF), diffSurroundLpCutoff)

    send(p(Param.HP_CURE_ENABLE, Param.SPK_CURE_ENABLE), cureEnabled ? 1 : 0)
    send(p(Param.HP_CURE_STRENGTH, Param.SPK_CURE_STRENGTH), cureCrossfeedStrength)

    send(p(Param.HP_TUBE_SIMULATOR_ENABLE, Param.SPK_TUBE_SIMULATOR_ENABLE), tubeSimulatorEnabled ? 1 : 0)

    send(p(Param.HP_ANALOGX_ENABLE, Param.SPK_ANALOGX_ENABLE), analogXEnabled ? 1 : 0)
    send(p(Param.HP_ANALOGX_MODE, Param.SPK_ANALOGX_MODE), analogXMode)

    send(p(Param.HP_OUTPUT_VOLUME, Param.SPK_OUTPUT_VOLUME), outputVolume)
    send(p(Param.HP_CHANNEL_PAN, Param.SPK_CHANNEL_PAN), channelPan)
    send(p(Param.HP_LIMITER, Param.SPK_LIMITER), limiter)

    send(p(Param.HP_FET_COMPRESSOR_ENABLE, Param.SPK_FET_COMPRESSOR_ENABLE), fetCompressorEnabled ? 100 : 0)
    send(p(Param.HP_FET_COMPRESSOR_THRESHOLD, Param.SPK_FET_COMPRESSOR_THRESHOLD), Self.fetThresholdToRaw(fetCompressorThreshold))
    send(p(Param.HP_FET_COMPRESSOR_RATIO, Param.SPK_FET_COMPRESSOR_RATIO), fetCompressorRatio)
    send(p(Param.HP_FET_COMPRESSOR_KNEE, Param.SPK_FET_COMPRESSOR_KNEE), Self.fetKneeToRaw(fetCompressorKnee))
    send(p(Param.HP_FET_COMPRESSOR_AUTO_KNEE, Param.SPK_FET_COMPRESSOR_AUTO_KNEE), fetCompressorAutoKnee ? 100 : 0)
    send(p(Param.HP_FET_COMPRESSOR_GAIN, Param.SPK_FET_COMPRESSOR_GAIN), Self.fetGainToRaw(fetCompressorGain))
    send(p(Param.HP_FET_COMPRESSOR_AUTO_GAIN, Param.SPK_FET_COMPRESSOR_AUTO_GAIN), fetCompressorAutoGain ? 100 : 0)
    send(p(Param.HP_FET_COMPRESSOR_ATTACK, Param.SPK_FET_COMPRESSOR_ATTACK), Self.fetAttackMsToRaw(fetCompressorAttack))
    send(p(Param.HP_FET_COMPRESSOR_AUTO_ATTACK, Param.SPK_FET_COMPRESSOR_AUTO_ATTACK), fetCompressorAutoAttack ? 100 : 0)
    send(p(Param.HP_FET_COMPRESSOR_RELEASE, Param.SPK_FET_COMPRESSOR_RELEASE), Self.fetReleaseMsToRaw(fetCompressorRelease))
    send(p(Param.HP_FET_COMPRESSOR_AUTO_RELEASE, Param.SPK_FET_COMPRESSOR_AUTO_RELEASE), fetCompressorAutoRelease ? 100 : 0)
    send(p(Param.HP_FET_COMPRESSOR_KNEE_MULTI, Param.SPK_FET_COMPRESSOR_KNEE_MULTI), fetCompressorKneeMulti)
    send(p(Param.HP_FET_COMPRESSOR_MAX_ATTACK, Param.SPK_FET_COMPRESSOR_MAX_ATTACK), Self.fetAttackMsToRaw(fetCompressorMaxAttack))
    send(p(Param.HP_FET_COMPRESSOR_MAX_RELEASE, Param.SPK_FET_COMPRESSOR_MAX_RELEASE), Self.fetReleaseMsToRaw(fetCompressorMaxRelease))
    send(p(Param.HP_FET_COMPRESSOR_CREST, Param.SPK_FET_COMPRESSOR_CREST), Self.fetReleaseMsToRaw(fetCompressorCrest))
    send(p(Param.HP_FET_COMPRESSOR_ADAPT, Param.SPK_FET_COMPRESSOR_ADAPT), fetCompressorAdapt)
    send(p(Param.HP_FET_COMPRESSOR_NO_CLIP, Param.SPK_FET_COMPRESSOR_NO_CLIP), fetCompressorNoClip ? 100 : 0)

    send(p(Param.HP_MULTIBAND_COMP_ENABLE, Param.SPK_MULTIBAND_COMP_ENABLE), mbcEnabled ? 1 : 0)
    for i in 0 ..< 4 {
      send(p(Param.HP_MULTIBAND_COMP_CROSSOVER_FREQ, Param.SPK_MULTIBAND_COMP_CROSSOVER_FREQ), i, mbcCrossovers[safe: i] ?? 500)
    }
    for i in 0 ..< 5 {
      send(p(Param.HP_MULTIBAND_COMP_BAND_THRESHOLD, Param.SPK_MULTIBAND_COMP_BAND_THRESHOLD), i, Self.fetThresholdToRaw(mbcThresholds[safe: i] ?? -18))
      send(p(Param.HP_MULTIBAND_COMP_BAND_RATIO, Param.SPK_MULTIBAND_COMP_BAND_RATIO), i, mbcRatios[safe: i] ?? 50)
      send(p(Param.HP_MULTIBAND_COMP_BAND_KNEE, Param.SPK_MULTIBAND_COMP_BAND_KNEE), i, Self.fetKneeToRaw(mbcKnees[safe: i] ?? 0))
      send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_KNEE, Param.SPK_MULTIBAND_COMP_BAND_AUTO_KNEE), i, (mbcAutoKnees[safe: i] ?? true) ? 100 : 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_GAIN, Param.SPK_MULTIBAND_COMP_BAND_GAIN), i, Self.fetGainToRaw(mbcGains[safe: i] ?? 24))
      send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_GAIN, Param.SPK_MULTIBAND_COMP_BAND_AUTO_GAIN), i, (mbcAutoGains[safe: i] ?? true) ? 100 : 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_ATTACK), i, Self.fetAttackMsToRaw(mbcAttacks[safe: i] ?? 1))
      send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_AUTO_ATTACK), i, (mbcAutoAttacks[safe: i] ?? true) ? 100 : 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_RELEASE), i, Self.fetReleaseMsToRaw(mbcReleases[safe: i] ?? 100))
      send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_AUTO_RELEASE), i, (mbcAutoReleases[safe: i] ?? true) ? 100 : 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_KNEE_MULTI, Param.SPK_MULTIBAND_COMP_BAND_KNEE_MULTI), i, mbcKneeMultis[safe: i] ?? 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_MAX_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_MAX_ATTACK), i, Self.fetAttackMsToRaw(mbcMaxAttacks[safe: i] ?? 44))
      send(p(Param.HP_MULTIBAND_COMP_BAND_MAX_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_MAX_RELEASE), i, Self.fetReleaseMsToRaw(mbcMaxReleases[safe: i] ?? 200))
      send(p(Param.HP_MULTIBAND_COMP_BAND_CREST, Param.SPK_MULTIBAND_COMP_BAND_CREST), i, Self.fetReleaseMsToRaw(mbcCrests[safe: i] ?? 100))
      send(p(Param.HP_MULTIBAND_COMP_BAND_ADAPT, Param.SPK_MULTIBAND_COMP_BAND_ADAPT), i, mbcAdapts[safe: i] ?? 50)
      send(p(Param.HP_MULTIBAND_COMP_BAND_NO_CLIP, Param.SPK_MULTIBAND_COMP_BAND_NO_CLIP), i, (mbcNoClips[safe: i] ?? true) ? 100 : 0)
      send(p(Param.HP_MULTIBAND_COMP_BAND_ENABLE, Param.SPK_MULTIBAND_COMP_BAND_ENABLE), i, (mbcBandEnables[safe: i] ?? true) ? 100 : 0)
    }
    send(p(Param.HP_MULTIBAND_COMP_BAND_COUNT, Param.SPK_MULTIBAND_COMP_BAND_COUNT), 5)

    send(p(Param.HP_STEREO_IMAGER_ENABLE, Param.SPK_STEREO_IMAGER_ENABLE), stereoImgEnabled ? 1 : 0)
    send(p(Param.HP_STEREO_IMAGER_LOW_WIDTH, Param.SPK_STEREO_IMAGER_LOW_WIDTH), stereoImgLowWidth)
    send(p(Param.HP_STEREO_IMAGER_MID_WIDTH, Param.SPK_STEREO_IMAGER_MID_WIDTH), stereoImgMidWidth)
    send(p(Param.HP_STEREO_IMAGER_HIGH_WIDTH, Param.SPK_STEREO_IMAGER_HIGH_WIDTH), stereoImgHighWidth)
    send(p(Param.HP_STEREO_IMAGER_LOW_CROSSOVER, Param.SPK_STEREO_IMAGER_LOW_CROSSOVER), stereoImgLowCrossover)
    send(p(Param.HP_STEREO_IMAGER_HIGH_CROSSOVER, Param.SPK_STEREO_IMAGER_HIGH_CROSSOVER), stereoImgHighCrossover)

    send(p(Param.HP_DYNAMIC_EQ_ENABLE, Param.SPK_DYNAMIC_EQ_ENABLE), dynEqEnabled ? 1 : 0)
    for i in 0 ..< dynEqBandCount {
      send(p(Param.HP_DYNAMIC_EQ_BAND_FREQ, Param.SPK_DYNAMIC_EQ_BAND_FREQ), i, dynEqFreqs[safe: i] ?? 1000)
      send(p(Param.HP_DYNAMIC_EQ_BAND_Q, Param.SPK_DYNAMIC_EQ_BAND_Q), i, dynEqQs[safe: i] ?? 150)
      send(p(Param.HP_DYNAMIC_EQ_BAND_GAIN, Param.SPK_DYNAMIC_EQ_BAND_GAIN), i, dynEqGains[safe: i] ?? 0)
      send(p(Param.HP_DYNAMIC_EQ_BAND_THRESHOLD, Param.SPK_DYNAMIC_EQ_BAND_THRESHOLD), i, dynEqThresholds[safe: i] ?? -250)
      send(p(Param.HP_DYNAMIC_EQ_BAND_ATTACK, Param.SPK_DYNAMIC_EQ_BAND_ATTACK), i, dynEqAttacks[safe: i] ?? 10)
      send(p(Param.HP_DYNAMIC_EQ_BAND_RELEASE, Param.SPK_DYNAMIC_EQ_BAND_RELEASE), i, dynEqReleases[safe: i] ?? 100)
      send(p(Param.HP_DYNAMIC_EQ_BAND_FILTER_TYPE, Param.SPK_DYNAMIC_EQ_BAND_FILTER_TYPE), i, dynEqFilterTypes[safe: i] ?? 0)
    }
    send(p(Param.HP_DYNAMIC_EQ_BAND_COUNT, Param.SPK_DYNAMIC_EQ_BAND_COUNT), dynEqBandCount)

    send(p(Param.HP_LUFS_ENABLE, Param.SPK_LUFS_ENABLE), lufsEnabled ? 1 : 0)
    send(p(Param.HP_LUFS_TARGET, Param.SPK_LUFS_TARGET), lufsTarget)
    send(p(Param.HP_LUFS_MAX_GAIN, Param.SPK_LUFS_MAX_GAIN), lufsMaxGain)
    send(p(Param.HP_LUFS_SPEED, Param.SPK_LUFS_SPEED), lufsSpeed)

    send(p(Param.HP_PSYCHO_BASS_ENABLE, Param.SPK_PSYCHO_BASS_ENABLE), psychoBassEnabled ? 1 : 0)
    send(p(Param.HP_PSYCHO_BASS_CUTOFF, Param.SPK_PSYCHO_BASS_CUTOFF), psychoBassCutoff)
    send(p(Param.HP_PSYCHO_BASS_INTENSITY, Param.SPK_PSYCHO_BASS_INTENSITY), psychoBassIntensity)
    send(p(Param.HP_PSYCHO_BASS_HARMONIC_ORDER, Param.SPK_PSYCHO_BASS_HARMONIC_ORDER), psychoBassHarmonicOrder)
    send(p(Param.HP_PSYCHO_BASS_ORIGINAL_LEVEL, Param.SPK_PSYCHO_BASS_ORIGINAL_LEVEL), psychoBassOriginalLevel)

    send(Param.SPK_SPEAKER_CORRECTION_ENABLE, speakerCorrectionEnabled ? 1 : 0)
  }

  func handleDeviceChanged(_ device: AudioOutputDetector.DeviceInfo) {
    let newType: FXType = device.type == .headphone ? .headphone : .speaker
    let oldUID = currentDeviceUID
    let oldType = activeDeviceType
    let typeChanged = newType != oldType
    let uidChanged = device.uid != oldUID && !device.uid.isEmpty

    guard typeChanged || uidChanged else { return }

    logger.info(
      "Device transition: \(oldType.rawValue)/\(oldUID) -> \(newType.rawValue)/\(device.uid)"
    )

    saveToMode(isSpk: oldType == .speaker)
    if !oldUID.isEmpty {
      writeDeviceProfile(uid: oldUID, isHeadphone: oldType == .headphone)
    }

    currentDeviceUID = device.uid
    currentDeviceName = device.name
    if typeChanged {
      activeDeviceType = newType
      suppressFxTypeSink = true
      fxType = newType
      suppressFxTypeSink = false
    }

    let modeState =
      readDeviceProfile(uid: device.uid, isHeadphone: device.type == .headphone)
        ?? (newType == .speaker ? speakerState : headphoneState)
    if newType == .speaker {
      speakerState = modeState
    } else {
      headphoneState = modeState
    }
    loadModeToActive(modeState)
    reloadActiveFiles()
    dispatchFullModeState()

    saveSettings()
  }

  private func writeDeviceProfile(uid: String, isHeadphone: Bool) {
    guard !uid.isEmpty else { return }
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    let source = isHeadphone ? headphoneState : speakerState
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(source) else { return }
    var wrapper: [String: Any] = [
      "deviceUID": uid,
      "deviceName": currentDeviceUID == uid ? currentDeviceName : uid,
      "isHeadphone": isHeadphone,
      "lastConnected": Int(Date().timeIntervalSince1970 * 1000),
    ]
    if let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      wrapper["settings"] = settings
    }
    if let jsonData = try? JSONSerialization.data(withJSONObject: wrapper, options: .prettyPrinted) {
      try? jsonData.write(to: url)
    }
  }

  private func readDeviceProfile(uid: String, isHeadphone _: Bool) -> ModeState? {
    guard !uid.isEmpty else { return nil }
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard FileManager.default.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url),
          let wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let settings = wrapper["settings"] as? [String: Any],
          let settingsData = try? JSONSerialization.data(withJSONObject: settings),
          let modeState = try? JSONDecoder().decode(ModeState.self, from: settingsData)
    else { return nil }
    return modeState
  }

  func saveCurrentDeviceSettings() {
    guard !currentDeviceUID.isEmpty else { return }
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(currentDeviceUID)).json", type: .deviceProfile
    )

    var existingIsHp: Bool? = nil
    if let existingData = try? Data(contentsOf: url),
       let existingDict = try? JSONSerialization.jsonObject(with: existingData) as? [String: Any]
    {
      existingIsHp = existingDict["isHeadphone"] as? Bool
    }
    let isHp = existingIsHp ?? (activeDeviceType == .headphone)

    saveToMode(isSpk: !isHp)
    let source = isHp ? headphoneState : speakerState
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(source) else { return }
    var wrapper: [String: Any] = [
      "deviceUID": currentDeviceUID,
      "deviceName": currentDeviceName,
      "isHeadphone": isHp,
      "lastConnected": Int(Date().timeIntervalSince1970 * 1000),
    ]
    if let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      wrapper["settings"] = settings
    }
    if let jsonData = try? JSONSerialization.data(withJSONObject: wrapper, options: .prettyPrinted) {
      try? jsonData.write(to: url)
    }
  }

  private func safeFileName(_ uid: String) -> String {
    uid.replacingOccurrences(of: ":", with: "_")
  }

  func loadDeviceSettings(_ uid: String, isHeadphone: Bool) {
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard FileManager.default.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url),
          var wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let settings = wrapper["settings"] as? [String: Any],
          let settingsData = try? JSONSerialization.data(withJSONObject: settings)
    else {
      ensureDeviceEntry(uid, isHeadphone: isHeadphone)
      return
    }

    if (wrapper["isHeadphone"] as? Bool) != isHeadphone {
      wrapper["isHeadphone"] = isHeadphone
      if let fixed = try? JSONSerialization.data(withJSONObject: wrapper, options: .prettyPrinted) {
        try? fixed.write(to: url)
      }
    }

    guard let modeState = try? JSONDecoder().decode(ModeState.self, from: settingsData) else {
      return
    }
    if isHeadphone {
      headphoneState = modeState
    } else {
      speakerState = modeState
    }
    loadModeToActive(modeState)
    dispatchFullModeState()
    saveSettings()
  }

  func ensureDeviceEntry(_ uid: String, isHeadphone _: Bool) {
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard !FileManager.default.fileExists(atPath: url.path) else { return }
    saveCurrentDeviceSettings()
  }

  var deviceProfileList: [[String: Any]] {
    let dir = ProfileFileManager.shared.directoryPath(for: .deviceProfile)
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
    var result: [[String: Any]] = []
    for file in files where file.hasSuffix(".json") {
      let path = "\(dir)/\(file)"
      guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else { continue }
      result.append(dict)
    }
    result.sort { ($0["lastConnected"] as? Int ?? 0) > ($1["lastConnected"] as? Int ?? 0) }
    return result
  }

  func renameDevice(_ uid: String, newName: String) {
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard let data = try? Data(contentsOf: url),
          var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return }
    dict["deviceName"] = newName
    if let newData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
      try? newData.write(to: url)
    }
    if uid == currentDeviceUID {
      currentDeviceName = newName
    }
  }

  func deleteDeviceProfile(_ uid: String) {
    let fileName = "\(safeFileName(uid)).json"
    ProfileFileManager.shared.deleteFile(name: fileName, type: .deviceProfile)
  }

  func loadDevicePreset(_ uid: String) {
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard let data = try? Data(contentsOf: url),
          let wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let isHp = wrapper["isHeadphone"] as? Bool,
          let settings = wrapper["settings"] as? [String: Any],
          let settingsData = try? JSONSerialization.data(withJSONObject: settings),
          let modeState = try? JSONDecoder().decode(ModeState.self, from: settingsData)
    else { return }
    if isHp {
      headphoneState = modeState
      if activeDeviceType == .headphone { loadModeToActive(modeState); dispatchFullModeState() }
    } else {
      speakerState = modeState
      if activeDeviceType == .speaker { loadModeToActive(modeState); dispatchFullModeState() }
    }
    saveSettings()
  }

  func saveDevicePreset(_ uid: String) {
    let url = ProfileFileManager.shared.fileURL(
      name: "\(safeFileName(uid)).json", type: .deviceProfile
    )
    guard let data = try? Data(contentsOf: url),
          var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return }
    let isHp = dict["isHeadphone"] as? Bool ?? true
    saveToMode(isSpk: !isHp)
    let source = isHp ? headphoneState : speakerState
    if let encoded = try? JSONEncoder().encode(source),
       let settings = try? JSONSerialization.jsonObject(with: encoded)
    {
      dict["settings"] = settings
      if let newData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
        try? newData.write(to: url)
      }
    }
  }

  private func bindInt(_ pub: Published<Int>.Publisher, _ hp: Int, _ spk: Int) {
    pub.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(hp, spk), v)
    }.store(in: &cancellables)
  }

  private func bindBool(_ pub: Published<Bool>.Publisher, _ hp: Int, _ spk: Int, trueValue: Int = 1) {
    pub.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(hp, spk), v ? trueValue : 0)
    }.store(in: &cancellables)
  }

  private func bindInt(_ pub: Published<Int>.Publisher, _ hp: Int, _ spk: Int, transform: @escaping (Int) -> Int) {
    pub.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(hp, spk), transform(v))
    }.store(in: &cancellables)
  }

  private func setupBindings() {
    $isEnabled.dropFirst().sink { on in
      AudioEngine.shared.processingEnabled = on
      logger.info("Processing \(on ? "enabled" : "disabled")")
    }.store(in: &cancellables)

    $fxType.dropFirst().sink { [weak self] newType in
      guard let self, !self.suppressFxTypeSink else { return }
      logger.info("FX tab switched to \(newType == .speaker ? "speaker" : "headphone")")
      let previousWasSpk = newType == .speaker ? false : true
      self.saveToMode(isSpk: previousWasSpk)
      let source = newType == .speaker ? self.speakerState : self.headphoneState
      self.loadModeToActive(source)
      self.reloadActiveFiles()
    }.store(in: &cancellables)

    bindInt($outputVolume, Param.HP_OUTPUT_VOLUME, Param.SPK_OUTPUT_VOLUME)
    bindInt($channelPan, Param.HP_CHANNEL_PAN, Param.SPK_CHANNEL_PAN)
    bindInt($limiter, Param.HP_LIMITER, Param.SPK_LIMITER)

    $convolutionEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let effective = on && !self.convolutionKernelPath.isEmpty ? 1 : 0
      self.send(self.p(Param.HP_CONVOLVER_ENABLE, Param.SPK_CONVOLVER_ENABLE), effective)
    }.store(in: &cancellables)
    bindInt($convolutionCrossChannel, Param.HP_CONVOLVER_CROSS_CHANNEL, Param.SPK_CONVOLVER_CROSS_CHANNEL)

    $ddcEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      let effective = on && !self.ddcFilePath.isEmpty ? 1 : 0
      self.send(self.p(Param.HP_DDC_ENABLE, Param.SPK_DDC_ENABLE), effective)
    }.store(in: &cancellables)

    bindBool($equalizerEnabled, Param.HP_EQ_ENABLE, Param.SPK_EQ_ENABLE)

    bindBool($reverberationEnabled, Param.HP_REVERB_ENABLE, Param.SPK_REVERB_ENABLE)
    bindInt($reverberationRoomSize, Param.HP_REVERB_ROOM_SIZE, Param.SPK_REVERB_ROOM_SIZE) { $0 * 10 }
    bindInt($reverberationRoomWidth, Param.HP_REVERB_ROOM_WIDTH, Param.SPK_REVERB_ROOM_WIDTH) { $0 * 10 }
    bindInt($reverberationRoomDampening, Param.HP_REVERB_ROOM_DAMPENING, Param.SPK_REVERB_ROOM_DAMPENING)
    bindInt($reverberationWetSignal, Param.HP_REVERB_ROOM_WET_SIGNAL, Param.SPK_REVERB_ROOM_WET_SIGNAL)
    bindInt($reverberationDrySignal, Param.HP_REVERB_ROOM_DRY_SIGNAL, Param.SPK_REVERB_ROOM_DRY_SIGNAL)

    bindBool($playbackGainEnabled, Param.HP_AGC_ENABLE, Param.SPK_AGC_ENABLE)
    bindInt($playbackGainStrength, Param.HP_AGC_RATIO, Param.SPK_AGC_RATIO)
    bindInt($playbackGainMaxGain, Param.HP_AGC_MAX_SCALER, Param.SPK_AGC_MAX_SCALER)
    bindInt($playbackGainOutputThreshold, Param.HP_AGC_VOLUME, Param.SPK_AGC_VOLUME)

    bindBool($dynamicSystemEnabled, Param.HP_DYNAMIC_SYSTEM_ENABLE, Param.SPK_DYNAMIC_SYSTEM_ENABLE)
    $dynamicSystemDevice.dropFirst().sink { [weak self] idx in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.applyDynamicSystemDevice(idx)
    }.store(in: &cancellables)
    bindInt($dynamicSystemStrength, Param.HP_DYNAMIC_SYSTEM_STRENGTH, Param.SPK_DYNAMIC_SYSTEM_STRENGTH) { Self.dynamicSystemStrengthToRaw($0) }
    $dsXLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS), v, self.dsXHigh)
    }.store(in: &cancellables)
    $dsXHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_X_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS), self.dsXLow, v)
    }.store(in: &cancellables)
    $dsYLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS), v, self.dsYHigh)
    }.store(in: &cancellables)
    $dsYHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS, Param.SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS), self.dsYLow, v)
    }.store(in: &cancellables)
    $dsSideGainLow.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN, Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN), v, self.dsSideGainHigh)
    }.store(in: &cancellables)
    $dsSideGainHigh.dropFirst().sink { [weak self] v in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(self.p(Param.HP_DYNAMIC_SYSTEM_SIDE_GAIN, Param.SPK_DYNAMIC_SYSTEM_SIDE_GAIN), self.dsSideGainLow, v)
    }.store(in: &cancellables)

    bindBool($viperBassEnabled, Param.HP_BASS_ENABLE, Param.SPK_BASS_ENABLE)
    bindInt($viperBassMode, Param.HP_BASS_MODE, Param.SPK_BASS_MODE)
    bindInt($viperBassFrequency, Param.HP_BASS_FREQUENCY, Param.SPK_BASS_FREQUENCY) { Self.bassFrequencyToRaw($0) }
    bindInt($viperBassGain, Param.HP_BASS_GAIN, Param.SPK_BASS_GAIN)
    bindBool($viperBassAntiPop, Param.HP_BASS_ANTI_POP, Param.SPK_BASS_ANTI_POP)
    bindBool($viperBassMonoEnabled, Param.HP_BASS_MONO_ENABLE, Param.SPK_BASS_MONO_ENABLE)
    bindInt($viperBassMonoMode, Param.HP_BASS_MONO_MODE, Param.SPK_BASS_MONO_MODE)
    bindInt($viperBassMonoFrequency, Param.HP_BASS_MONO_FREQUENCY, Param.SPK_BASS_MONO_FREQUENCY) { Self.bassFrequencyToRaw($0) }
    bindInt($viperBassMonoGain, Param.HP_BASS_MONO_GAIN, Param.SPK_BASS_MONO_GAIN)
    bindBool($viperBassMonoAntiPop, Param.HP_BASS_MONO_ANTI_POP, Param.SPK_BASS_MONO_ANTI_POP)

    bindBool($viperClarityEnabled, Param.HP_CLARITY_ENABLE, Param.SPK_CLARITY_ENABLE)
    bindInt($viperClarityMode, Param.HP_CLARITY_MODE, Param.SPK_CLARITY_MODE)
    bindInt($viperClarityGain, Param.HP_CLARITY_GAIN, Param.SPK_CLARITY_GAIN)

    bindBool($tubeSimulatorEnabled, Param.HP_TUBE_SIMULATOR_ENABLE, Param.SPK_TUBE_SIMULATOR_ENABLE)

    bindBool($analogXEnabled, Param.HP_ANALOGX_ENABLE, Param.SPK_ANALOGX_ENABLE)
    bindInt($analogXMode, Param.HP_ANALOGX_MODE, Param.SPK_ANALOGX_MODE)

    bindBool($fieldSurroundEnabled, Param.HP_FIELD_SURROUND_ENABLE, Param.SPK_FIELD_SURROUND_ENABLE)
    bindInt($fieldSurroundWidening, Param.HP_FIELD_SURROUND_WIDENING, Param.SPK_FIELD_SURROUND_WIDENING) { Self.fieldSurroundWideningToRaw($0) }
    bindInt($fieldSurroundMidImage, Param.HP_FIELD_SURROUND_MID_IMAGE, Param.SPK_FIELD_SURROUND_MID_IMAGE) { Self.fieldSurroundMidImageToRaw($0) }
    bindInt($fieldSurroundDepth, Param.HP_FIELD_SURROUND_DEPTH, Param.SPK_FIELD_SURROUND_DEPTH) { Self.fieldSurroundDepthToRaw($0) }

    bindBool($diffSurroundEnabled, Param.HP_DIFF_SURROUND_ENABLE, Param.SPK_DIFF_SURROUND_ENABLE)
    bindInt($diffSurroundDelay, Param.HP_DIFF_SURROUND_DELAY, Param.SPK_DIFF_SURROUND_DELAY) { Self.diffSurroundDelayToRaw($0) }
    bindBool($diffSurroundReverse, Param.HP_DIFF_SURROUND_REVERSE, Param.SPK_DIFF_SURROUND_REVERSE)
    bindInt($diffSurroundWetDryMix, Param.HP_DIFF_SURROUND_WET_DRY_MIX, Param.SPK_DIFF_SURROUND_WET_DRY_MIX)
    bindInt($diffSurroundLpCutoff, Param.HP_DIFF_SURROUND_LP_CUTOFF, Param.SPK_DIFF_SURROUND_LP_CUTOFF)

    bindBool($stereoImgEnabled, Param.HP_STEREO_IMAGER_ENABLE, Param.SPK_STEREO_IMAGER_ENABLE)
    bindInt($stereoImgLowWidth, Param.HP_STEREO_IMAGER_LOW_WIDTH, Param.SPK_STEREO_IMAGER_LOW_WIDTH)
    bindInt($stereoImgMidWidth, Param.HP_STEREO_IMAGER_MID_WIDTH, Param.SPK_STEREO_IMAGER_MID_WIDTH)
    bindInt($stereoImgHighWidth, Param.HP_STEREO_IMAGER_HIGH_WIDTH, Param.SPK_STEREO_IMAGER_HIGH_WIDTH)
    bindInt($stereoImgLowCrossover, Param.HP_STEREO_IMAGER_LOW_CROSSOVER, Param.SPK_STEREO_IMAGER_LOW_CROSSOVER)
    bindInt($stereoImgHighCrossover, Param.HP_STEREO_IMAGER_HIGH_CROSSOVER, Param.SPK_STEREO_IMAGER_HIGH_CROSSOVER)

    bindBool($cureEnabled, Param.HP_CURE_ENABLE, Param.SPK_CURE_ENABLE)
    bindInt($cureCrossfeedStrength, Param.HP_CURE_STRENGTH, Param.SPK_CURE_STRENGTH)

    bindBool($vheEnabled, Param.HP_HEADPHONE_SURROUND_ENABLE, Param.SPK_HEADPHONE_SURROUND_ENABLE)
    bindInt($vheQuality, Param.HP_HEADPHONE_SURROUND_STRENGTH, Param.SPK_HEADPHONE_SURROUND_STRENGTH)

    bindBool($spectrumExtensionEnabled, Param.HP_SPECTRUM_EXTENSION_ENABLE, Param.SPK_SPECTRUM_EXTENSION_ENABLE)
    bindInt($spectrumExtensionBark, Param.HP_SPECTRUM_EXTENSION_BARK, Param.SPK_SPECTRUM_EXTENSION_BARK)
    bindInt($spectrumExtensionBarkReconstruct, Param.HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT, Param.SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT) { Self.vseExciterToRaw($0) }

    bindBool($fetCompressorEnabled, Param.HP_FET_COMPRESSOR_ENABLE, Param.SPK_FET_COMPRESSOR_ENABLE, trueValue: 100)
    bindInt($fetCompressorThreshold, Param.HP_FET_COMPRESSOR_THRESHOLD, Param.SPK_FET_COMPRESSOR_THRESHOLD) { Self.fetThresholdToRaw($0) }
    bindInt($fetCompressorRatio, Param.HP_FET_COMPRESSOR_RATIO, Param.SPK_FET_COMPRESSOR_RATIO)
    bindBool($fetCompressorAutoKnee, Param.HP_FET_COMPRESSOR_AUTO_KNEE, Param.SPK_FET_COMPRESSOR_AUTO_KNEE, trueValue: 100)
    bindInt($fetCompressorKnee, Param.HP_FET_COMPRESSOR_KNEE, Param.SPK_FET_COMPRESSOR_KNEE) { Self.fetKneeToRaw($0) }
    bindInt($fetCompressorKneeMulti, Param.HP_FET_COMPRESSOR_KNEE_MULTI, Param.SPK_FET_COMPRESSOR_KNEE_MULTI)
    bindBool($fetCompressorAutoGain, Param.HP_FET_COMPRESSOR_AUTO_GAIN, Param.SPK_FET_COMPRESSOR_AUTO_GAIN, trueValue: 100)
    bindInt($fetCompressorGain, Param.HP_FET_COMPRESSOR_GAIN, Param.SPK_FET_COMPRESSOR_GAIN) { Self.fetGainToRaw($0) }
    bindBool($fetCompressorAutoAttack, Param.HP_FET_COMPRESSOR_AUTO_ATTACK, Param.SPK_FET_COMPRESSOR_AUTO_ATTACK, trueValue: 100)
    bindInt($fetCompressorAttack, Param.HP_FET_COMPRESSOR_ATTACK, Param.SPK_FET_COMPRESSOR_ATTACK) { Self.fetAttackMsToRaw($0) }
    bindInt($fetCompressorMaxAttack, Param.HP_FET_COMPRESSOR_MAX_ATTACK, Param.SPK_FET_COMPRESSOR_MAX_ATTACK) { Self.fetAttackMsToRaw($0) }
    bindBool($fetCompressorAutoRelease, Param.HP_FET_COMPRESSOR_AUTO_RELEASE, Param.SPK_FET_COMPRESSOR_AUTO_RELEASE, trueValue: 100)
    bindInt($fetCompressorRelease, Param.HP_FET_COMPRESSOR_RELEASE, Param.SPK_FET_COMPRESSOR_RELEASE) { Self.fetReleaseMsToRaw($0) }
    bindInt($fetCompressorMaxRelease, Param.HP_FET_COMPRESSOR_MAX_RELEASE, Param.SPK_FET_COMPRESSOR_MAX_RELEASE) { Self.fetReleaseMsToRaw($0) }
    bindInt($fetCompressorCrest, Param.HP_FET_COMPRESSOR_CREST, Param.SPK_FET_COMPRESSOR_CREST) { Self.fetReleaseMsToRaw($0) }
    bindInt($fetCompressorAdapt, Param.HP_FET_COMPRESSOR_ADAPT, Param.SPK_FET_COMPRESSOR_ADAPT)
    bindBool($fetCompressorNoClip, Param.HP_FET_COMPRESSOR_NO_CLIP, Param.SPK_FET_COMPRESSOR_NO_CLIP, trueValue: 100)

    $speakerCorrectionEnabled.dropFirst().sink { [weak self] on in
      guard let self, !self.suppressDispatch, self.fxType == self.activeDeviceType else { return }
      self.send(Param.SPK_SPEAKER_CORRECTION_ENABLE, on ? 1 : 0)
    }.store(in: &cancellables)

    bindBool($lufsEnabled, Param.HP_LUFS_ENABLE, Param.SPK_LUFS_ENABLE)
    bindInt($lufsTarget, Param.HP_LUFS_TARGET, Param.SPK_LUFS_TARGET)
    bindInt($lufsMaxGain, Param.HP_LUFS_MAX_GAIN, Param.SPK_LUFS_MAX_GAIN)
    bindInt($lufsSpeed, Param.HP_LUFS_SPEED, Param.SPK_LUFS_SPEED)

    bindBool($psychoBassEnabled, Param.HP_PSYCHO_BASS_ENABLE, Param.SPK_PSYCHO_BASS_ENABLE)
    bindInt($psychoBassCutoff, Param.HP_PSYCHO_BASS_CUTOFF, Param.SPK_PSYCHO_BASS_CUTOFF)
    bindInt($psychoBassIntensity, Param.HP_PSYCHO_BASS_INTENSITY, Param.SPK_PSYCHO_BASS_INTENSITY)
    bindInt($psychoBassHarmonicOrder, Param.HP_PSYCHO_BASS_HARMONIC_ORDER, Param.SPK_PSYCHO_BASS_HARMONIC_ORDER)
    bindInt($psychoBassOriginalLevel, Param.HP_PSYCHO_BASS_ORIGINAL_LEVEL, Param.SPK_PSYCHO_BASS_ORIGINAL_LEVEL)

    bindBool($dynEqEnabled, Param.HP_DYNAMIC_EQ_ENABLE, Param.SPK_DYNAMIC_EQ_ENABLE)

    bindBool($mbcEnabled, Param.HP_MULTIBAND_COMP_ENABLE, Param.SPK_MULTIBAND_COMP_ENABLE)
  }

  func sendEQBand(index: Int, level: Float) {
    equalizerBandsMap[equalizerBandCount] = equalizerBands
    send(p(Param.HP_EQ_BAND_LEVEL, Param.SPK_EQ_BAND_LEVEL), index, Int(level * 100))
  }

  func setEQBandCount(_ count: Int) {
    let oldCount = equalizerBandCount
    logger.debug("EQ band count: \(oldCount) -> \(count)")
    equalizerBandsMap[oldCount] = equalizerBands

    equalizerBandCount = count
    let restored = equalizerBandsMap[count] ?? Array(repeating: 0.0, count: count)
    equalizerBands = restored

    send(p(Param.HP_EQ_BAND_COUNT, Param.SPK_EQ_BAND_COUNT), count)
    for i in 0 ..< count {
      send(p(Param.HP_EQ_BAND_LEVEL, Param.SPK_EQ_BAND_LEVEL), i, Int(restored[i] * 100))
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

  func dispatchDynEqBand(_ band: Int) {
    guard !suppressDispatch, fxType == activeDeviceType, band < dynEqBandCount else { return }
    send(p(Param.HP_DYNAMIC_EQ_BAND_FREQ, Param.SPK_DYNAMIC_EQ_BAND_FREQ), band, dynEqFreqs[safe: band] ?? 1000)
    send(p(Param.HP_DYNAMIC_EQ_BAND_Q, Param.SPK_DYNAMIC_EQ_BAND_Q), band, dynEqQs[safe: band] ?? 150)
    send(p(Param.HP_DYNAMIC_EQ_BAND_GAIN, Param.SPK_DYNAMIC_EQ_BAND_GAIN), band, dynEqGains[safe: band] ?? 0)
    send(p(Param.HP_DYNAMIC_EQ_BAND_THRESHOLD, Param.SPK_DYNAMIC_EQ_BAND_THRESHOLD), band, dynEqThresholds[safe: band] ?? -250)
    send(p(Param.HP_DYNAMIC_EQ_BAND_ATTACK, Param.SPK_DYNAMIC_EQ_BAND_ATTACK), band, dynEqAttacks[safe: band] ?? 10)
    send(p(Param.HP_DYNAMIC_EQ_BAND_RELEASE, Param.SPK_DYNAMIC_EQ_BAND_RELEASE), band, dynEqReleases[safe: band] ?? 100)
    send(p(Param.HP_DYNAMIC_EQ_BAND_FILTER_TYPE, Param.SPK_DYNAMIC_EQ_BAND_FILTER_TYPE), band, dynEqFilterTypes[safe: band] ?? 0)
  }

  func setDynEqBandCount(_ count: Int) {
    let clamped = min(max(count, 1), 8)
    let old = dynEqBandCount
    if clamped > old {
      let defaults: [(Int, Int, Int, Int, Int, Int, Int)] = [
        (60, 100, 0, -300, 10, 100, 0), (150, 100, 0, -300, 10, 100, 0),
        (400, 150, 0, -250, 10, 100, 0), (1000, 150, 0, -250, 10, 100, 0),
        (2500, 150, 0, -200, 10, 100, 0), (5000, 200, 0, -200, 10, 100, 0),
        (8000, 200, 0, -200, 10, 100, 0), (12000, 200, 0, -200, 10, 100, 0),
      ]
      for i in old ..< clamped {
        let d = defaults[safe: i] ?? (1000, 150, 0, -250, 10, 100, 0)
        dynEqFreqs.append(d.0)
        dynEqQs.append(d.1)
        dynEqGains.append(d.2)
        dynEqThresholds.append(d.3)
        dynEqAttacks.append(d.4)
        dynEqReleases.append(d.5)
        dynEqFilterTypes.append(d.6)
      }
    } else if clamped < old {
      dynEqFreqs = Array(dynEqFreqs.prefix(clamped))
      dynEqQs = Array(dynEqQs.prefix(clamped))
      dynEqGains = Array(dynEqGains.prefix(clamped))
      dynEqThresholds = Array(dynEqThresholds.prefix(clamped))
      dynEqAttacks = Array(dynEqAttacks.prefix(clamped))
      dynEqReleases = Array(dynEqReleases.prefix(clamped))
      dynEqFilterTypes = Array(dynEqFilterTypes.prefix(clamped))
    }
    dynEqBandCount = clamped
    if dynEqSelectedBand >= clamped { dynEqSelectedBand = clamped - 1 }
    guard !suppressDispatch, fxType == activeDeviceType else { return }
    for i in 0 ..< clamped {
      dispatchDynEqBand(i)
    }
    send(p(Param.HP_DYNAMIC_EQ_BAND_COUNT, Param.SPK_DYNAMIC_EQ_BAND_COUNT), clamped)
  }

  func addDynEqBand() {
    guard dynEqBandCount < 8 else { return }
    let lastFreq = dynEqFreqs.last ?? 0
    guard lastFreq < 19990 else { return }
    setDynEqBandCount(dynEqBandCount + 1)
    let newIdx = dynEqBandCount - 1
    if dynEqFreqs[safe: newIdx] ?? 0 <= lastFreq {
      let suggested = min(20000, lastFreq + max(100, (20000 - lastFreq) / 2))
      dynEqFreqs[newIdx] = (suggested / 5) * 5
      dispatchDynEqBand(newIdx)
    }
    dynEqSelectedBand = newIdx
  }

  func removeDynEqBand(at index: Int) {
    guard dynEqBandCount > 1, index < dynEqBandCount else { return }
    dynEqFreqs.remove(at: index)
    dynEqQs.remove(at: index)
    dynEqGains.remove(at: index)
    dynEqThresholds.remove(at: index)
    dynEqAttacks.remove(at: index)
    dynEqReleases.remove(at: index)
    dynEqFilterTypes.remove(at: index)
    dynEqBandCount -= 1
    if dynEqSelectedBand >= dynEqBandCount { dynEqSelectedBand = dynEqBandCount - 1 }
    guard !suppressDispatch, fxType == activeDeviceType else { return }
    for i in 0 ..< dynEqBandCount {
      dispatchDynEqBand(i)
    }
    send(p(Param.HP_DYNAMIC_EQ_BAND_COUNT, Param.SPK_DYNAMIC_EQ_BAND_COUNT), dynEqBandCount)
  }

  func dispatchMbcCrossover(_ band: Int) {
    guard !suppressDispatch, fxType == activeDeviceType, band < 4 else { return }
    send(p(Param.HP_MULTIBAND_COMP_CROSSOVER_FREQ, Param.SPK_MULTIBAND_COMP_CROSSOVER_FREQ), band, mbcCrossovers[safe: band] ?? 500)
  }

  func dispatchMbcBand(_ band: Int) {
    guard !suppressDispatch, fxType == activeDeviceType, band < 5 else { return }
    send(p(Param.HP_MULTIBAND_COMP_BAND_THRESHOLD, Param.SPK_MULTIBAND_COMP_BAND_THRESHOLD), band, Self.fetThresholdToRaw(mbcThresholds[safe: band] ?? -18))
    send(p(Param.HP_MULTIBAND_COMP_BAND_RATIO, Param.SPK_MULTIBAND_COMP_BAND_RATIO), band, mbcRatios[safe: band] ?? 50)
    send(p(Param.HP_MULTIBAND_COMP_BAND_GAIN, Param.SPK_MULTIBAND_COMP_BAND_GAIN), band, Self.fetGainToRaw(mbcGains[safe: band] ?? 24))
    send(p(Param.HP_MULTIBAND_COMP_BAND_KNEE, Param.SPK_MULTIBAND_COMP_BAND_KNEE), band, Self.fetKneeToRaw(mbcKnees[safe: band] ?? 0))
    send(p(Param.HP_MULTIBAND_COMP_BAND_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_ATTACK), band, Self.fetAttackMsToRaw(mbcAttacks[safe: band] ?? 1))
    send(p(Param.HP_MULTIBAND_COMP_BAND_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_RELEASE), band, Self.fetReleaseMsToRaw(mbcReleases[safe: band] ?? 100))
    send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_GAIN, Param.SPK_MULTIBAND_COMP_BAND_AUTO_GAIN), band, (mbcAutoGains[safe: band] ?? true) ? 100 : 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_AUTO_ATTACK), band, (mbcAutoAttacks[safe: band] ?? true) ? 100 : 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_AUTO_RELEASE), band, (mbcAutoReleases[safe: band] ?? true) ? 100 : 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_AUTO_KNEE, Param.SPK_MULTIBAND_COMP_BAND_AUTO_KNEE), band, (mbcAutoKnees[safe: band] ?? true) ? 100 : 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_KNEE_MULTI, Param.SPK_MULTIBAND_COMP_BAND_KNEE_MULTI), band, mbcKneeMultis[safe: band] ?? 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_MAX_ATTACK, Param.SPK_MULTIBAND_COMP_BAND_MAX_ATTACK), band, Self.fetAttackMsToRaw(mbcMaxAttacks[safe: band] ?? 44))
    send(p(Param.HP_MULTIBAND_COMP_BAND_MAX_RELEASE, Param.SPK_MULTIBAND_COMP_BAND_MAX_RELEASE), band, Self.fetReleaseMsToRaw(mbcMaxReleases[safe: band] ?? 200))
    send(p(Param.HP_MULTIBAND_COMP_BAND_CREST, Param.SPK_MULTIBAND_COMP_BAND_CREST), band, Self.fetReleaseMsToRaw(mbcCrests[safe: band] ?? 100))
    send(p(Param.HP_MULTIBAND_COMP_BAND_ADAPT, Param.SPK_MULTIBAND_COMP_BAND_ADAPT), band, mbcAdapts[safe: band] ?? 50)
    send(p(Param.HP_MULTIBAND_COMP_BAND_NO_CLIP, Param.SPK_MULTIBAND_COMP_BAND_NO_CLIP), band, (mbcNoClips[safe: band] ?? true) ? 100 : 0)
    send(p(Param.HP_MULTIBAND_COMP_BAND_ENABLE, Param.SPK_MULTIBAND_COMP_BAND_ENABLE), band, (mbcBandEnables[safe: band] ?? true) ? 100 : 0)
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
      Int32(p(Param.HP_DDC_COEFFICIENTS, Param.SPK_DDC_COEFFICIENTS)),
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

    let prepareParam = p(Param.HP_CONVOLVER_PREPARE_BUFFER, Param.SPK_CONVOLVER_PREPARE_BUFFER)
    let setBufferParam = p(Param.HP_CONVOLVER_SET_BUFFER, Param.SPK_CONVOLVER_SET_BUFFER)
    let commitParam = p(Param.HP_CONVOLVER_COMMIT_BUFFER, Param.SPK_CONVOLVER_COMMIT_BUFFER)

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
    saveCurrentDeviceSettings()
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
      send(p(Param.HP_DDC_ENABLE, Param.SPK_DDC_ENABLE), 1)
    }
  }

  func loadKernelByName(_ name: String) {
    let url = ProfileFileManager.shared.fileURL(name: name, type: .kernel)
    loadConvolverKernel(at: url)
    if convolutionEnabled {
      send(p(Param.HP_CONVOLVER_ENABLE, Param.SPK_CONVOLVER_ENABLE), 1)
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

  func presetIsHeadphone(_ name: String) -> Bool {
    let url = ProfileFileManager.shared.fileURL(name: "\(name).json", type: .preset)
    guard let data = try? Data(contentsOf: url),
          let state = try? JSONDecoder().decode(ModeState.self, from: data) else { return true }
    return state.mode == FXType.headphone.rawValue
  }

  func renamePreset(oldName: String, newName: String) {
    ProfileFileManager.shared.renameFile("\(oldName).json", to: "\(newName).json", type: .preset)
    refreshFileLists()
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
    for i in 0 ..< preset.bands.count {
      send(p(Param.HP_EQ_BAND_LEVEL, Param.SPK_EQ_BAND_LEVEL), i, Int(preset.bands[i] * 100))
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
