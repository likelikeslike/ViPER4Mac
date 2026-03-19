import AppKit
import SwiftUI

private let dbMin: Float = -12
private let dbMax: Float = 12
private let dbGridLines: [Float] = [-12, -6, 0, 6, 12]

enum EqLabels {
  static let graph10 = ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
  static let graph15 = [
    "25", "40", "63", "100", "160", "250", "400", "630", "1k", "1.6k", "2.5k", "4k", "6.3k", "10k",
    "16k",
  ]
  static let graph25 = [
    "20", "31", "40", "50", "80", "100", "125", "160", "250", "315", "400", "500", "800", "1k",
    "1.25k", "1.6k", "2.5k", "3.15k", "4k", "5k", "8k", "10k", "12.5k", "16k", "20k",
  ]
  static let graph31 = [
    "20", "25", "31", "40", "50", "63", "80", "100", "125", "160", "200", "250", "315", "400",
    "500", "630", "800", "1k", "1.25k", "1.6k", "2k", "2.5k", "3.15k", "4k", "5k", "6.3k", "8k",
    "10k", "12.5k", "16k", "20k",
  ]

  static let full10 = [
    "31Hz", "62Hz", "125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz", "16kHz",
  ]
  static let full15 = [
    "25Hz", "40Hz", "63Hz", "100Hz", "160Hz", "250Hz", "400Hz", "630Hz", "1kHz", "1.6kHz", "2.5kHz",
    "4kHz", "6.3kHz", "10kHz", "16kHz",
  ]
  static let full25 = [
    "20Hz", "31Hz", "40Hz", "50Hz", "80Hz", "100Hz", "125Hz", "160Hz", "250Hz", "315Hz", "400Hz",
    "500Hz", "800Hz", "1kHz", "1.25kHz", "1.6kHz", "2.5kHz", "3.15kHz", "4kHz", "5kHz", "8kHz",
    "10kHz", "12.5kHz", "16kHz", "20kHz",
  ]
  static let full31 = [
    "20Hz", "25Hz", "31Hz", "40Hz", "50Hz", "63Hz", "80Hz", "100Hz", "125Hz", "160Hz", "200Hz",
    "250Hz", "315Hz", "400Hz", "500Hz", "630Hz", "800Hz", "1kHz", "1.25kHz", "1.6kHz", "2kHz",
    "2.5kHz", "3.15kHz", "4kHz", "5kHz", "6.3kHz", "8kHz", "10kHz", "12.5kHz", "16kHz", "20kHz",
  ]

  static func graphLabels(for count: Int) -> [String] {
    switch count {
    case 15: return graph15
    case 25: return graph25
    case 31: return graph31
    default: return graph10
    }
  }

  static func fullLabels(for count: Int) -> [String] {
    switch count {
    case 15: return full15
    case 25: return full25
    case 31: return full31
    default: return full10
    }
  }

  static func labelStep(for count: Int) -> Int {
    switch count {
    case 31: return 5
    case 25: return 4
    case 15: return 2
    default: return 1
    }
  }
}

enum EqPresets {
  static let names = [
    Text("Acoustic"), Text("Bass Booster"), Text("Bass Reducer"), Text("Classical"),
    Text("Deep"), Text("Flat"), Text("R&B"), Text("Rock"),
    Text("Small Speakers"), Text("Treble Booster"), Text("Treble Reducer"), Text("Vocal Booster"),
  ]

  static let presets10: [[Float]] = [
    [4.5, 4.5, 3.5, 1.2, 1.0, 0.5, 1.4, 1.75, 3.5, 2.5],
    [6.0, 4.0, 2.0, 0, 0, 0, 0, 0, 0, 0],
    [-6.0, -4.0, -2.0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, -3.0, -3.0, -3.0, -5.0],
    [3.0, 2.0, 1.0, 0.5, 0.5, 0, -1.0, -2.0, -3.0, -3.5],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [3.0, 6.0, 4.0, 1.0, -1.0, -0.5, 1.0, 1.5, 2.5, 3.0],
    [4.0, 3.0, 1.0, 0, -0.5, 0, 1.5, 2.5, 3.5, 4.0],
    [3.0, 2.0, 1.5, 1.0, 0.5, -0.5, -1.5, -2.0, -3.0, -3.5],
    [0, 0, 0, 0, 0, 1.0, 2.0, 3.0, 4.0, 5.0],
    [0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -4.0, -5.0],
    [-1.0, -0.5, 0, 1.5, 3.0, 3.0, 2.0, 1.0, 0, -1.0],
  ]

  static let presets15: [[Float]] = [
    [4.5, 4.5, 4.5, 4.0, 2.5, 1.0, 1.0, 1.0, 0.5, 1.0, 1.5, 2.0, 3.0, 3.0, 2.5],
    [6.0, 5.5, 4.0, 2.5, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [-6.0, -5.5, -4.0, -2.5, -1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, -2.0, -3.0, -3.0, -3.0, -3.5, -5.0],
    [3.0, 2.5, 2.0, 1.5, 1.0, 0.5, 0.5, 0.5, 0, -0.5, -1.5, -2.0, -2.5, -3.0, -3.5],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [3.0, 4.0, 6.0, 4.5, 3.0, 1.0, -0.5, -1.0, -0.5, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
    [4.0, 3.5, 3.0, 1.5, 0.5, 0, -0.5, -0.5, 0, 1.0, 2.0, 2.5, 3.0, 3.5, 4.0],
    [3.0, 2.5, 2.0, 1.5, 1.5, 1.0, 0.5, 0, -0.5, -1.0, -1.5, -2.0, -2.5, -3.0, -3.5],
    [0, 0, 0, 0, 0, 0, 0, 0.5, 1.0, 1.5, 2.5, 3.0, 3.5, 4.5, 5.0],
    [0, 0, 0, 0, 0, 0, 0, -0.5, -1.0, -1.5, -2.5, -3.0, -3.5, -4.5, -5.0],
    [-1.0, -1.0, -0.5, 0, 0.5, 1.5, 2.5, 3.0, 3.0, 2.5, 1.5, 1.0, 0.5, -0.5, -1.0],
  ]

  static let presets25: [[Float]] = [
    [
      4.5, 4.5, 4.5, 4.5, 4.0, 4.0, 3.5, 2.5, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.5, 1.5, 2.0,
      2.5, 3.5, 3.0, 3.0, 2.5, 2.5,
    ],
    [6.0, 6.0, 5.5, 4.5, 3.5, 2.5, 2.0, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [
      -6.0, -6.0, -5.5, -4.5, -3.5, -2.5, -2.0, -1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.5,
      -4.5, -5.0, -5.0,
    ],
    [
      3.0, 3.0, 2.5, 2.5, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0, 0, -0.5, -0.5, -1.5, -1.5,
      -2.0, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5,
    ],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [
      3.0, 3.0, 4.0, 5.0, 5.5, 4.5, 4.0, 3.0, 1.0, 0.5, -0.5, -1.0, -0.5, -0.5, 0, 0.5, 1.0, 1.5,
      1.5, 2.0, 2.5, 2.5, 3.0, 3.0, 3.0,
    ],
    [
      4.0, 4.0, 3.5, 3.5, 2.5, 1.5, 1.0, 0.5, 0, 0, -0.5, -0.5, 0, 0, 0.5, 1.0, 2.0, 2.0, 2.5, 3.0,
      3.5, 3.5, 4.0, 4.0, 4.0,
    ],
    [
      3.0, 3.0, 2.5, 2.5, 2.0, 1.5, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0, -0.5, -1.0, -1.0, -1.5, -2.0,
      -2.0, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 1.0, 1.5, 1.5, 2.5, 2.5, 3.0, 3.5, 4.0, 4.5, 4.5,
      5.0, 5.0,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.5, -1.0, -1.5, -1.5, -2.5, -2.5, -3.0, -3.5, -4.0,
      -4.5, -4.5, -5.0, -5.0,
    ],
    [
      -1.0, -1.0, -1.0, -0.5, -0.5, 0, 0, 0.5, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 2.5, 2.5, 1.5, 1.5,
      1.0, 0.5, 0, -0.5, -0.5, -1.0, -1.0,
    ],
  ]

  static let presets31: [[Float]] = [
    [
      4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.0, 4.0, 3.5, 2.5, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0,
      1.0, 1.5, 1.5, 1.5, 2.0, 2.5, 3.0, 3.5, 3.0, 3.0, 2.5, 2.5,
    ],
    [
      6.0, 6.0, 6.0, 5.5, 4.5, 4.0, 3.5, 2.5, 2.0, 1.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0,
    ],
    [
      -6.0, -6.0, -6.0, -5.5, -4.5, -4.0, -3.5, -2.5, -2.0, -1.5, -0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -3.0, -3.0, -3.0,
      -3.0, -3.0, -3.0, -3.5, -4.5, -5.0, -5.0,
    ],
    [
      3.0, 3.0, 3.0, 2.5, 2.5, 2.0, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, -0.5,
      -0.5, -1.0, -1.5, -1.5, -2.0, -2.5, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5,
    ],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [
      3.0, 3.0, 3.0, 4.0, 5.0, 6.0, 5.5, 4.5, 4.0, 3.0, 2.0, 1.0, 0.5, -0.5, -1.0, -1.0, -0.5, -0.5,
      0, 0.5, 1.0, 1.0, 1.5, 1.5, 2.0, 2.0, 2.5, 2.5, 3.0, 3.0, 3.0,
    ],
    [
      4.0, 4.0, 4.0, 3.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5, 0.5, 0, 0, -0.5, -0.5, -0.5, 0, 0, 0.5, 1.0,
      1.5, 2.0, 2.0, 2.5, 3.0, 3.0, 3.5, 3.5, 4.0, 4.0, 4.0,
    ],
    [
      3.0, 3.0, 3.0, 2.5, 2.5, 2.0, 2.0, 1.5, 1.5, 1.5, 1.0, 1.0, 1.0, 0.5, 0.5, 0, 0, -0.5, -1.0,
      -1.0, -1.5, -1.5, -2.0, -2.0, -2.5, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 1.0, 1.5, 1.5, 2.0, 2.5, 2.5, 3.0, 3.5,
      3.5, 4.0, 4.5, 4.5, 5.0, 5.0,
    ],
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.5, -0.5, -1.0, -1.5, -1.5, -2.0, -2.5, -2.5,
      -3.0, -3.5, -3.5, -4.0, -4.5, -4.5, -5.0, -5.0,
    ],
    [
      -1.0, -1.0, -1.0, -1.0, -0.5, -0.5, -0.5, 0, 0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 3.0,
      2.5, 2.5, 2.0, 1.5, 1.5, 1.0, 0.5, 0.5, 0, -0.5, -0.5, -1.0, -1.0,
    ],
  ]

  static func presets(for count: Int) -> [[Float]] {
    switch count {
    case 15: return presets15
    case 25: return presets25
    case 31: return presets31
    default: return presets10
    }
  }
}

struct EqCurveGraph: View {
  let bands: [Float]
  let bandCount: Int
  var height: CGFloat = 120
  var interactive: Bool = true
  var onTap: (() -> Void)?

  var body: some View {
    Canvas { context, size in
      drawGraph(context: context, size: size)
    }
    .frame(height: height)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .contentShape(Rectangle())
    .onTapGesture {
      if interactive { onTap?() }
    }
  }

  private func drawGraph(context: GraphicsContext, size: CGSize) {
    let paddingLeft: CGFloat = 28
    let paddingRight: CGFloat = 12
    let paddingTop: CGFloat = 16
    let paddingBottom: CGFloat = 20

    let graphWidth = size.width - paddingLeft - paddingRight
    let graphHeight = size.height - paddingTop - paddingBottom

    let gridColor = Color.white.opacity(0.1)
    let dbLabelColor = Color.white.opacity(0.4)
    let freqLabelColor = Color.secondary

    for db in dbGridLines {
      let y = paddingTop + graphHeight * CGFloat(1.0 - (db - dbMin) / (dbMax - dbMin))
      var gridPath = Path()
      gridPath.move(to: CGPoint(x: paddingLeft, y: y))
      gridPath.addLine(to: CGPoint(x: size.width - paddingRight, y: y))
      context.stroke(gridPath, with: .color(gridColor), lineWidth: 0.5)

      let label: String
      if db > 0 {
        label = "+\(Int(db))"
      } else if db == 0 {
        label = "0"
      } else {
        label = "\(Int(db))"
      }
      let text = Text(label).font(.system(size: 7, design: .monospaced)).foregroundColor(
        dbLabelColor
      )
      context.draw(text, at: CGPoint(x: paddingLeft - 4, y: y), anchor: .trailing)
    }

    guard bands.count >= bandCount, bandCount > 1 else { return }

    let points: [CGPoint] = (0 ..< bandCount).map { i in
      let x = paddingLeft + graphWidth * CGFloat(i) / CGFloat(bandCount - 1)
      let db = min(max(bands[i], dbMin), dbMax)
      let y = paddingTop + graphHeight * CGFloat(1.0 - (db - dbMin) / (dbMax - dbMin))
      return CGPoint(x: x, y: y)
    }

    let curvePath = buildSplinePath(points: points)

    var fillPath = curvePath
    fillPath.addLine(to: CGPoint(x: points.last!.x, y: paddingTop + graphHeight))
    fillPath.addLine(to: CGPoint(x: points.first!.x, y: paddingTop + graphHeight))
    fillPath.closeSubpath()

    let gradient = Gradient(colors: [
      Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.0),
    ])
    context.fill(
      fillPath,
      with: .linearGradient(
        gradient,
        startPoint: CGPoint(x: 0, y: paddingTop),
        endPoint: CGPoint(x: 0, y: paddingTop + graphHeight)
      )
    )

    context.stroke(curvePath, with: .color(.accentColor), lineWidth: 2)

    let dotRadius: CGFloat = bandCount > 15 ? 2 : 3
    for pt in points {
      let dotRect = CGRect(
        x: pt.x - dotRadius, y: pt.y - dotRadius,
        width: dotRadius * 2, height: dotRadius * 2
      )
      context.fill(Path(ellipseIn: dotRect), with: .color(.accentColor))
    }

    let graphLabels = EqLabels.graphLabels(for: bandCount)
    let step = EqLabels.labelStep(for: bandCount)
    let fontSize: CGFloat = bandCount > 15 ? 6 : 8

    for (i, pt) in points.enumerated() {
      if i % step == 0 {
        let label = graphLabels[safe: i] ?? ""
        let text = Text(label).font(.system(size: fontSize, design: .monospaced)).foregroundColor(
          freqLabelColor
        )
        context.draw(text, at: CGPoint(x: pt.x, y: paddingTop + graphHeight + 10), anchor: .center)
      }
    }

    if bandCount <= 15 {
      for (i, pt) in points.enumerated() {
        let valText = String(format: "%.1f", bands[i])
        let text = Text(valText).font(.system(size: 7, weight: .medium, design: .monospaced))
          .foregroundColor(.accentColor)
        context.draw(text, at: CGPoint(x: pt.x, y: pt.y - 8), anchor: .center)
      }
    }
  }
}

private func buildSplinePath(points: [CGPoint]) -> Path {
  var path = Path()
  guard !points.isEmpty else { return path }
  path.move(to: points[0])
  let tension: CGFloat = 0.3
  for i in 0 ..< (points.count - 1) {
    let prev = points[max(0, i - 1)]
    let curr = points[i]
    let next = points[i + 1]
    let afterNext = points[min(points.count - 1, i + 2)]
    let cp1 = CGPoint(
      x: curr.x + (next.x - prev.x) * tension,
      y: curr.y + (next.y - prev.y) * tension
    )
    let cp2 = CGPoint(
      x: next.x - (afterNext.x - curr.x) * tension,
      y: next.y - (afterNext.y - curr.y) * tension
    )
    path.addCurve(to: next, control1: cp1, control2: cp2)
  }
  return path
}

// MARK: - EQ Edit Popup

struct EqEditContentView: View {
  @ObservedObject private var state = ViPERState.shared
  @State private var selectedPreset: Int = -1
  @State private var showSaveSheet = false
  @State private var newPresetName = ""

  var body: some View {
    VStack(spacing: 12) {
      EqCurveGraph(
        bands: state.equalizerBands,
        bandCount: state.equalizerBandCount,
        height: 160,
        interactive: false
      )

      Picker(
        "Bands",
        selection: Binding(
          get: { state.equalizerBandCount },
          set: { newCount in
            DispatchQueue.main.async {
              state.setEQBandCount(newCount)
              selectedPreset = -1
            }
          }
        )
      ) {
        Text("10").tag(10)
        Text("15").tag(15)
        Text("25").tag(25)
        Text("31").tag(31)
      }
      .pickerStyle(.segmented)

      HStack(spacing: 6) {
        Text("Preset")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(width: 42, alignment: .trailing)
        Picker("", selection: $selectedPreset) {
          Text("Custom").tag(-1)
          ForEach(Array(EqPresets.names.enumerated()), id: \.offset) { i, name in
            name.tag(i)
          }
          let userPresets = state.eqPresetsForCurrentBandCount()
          if !userPresets.isEmpty {
            Divider()
            ForEach(Array(userPresets.enumerated()), id: \.offset) { i, name in
              Text(name).tag(1000 + i)
            }
          }
        }
        .onChange(of: selectedPreset) {
          let newValue = selectedPreset
          if newValue >= 1000 {
            let userPresets = state.eqPresetsForCurrentBandCount()
            let idx = newValue - 1000
            guard idx < userPresets.count else { return }
            state.loadEqPreset(name: userPresets[idx])
          } else if newValue >= 0 {
            let presets = EqPresets.presets(for: state.equalizerBandCount)
            guard newValue < presets.count else { return }
            let bands = presets[newValue]
            state.equalizerBands = bands
            state.equalizerBandsMap[state.equalizerBandCount] = bands
            for i in 0 ..< bands.count {
              state.sendEQBand(index: i, level: bands[i])
            }
          }
        }
        Button {
          showSaveSheet = true
          newPresetName = ""
        } label: {
          Image(systemName: "square.and.arrow.down")
            .font(.system(size: 11))
        }
        .buttonStyle(.borderless)
        .help("Save current EQ as preset")
        if selectedPreset >= 1000 {
          Button {
            let userPresets = state.eqPresetsForCurrentBandCount()
            let idx = selectedPreset - 1000
            guard idx < userPresets.count else { return }
            state.deleteEqPreset(name: userPresets[idx])
            selectedPreset = -1
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 11))
              .foregroundStyle(.red)
          }
          .buttonStyle(.borderless)
          .help("Delete selected preset")
        }
      }
      .sheet(isPresented: $showSaveSheet) {
        VStack(spacing: 12) {
          Text("Save EQ Preset")
            .font(.headline)
          TextField("Preset name", text: $newPresetName)
            .textFieldStyle(.roundedBorder)
            .frame(width: 200)
          HStack(spacing: 8) {
            Button("Cancel") {
              showSaveSheet = false
            }
            Button("Save") {
              let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
              guard !trimmed.isEmpty else { return }
              state.saveEqPreset(name: trimmed)
              showSaveSheet = false
              let userPresets = state.eqPresetsForCurrentBandCount()
              if let idx = userPresets.firstIndex(of: trimmed) {
                selectedPreset = 1000 + idx
              }
            }
            .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.defaultAction)
          }
        }
        .padding(20)
        .frame(width: 260)
      }

      ScrollView {
        VStack(spacing: 2) {
          let labels = EqLabels.fullLabels(for: state.equalizerBandCount)
          ForEach(Array(0 ..< state.equalizerBandCount), id: \.self) { i in
            eqBandRow(index: i, label: labels[safe: i] ?? "")
          }
        }
      }
    }
    .padding(16)
    .frame(width: 420, height: 580)
  }

  private func eqBandRow(index i: Int, label: String) -> some View {
    let currentValue = i < state.equalizerBands.count ? state.equalizerBands[i] : 0
    let isAtMin = currentValue <= dbMin
    let isAtMax = currentValue >= dbMax
    return HStack(spacing: 4) {
      Text(label)
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(width: 50, alignment: .trailing)
      Button {
        adjustBand(index: i, delta: -0.1)
      } label: {
        Image(systemName: "minus")
          .font(.system(size: 9, weight: .bold))
          .frame(width: 16, height: 16)
      }
      .buttonStyle(.borderless)
      .disabled(isAtMin)
      Slider(
        value: Binding(
          get: { Double(currentValue) },
          set: { val in
            if i < state.equalizerBands.count {
              state.equalizerBands[i] = Float(val)
              state.sendEQBand(index: i, level: Float(val))
              selectedPreset = -1
            }
          }
        ), in: Double(dbMin) ... Double(dbMax)
      )
      Button {
        adjustBand(index: i, delta: 0.1)
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 9, weight: .bold))
          .frame(width: 16, height: 16)
      }
      .buttonStyle(.borderless)
      .disabled(isAtMax)
      Text(String(format: "%.1fdB", currentValue))
        .font(.system(size: 9, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(width: 44, alignment: .trailing)
    }
  }

  private func adjustBand(index i: Int, delta: Float) {
    guard i < state.equalizerBands.count else { return }
    let newValue = min(dbMax, max(dbMin, state.equalizerBands[i] + delta))
    let rounded = (newValue * 10).rounded() / 10
    state.equalizerBands[i] = rounded
    state.sendEQBand(index: i, level: rounded)
    selectedPreset = -1
  }
}

enum EqEditWindow {
  private static var panel: NSPanel?

  static func show() {
    if let existing = panel {
      existing.makeKeyAndOrderFront(nil)
      return
    }

    AppDelegate.shared?.popover?.behavior = .applicationDefined

    let p = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
      styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
      backing: .buffered,
      defer: false
    )
    p.title = "Equalizer"
    p.isFloatingPanel = true
    p.level = .floating
    p.hidesOnDeactivate = false
    p.isReleasedWhenClosed = false
    p.contentView = NSHostingView(rootView: EqEditContentView())

    positionBesidePopover(p)
    p.makeKeyAndOrderFront(nil)

    panel = p

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: p, queue: .main
    ) { _ in
      AppDelegate.shared?.popover?.behavior = .transient
      panel = nil
    }
  }

  static func hide() {
    panel?.close()
  }

  private static func positionBesidePopover(_ panel: NSPanel) {
    guard let screen = NSScreen.main else {
      panel.center()
      return
    }

    let popoverWindows = NSApp.windows.filter {
      $0 !== panel && $0.isVisible && $0.className.contains("Popover")
    }

    if let popoverWindow = popoverWindows.first {
      let popFrame = popoverWindow.frame
      let panelSize = panel.frame.size
      var x = popFrame.minX - panelSize.width - 8
      if x < screen.visibleFrame.minX {
        x = popFrame.maxX + 8
      }
      let y = popFrame.maxY - panelSize.height
      panel.setFrameOrigin(NSPoint(x: x, y: max(y, screen.visibleFrame.minY)))
    } else {
      panel.center()
    }
  }
}
