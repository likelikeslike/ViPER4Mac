import CoreAudio
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension Color {
  static let viperPurple = Color(red: 0.66, green: 0.55, blue: 0.98)
  static let viperPurpleLight = Color(red: 0.87, green: 0.82, blue: 1.0)
  static let viperAccent = Color(red: 0.76, green: 0.67, blue: 1.0)
  static let viperDeepBg = Color(red: 0.04, green: 0.03, blue: 0.08)
  static let viperSurface = Color(red: 0.11, green: 0.11, blue: 0.12)
}

struct PopoverContentView: View {
  @ObservedObject private var state = ViPERState.shared

  @State private var expandedSections: Set<String> = []
  @State private var presetName: String = ""
  @State private var showSavePreset = false
  @State private var showDriverStatus = false
  @State private var dsPresetName: String = ""
  @State private var showSaveDsPreset = false

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        headerSection
        Divider()
        presetSection
        Divider()
        outputSection
        Divider()
        effectSections
        Divider()
        footerSection
      }
      .padding(12)
    }
    .frame(width: 340, height: 560)
    .controlSize(.small)
  }

  // MARK: - Section Header Helpers

  private func sectionHeader(_ title: String, icon: String, id: String, isOn: Binding<Bool>)
    -> some View
  {
    HStack(spacing: 6) {
      Toggle("", isOn: isOn)
        .toggleStyle(.switch)
        .labelsHidden()
        .controlSize(.mini)
        .tint(.viperPurple)
        .onTapGesture {}
      Image(systemName: icon)
        .font(.caption)
        .foregroundStyle(isOn.wrappedValue ? Color.viperAccent : .secondary)
        .frame(width: 16)
      HStack(spacing: 0) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(isOn.wrappedValue ? Color.viperPurpleLight : .secondary)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(expandedSections.contains(id) ? 90 : 0))
      }
      .contentShape(Rectangle())
      .onTapGesture {
        withAnimation(.easeInOut(duration: 0.2)) {
          if expandedSections.contains(id) {
            expandedSections.remove(id)
          } else {
            expandedSections.insert(id)
          }
        }
      }
    }
    .padding(.vertical, 2)
  }

  private func toggleOnlyHeader(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
    HStack(spacing: 6) {
      Toggle("", isOn: isOn)
        .toggleStyle(.switch)
        .labelsHidden()
        .controlSize(.mini)
        .tint(.viperPurple)
      Image(systemName: icon)
        .font(.caption)
        .foregroundStyle(isOn.wrappedValue ? Color.viperAccent : .secondary)
        .frame(width: 16)
      Text(title)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(isOn.wrappedValue ? Color.viperPurpleLight : .secondary)
      Spacer()
    }
    .padding(.vertical, 2)
  }

  // MARK: - Header

  private var headerSection: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: "waveform.path.ecg.rectangle")
          .foregroundStyle(Color.viperAccent)
        Text("ViPER4Mac")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(Color.viperAccent)
        Button {
          showDriverStatus.toggle()
        } label: {
          Image(systemName: "info.circle")
            .font(.caption)
            .foregroundStyle(
              state.driverInstalled && state.isProcessing ? Color.viperAccent : .secondary)
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showDriverStatus, arrowEdge: .bottom) {
          driverStatusPopover
        }
        Spacer()
        Toggle("", isOn: $state.isEnabled)
          .toggleStyle(.switch)
          .labelsHidden()
          .tint(.viperPurple)
      }
      Picker("", selection: $state.fxType) {
        Text("Headphone").tag(ViPERState.FXType.headphone)
        Text("Speaker").tag(ViPERState.FXType.speaker)
      }
      .pickerStyle(.segmented)
      .tint(.viperPurple)
      if !state.availableOutputDevices.isEmpty {
        HStack(spacing: 6) {
          Image(systemName: "hifispeaker.2")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 16)
          Picker("", selection: $state.selectedOutputDeviceID) {
            ForEach(state.availableOutputDevices) { device in
              Text(device.name).tag(device.id)
            }
          }
          .labelsHidden()
          .frame(maxWidth: .infinity)
        }
      }
    }
  }

  // MARK: - Presets

  private var presetSection: some View {
    VStack(spacing: 4) {
      if showSavePreset {
        HStack(spacing: 6) {
          TextField("Preset name", text: $presetName)
            .textFieldStyle(.roundedBorder)
            .font(.caption)
          Button("Save") {
            let trimmed = presetName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            state.savePreset(name: trimmed)
            presetName = ""
            showSavePreset = false
          }
          .controlSize(.small)
          .disabled(presetName.trimmingCharacters(in: .whitespaces).isEmpty)
          Button("Cancel") {
            presetName = ""
            showSavePreset = false
          }
          .controlSize(.small)
        }
      } else {
        HStack(spacing: 6) {
          Text("Preset")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 45, alignment: .leading)
          Menu {
            ForEach(state.presetFiles, id: \.self) { name in
              Button(name) {
                state.loadPreset(name: name)
              }
            }
            if !state.presetFiles.isEmpty {
              Divider()
              Menu("Delete") {
                ForEach(state.presetFiles, id: \.self) { name in
                  Button(name, role: .destructive) {
                    state.deletePreset(name: name)
                  }
                }
              }
            }
          } label: {
            Text(state.presetFiles.isEmpty ? "No presets" : "Load...")
              .font(.caption)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .menuStyle(.borderlessButton)
          .frame(maxWidth: .infinity)
          Button("Save") {
            showSavePreset = true
          }
          .controlSize(.small)
          Button("Import") {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
              state.importPreset(from: url)
            }
          }
          .controlSize(.small)
        }
      }
    }
  }

  // MARK: - Output

  private var outputSection: some View {
    VStack(spacing: 6) {
      let volValues = ViPERState.outputVolumeValues
      let volPct = volValues[safe: state.outputVolume] ?? 100
      let volDb = volPct > 0 ? 20.0 * log10(Double(volPct) / 100.0) : -99.9
      steppedSlider(
        "Output Gain", value: $state.outputVolume, maxIndex: volValues.count - 1,
        steps: volValues.count - 2, label: String(format: "%.1fdB", volDb))

      paramSlider("Output Pan", intValue: $state.channelPan, range: -100...100)

      let limValues = ViPERState.limiterValues
      let limPct = limValues[safe: state.limiter] ?? 100
      let limDb = limPct > 0 ? 20.0 * log10(Double(limPct) / 100.0) : -99.9
      steppedSlider(
        "Threshold Limit", value: $state.limiter, maxIndex: limValues.count - 1,
        steps: limValues.count - 2, label: String(format: "%.1fdB", limDb))
    }
  }

  // MARK: - Effects

  private var effectSections: some View {
    VStack(spacing: 4) {
      eqSection
      bassSection
      bassMonoSection
      claritySection
      surroundSection
      diffSurroundSection
      reverbSection
      dynamicSystemSection
      toggleOnlyHeader(
        "Tube Simulator (6N1J)", icon: "music.note", isOn: $state.tubeSimulatorEnabled)
      analogXSection
      cureSection
      compressorSection
      vheSection
      spectrumSection
      agcSection
      ddcSection
      convolverSection
      if state.fxType == .speaker {
        toggleOnlyHeader(
          "Speaker Optimization", icon: "hifispeaker.fill", isOn: $state.speakerCorrectionEnabled)
      }
    }
  }

  // MARK: - EQ

  private var eqSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "FIR Equalizer", icon: "slider.vertical.3", id: "eq", isOn: $state.equalizerEnabled)
      if expandedSections.contains("eq") {
        EqCurveGraph(
          bands: state.equalizerBands,
          bandCount: state.equalizerBandCount,
          height: 120,
          interactive: true,
          onTap: { EqEditWindow.show() }
        )
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Effect Sections

  private var bassSection: some View {
    VStack(spacing: 4) {
      sectionHeader("ViPER Bass", icon: "waveform", id: "bass", isOn: $state.viperBassEnabled)
      if expandedSections.contains("bass") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperBassMode) {
            Text("Natural").tag(0)
            Text("Pure Bass").tag(1)
            Text("Subwoofer").tag(2)
          }
          .pickerStyle(.segmented)
          paramSlider(
            "Frequency", intValue: $state.viperBassFrequency, range: 0...135,
            displayFn: { "\($0 + 15)Hz" })
          steppedSlider(
            "Gain", value: $state.viperBassGain, maxIndex: 19, steps: 18,
            label:
              ViPERState.bassGainDbLabels[safe: state.viperBassGain].map { "\($0)dB" } ?? "--"
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var bassMonoSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "ViPER Bass Mono", icon: "waveform", id: "bassMono", isOn: $state.viperBassMonoEnabled)
      if expandedSections.contains("bassMono") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperBassMonoMode) {
            Text("Natural").tag(0)
            Text("Pure Bass").tag(1)
            Text("Subwoofer").tag(2)
          }
          .pickerStyle(.segmented)
          paramSlider(
            "Frequency", intValue: $state.viperBassMonoFrequency, range: 0...135,
            displayFn: { "\($0 + 15)Hz" })
          steppedSlider(
            "Gain", value: $state.viperBassMonoGain, maxIndex: 19, steps: 18,
            label:
              ViPERState.bassGainDbLabels[safe: state.viperBassMonoGain].map { "\($0)dB" } ?? "--"
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var claritySection: some View {
    VStack(spacing: 4) {
      sectionHeader("ViPER Clarity", icon: "ear", id: "clarity", isOn: $state.viperClarityEnabled)
      if expandedSections.contains("clarity") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperClarityMode) {
            Text("Natural").tag(0)
            Text("OZone").tag(1)
            Text("XHiFi").tag(2)
          }
          .pickerStyle(.segmented)
          steppedSlider(
            "Gain", value: $state.viperClarityGain, maxIndex: 9, steps: 8,
            label:
              ViPERState.clarityGainDbLabels[safe: state.viperClarityGain].map { "\($0)dB" } ?? "--"
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var surroundSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Field Surround", icon: "dot.radiowaves.left.and.right", id: "surround",
        isOn: $state.fieldSurroundEnabled)
      if expandedSections.contains("surround") {
        VStack(spacing: 4) {
          steppedSlider("Widening", value: $state.fieldSurroundWidening, maxIndex: 8, steps: 7)
          steppedSlider("Mid Image", value: $state.fieldSurroundMidImage, maxIndex: 10, steps: 9)
          steppedSlider("Depth", value: $state.fieldSurroundDepth, maxIndex: 10, steps: 9)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var diffSurroundSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Differential Surround", icon: "person.wave.2", id: "diffsurr",
        isOn: $state.diffSurroundEnabled)
      if expandedSections.contains("diffsurr") {
        VStack(spacing: 4) {
          let delayVal = ViPERState.diffSurroundDelayValues[safe: state.diffSurroundDelay] ?? 500
          steppedSlider(
            "Delay", value: $state.diffSurroundDelay, maxIndex: 19, steps: 18,
            label: "\(delayVal / 100)ms")
        }
        .padding(.leading, 4)
      }
    }
  }

  private var reverbSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Reverberation", icon: "aqi.medium", id: "reverb", isOn: $state.reverberationEnabled)
      if expandedSections.contains("reverb") {
        VStack(spacing: 4) {
          steppedSlider("Room Size", value: $state.reverberationRoomSize, maxIndex: 10, steps: 9)
          steppedSlider("Width", value: $state.reverberationRoomWidth, maxIndex: 10, steps: 9)
          steppedSlider(
            "Dampening", value: $state.reverberationRoomDampening, maxIndex: 10, steps: 9)
          paramSlider(
            "Wet", intValue: $state.reverberationWetSignal, range: 0...100,
            displayFn: { "\($0)%" })
          paramSlider(
            "Dry", intValue: $state.reverberationDrySignal, range: 0...100,
            displayFn: { "\($0)%" })
        }
        .padding(.leading, 4)
      }
    }
  }

  private var dynamicSystemSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Dynamic System", icon: "hifispeaker.fill", id: "dynsys", isOn: $state.dynamicSystemEnabled)
      if expandedSections.contains("dynsys") {
        VStack(spacing: 4) {
          HStack {
            Picker("Device", selection: $state.dynamicSystemDevice) {
              ForEach(0..<ViPERState.dynamicSystemDevices.count, id: \.self) { i in
                Text(ViPERState.dynamicSystemDevices[i].name).tag(i)
              }
              if !state.dsPresetFiles.isEmpty {
                Divider()
                ForEach(Array(state.dsPresetFiles.enumerated()), id: \.offset) { i, name in
                  Text(name).tag(1000 + i)
                }
              }
            }
            .onChange(of: state.dynamicSystemDevice) {
              let newValue = state.dynamicSystemDevice
              if newValue >= 1000 {
                let idx = newValue - 1000
                guard idx < state.dsPresetFiles.count else { return }
                state.loadDsPreset(name: state.dsPresetFiles[idx])
              }
            }
            Button {
              showSaveDsPreset = true
              dsPresetName = ""
            } label: {
              Image(systemName: "square.and.arrow.down")
                .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Save current DS as preset")
            if state.dynamicSystemDevice >= 1000 {
              Button {
                let idx = state.dynamicSystemDevice - 1000
                guard idx < state.dsPresetFiles.count else { return }
                state.deleteDsPreset(name: state.dsPresetFiles[idx])
                state.dynamicSystemDevice = 0
              } label: {
                Image(systemName: "trash")
                  .font(.system(size: 11))
                  .foregroundStyle(.red)
              }
              .buttonStyle(.borderless)
              .help("Delete selected preset")
            }
          }
          .sheet(isPresented: $showSaveDsPreset) {
            VStack(spacing: 12) {
              Text("Save DS Preset")
                .font(.headline)
              TextField("Preset name", text: $dsPresetName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
              HStack(spacing: 8) {
                Button("Cancel") {
                  showSaveDsPreset = false
                }
                Button("Save") {
                  let trimmed = dsPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                  guard !trimmed.isEmpty else { return }
                  state.saveDsPreset(name: trimmed)
                  showSaveDsPreset = false
                  if let idx = state.dsPresetFiles.firstIndex(of: trimmed) {
                    state.dynamicSystemDevice = 1000 + idx
                  }
                }
                .disabled(dsPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
              }
            }
            .padding(20)
          }
          paramSlider(
            "Strength", intValue: $state.dynamicSystemStrength, range: 0...100,
            displayFn: { "\($0)%" })
          paramSlider(
            "X Low Freq", intValue: $state.dsXLow, range: 0...2400,
            displayFn: { "\($0) Hz" })
          paramSlider(
            "X High Freq", intValue: $state.dsXHigh, range: 0...12000,
            displayFn: { "\($0) Hz" })
          paramSlider(
            "Y Low Freq", intValue: $state.dsYLow, range: 0...200,
            displayFn: { "\($0) Hz" })
          paramSlider(
            "Y High Freq", intValue: $state.dsYHigh, range: 0...300,
            displayFn: { "\($0) Hz" })
          paramSlider(
            "Side Gain Lo", intValue: $state.dsSideGainLow, range: 0...100,
            displayFn: { "\($0)%" })
          paramSlider(
            "Side Gain Hi", intValue: $state.dsSideGainHigh, range: 0...100,
            displayFn: { "\($0)%" })
        }
        .padding(.leading, 4)
      }
    }
  }

  private var analogXSection: some View {
    VStack(spacing: 4) {
      sectionHeader("AnalogX", icon: "memorychip", id: "analogx", isOn: $state.analogXEnabled)
      if expandedSections.contains("analogx") {
        Picker("Mode", selection: $state.analogXMode) {
          Text("Mild").tag(0)
          Text("Medium").tag(1)
          Text("Strong").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.leading, 4)
      }
    }
  }

  private var cureSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Auditory System Protection", icon: "cross.case.fill", id: "cure", isOn: $state.cureEnabled)
      if expandedSections.contains("cure") {
        Picker("Preset", selection: $state.cureCrossfeedStrength) {
          Text("Mild").tag(0)
          Text("Medium").tag(1)
          Text("Strong").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.leading, 4)
      }
    }
  }

  private var compressorSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "FET Compressor", icon: "rectangle.compress.vertical", id: "comp",
        isOn: $state.fetCompressorEnabled)
      if expandedSections.contains("comp") {
        VStack(spacing: 4) {
          paramSlider("Threshold", intValue: $state.fetCompressorThreshold, range: 0...200)
          paramSlider("Ratio", intValue: $state.fetCompressorRatio, range: 0...200)
          toggleRow("Auto Knee", isOn: $state.fetCompressorAutoKnee)
          paramSlider(
            "Knee", intValue: $state.fetCompressorKnee, range: 0...200,
            enabled: !state.fetCompressorAutoKnee)
          paramSlider("Knee Multi", intValue: $state.fetCompressorKneeMulti, range: 0...200)
          toggleRow("Auto Gain", isOn: $state.fetCompressorAutoGain)
          paramSlider(
            "Gain", intValue: $state.fetCompressorGain, range: 0...200,
            enabled: !state.fetCompressorAutoGain)
          toggleRow("Auto Attack", isOn: $state.fetCompressorAutoAttack)
          paramSlider(
            "Attack", intValue: $state.fetCompressorAttack, range: 0...200,
            enabled: !state.fetCompressorAutoAttack)
          paramSlider("Max Attack", intValue: $state.fetCompressorMaxAttack, range: 0...200)
          toggleRow("Auto Release", isOn: $state.fetCompressorAutoRelease)
          paramSlider(
            "Release", intValue: $state.fetCompressorRelease, range: 0...200,
            enabled: !state.fetCompressorAutoRelease)
          paramSlider("Max Release", intValue: $state.fetCompressorMaxRelease, range: 0...200)
          paramSlider("Crest", intValue: $state.fetCompressorCrest, range: 0...300)
          paramSlider("Adapt", intValue: $state.fetCompressorAdapt, range: 0...200)
          toggleRow("No Clip", isOn: $state.fetCompressorNoClip)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var vheSection: some View {
    VStack(spacing: 4) {
      sectionHeader("Headphone Surround+", icon: "headphones", id: "vhe", isOn: $state.vheEnabled)
      if expandedSections.contains("vhe") {
        steppedSlider("Quality", value: $state.vheQuality, maxIndex: 4, steps: 3)
          .padding(.leading, 4)
      }
    }
  }

  private var spectrumSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Spectrum Extension", icon: "water.waves", id: "vse", isOn: $state.spectrumExtensionEnabled)
      if expandedSections.contains("vse") {
        VStack(spacing: 4) {
          steppedSlider("Strength", value: $state.spectrumExtensionBark, maxIndex: 10, steps: 9)
          paramSlider(
            "Exciter", intValue: $state.spectrumExtensionBarkReconstruct, range: 0...100,
            displayFn: { "\($0)%" })
        }
        .padding(.leading, 4)
      }
    }
  }

  private var agcSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Playback Gain Control", icon: "chart.line.uptrend.xyaxis", id: "agc",
        isOn: $state.playbackGainEnabled)
      if expandedSections.contains("agc") {
        VStack(spacing: 4) {
          steppedSlider("Strength", value: $state.playbackGainStrength, maxIndex: 2, steps: 1)
          steppedSlider("Max Gain", value: $state.playbackGainMaxGain, maxIndex: 10, steps: 9)
          let threshValues = ViPERState.limiterValues
          let threshPct = threshValues[safe: state.playbackGainOutputThreshold] ?? 100
          let threshDb = threshPct > 0 ? 20.0 * log10(Double(threshPct) / 100.0) : -99.9
          steppedSlider(
            "Threshold", value: $state.playbackGainOutputThreshold,
            maxIndex: threshValues.count - 1, steps: threshValues.count - 2,
            label: String(format: "%.1fdB", threshDb))
        }
        .padding(.leading, 4)
      }
    }
  }

  private var ddcSection: some View {
    VStack(spacing: 4) {
      sectionHeader("ViPER-DDC", icon: "slider.horizontal.3", id: "ddc", isOn: $state.ddcEnabled)
      if expandedSections.contains("ddc") {
        VStack(spacing: 4) {
          HStack(spacing: 6) {
            Text("File")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(width: 65, alignment: .leading)
            Picker(
              "",
              selection: Binding(
                get: { state.ddcFilePath },
                set: { name in
                  if name.isEmpty {
                    state.ddcFilePath = ""
                    state.ddcEnabled = false
                  } else {
                    state.loadDDCByName(name)
                  }
                }
              )
            ) {
              Text("None").tag("")
              ForEach(state.ddcFiles, id: \.self) { name in
                Text(name).tag(name)
              }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
          }
          HStack(spacing: 6) {
            Spacer()
            Button("Import") {
              let panel = NSOpenPanel()
              panel.allowedContentTypes = [UTType(filenameExtension: "vdc")].compactMap { $0 }
              panel.allowsOtherFileTypes = true
              panel.allowsMultipleSelection = false
              panel.canChooseDirectories = false
              if panel.runModal() == .OK, let url = panel.url {
                state.importDDC(from: url)
              }
            }
            .controlSize(.small)
            Button("Delete") {
              guard !state.ddcFilePath.isEmpty else { return }
              state.deleteDDC(state.ddcFilePath)
            }
            .controlSize(.small)
            .disabled(state.ddcFilePath.isEmpty)
          }
        }
        .padding(.leading, 4)
      }
    }
  }

  private var convolverSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        "Convolver", icon: "waveform.circle", id: "conv", isOn: $state.convolutionEnabled)
      if expandedSections.contains("conv") {
        VStack(spacing: 4) {
          HStack(spacing: 6) {
            Text("Kernel")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(width: 65, alignment: .leading)
            Picker(
              "",
              selection: Binding(
                get: { state.convolutionKernelPath },
                set: { name in
                  if name.isEmpty {
                    state.convolutionKernelPath = ""
                    state.convolutionEnabled = false
                  } else {
                    state.loadKernelByName(name)
                  }
                }
              )
            ) {
              Text("None").tag("")
              ForEach(state.kernelFiles, id: \.self) { name in
                Text(name).tag(name)
              }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
          }
          HStack(spacing: 6) {
            Spacer()
            Button("Import") {
              let panel = NSOpenPanel()
              panel.allowedContentTypes = [UTType.wav, UTType(filenameExtension: "irs")].compactMap
              { $0 }
              panel.allowsOtherFileTypes = true
              panel.allowsMultipleSelection = false
              panel.canChooseDirectories = false
              if panel.runModal() == .OK, let url = panel.url {
                state.importKernel(from: url)
              }
            }
            .controlSize(.small)
            Button("Delete") {
              guard !state.convolutionKernelPath.isEmpty else { return }
              state.deleteKernel(state.convolutionKernelPath)
            }
            .controlSize(.small)
            .disabled(state.convolutionKernelPath.isEmpty)
          }
          paramSlider(
            "Cross Ch.", intValue: $state.convolutionCrossChannel, range: 0...100,
            displayFn: { "\($0)%" })
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Footer

  private var footerSection: some View {
    HStack {
      Toggle("Launch at Login", isOn: $state.launchAtLogin)
        .toggleStyle(.switch)
        .controlSize(.mini)
        .font(.caption)
        .foregroundStyle(.secondary)
        .tint(.viperPurple)
      Spacer()
      Button("Quit") {
        AudioEngine.shared.stop()
        NSApplication.shared.terminate(nil)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.secondary)
      .font(.caption)
    }
    .padding(.top, 4)
  }

  // MARK: - Driver Status

  private var driverStatusPopover: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("ViPER4Mac")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(Color.viperAccent)

      statusRow(
        "App Version",
        value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
          ?? "?")
      statusRow(
        "Driver",
        value: state.driverInstalled
          ? "v\(state.driverVersion)" : "Not Found",
        color: state.driverInstalled ? .green : .red)
      statusRow(
        "Processing",
        value: state.isProcessing ? "Active" : "Inactive",
        color: state.isProcessing ? .green : .orange)

      Divider()

      statusRow(
        "Audio Mode",
        value: state.fxType == .headphone ? "Headphone" : "Speaker")
      statusRow(
        "Sample Rate",
        value: state.currentSampleRate > 0
          ? "\(state.currentSampleRate) Hz" : "N/A")
      statusRow(
        "Output Device",
        value: state.outputDeviceName)
    }
    .padding(12)
    .frame(width: 220)
  }

  private func statusRow(_ label: String, value: String, color: Color? = nil) -> some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      HStack(spacing: 4) {
        if let color {
          Circle()
            .fill(color)
            .frame(width: 6, height: 6)
        }
        Text(value)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
      }
    }
  }

  // MARK: - Helpers

  private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Toggle("", isOn: isOn)
        .toggleStyle(.switch)
        .labelsHidden()
        .controlSize(.mini)
        .tint(.viperPurple)
    }
  }

  private func steppedSlider(
    _ label: String, value: Binding<Int>, maxIndex: Int,
    steps: Int, label displayLabel: String? = nil
  ) -> some View {
    let floatBinding = Binding<Float>(
      get: { Float(value.wrappedValue) },
      set: { value.wrappedValue = Int($0.rounded()) }
    )
    return HStack(spacing: 6) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 65, alignment: .leading)
      Slider(value: floatBinding, in: 0...Float(maxIndex), step: 1)
        .tint(.viperPurple)
      Text(displayLabel ?? "\(value.wrappedValue)")
        .font(.caption)
        .monospacedDigit()
        .frame(width: 48, alignment: .trailing)
    }
  }

  private func paramSlider(
    _ label: String, intValue: Binding<Int>, range: ClosedRange<Int>,
    unit: String = "", displayFn: ((Int) -> String)? = nil,
    enabled: Bool = true
  ) -> some View {
    let floatBinding = Binding<Float>(
      get: { Float(intValue.wrappedValue) },
      set: { intValue.wrappedValue = Int($0) }
    )
    let display = displayFn?(intValue.wrappedValue) ?? "\(intValue.wrappedValue)\(unit)"
    return HStack(spacing: 6) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 65, alignment: .leading)
      Slider(value: floatBinding, in: Float(range.lowerBound)...Float(range.upperBound))
        .tint(.viperPurple)
        .disabled(!enabled)
      Text(display)
        .font(.caption)
        .monospacedDigit()
        .frame(width: 48, alignment: .trailing)
    }
    .opacity(enabled ? 1.0 : 0.5)
  }
}
