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
  @State private var showEngineStatus = false
  @State private var dsPresetName: String = ""
  @State private var showSaveDsPreset = false
  @State private var showDevices = false
  @State private var showDeviceInfoUID: String? = nil
  @State private var dynEqBandToDelete: Int? = nil

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        headerSection
        Divider()
        outputSection
        Divider()
        effectSections
        Divider()
        devicesSection
        Divider()
        presetSection
        Divider()
        footerSection
      }
      .padding(12)
    }
    .frame(width: 340, height: 560)
    .controlSize(.small)
  }

  // MARK: - Section Header Helpers

  private func sectionHeader(_ title: Text, icon: String, id: String, isOn: Binding<Bool>)
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
        title
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

  private func toggleOnlyHeader(_ title: Text, icon: String, isOn: Binding<Bool>) -> some View {
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
      title
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
          showEngineStatus.toggle()
        } label: {
          Image(systemName: "info.circle")
            .font(.caption)
            .foregroundStyle(
              state.isProcessing ? Color.viperAccent : .secondary
            )
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showEngineStatus, arrowEdge: .bottom) {
          engineStatusPopover
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
    }
  }

  // MARK: - Presets

  @State private var showPresets = false
  @State private var renamingPreset: String? = nil
  @State private var presetRenameText: String = ""

  private var presetSection: some View {
    VStack(spacing: 4) {
      HStack(spacing: 6) {
        Image(systemName: "chevron.right")
          .font(.caption2)
          .rotationEffect(.degrees(showPresets ? 90 : 0))
          .animation(.easeInOut(duration: 0.2), value: showPresets)
          .foregroundStyle(.secondary)
        Image(systemName: "doc.text.fill")
          .font(.caption)
          .foregroundStyle(Color.viperPurpleLight)
        Text("Presets")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(Color.viperPurpleLight)
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture { withAnimation { showPresets.toggle() } }

      if showPresets {
        VStack(spacing: 4) {
          HStack(spacing: 6) {
            TextField("Preset name", text: $presetName)
              .textFieldStyle(.roundedBorder)
              .font(.caption)
            Button("Save") {
              let trimmed = presetName.trimmingCharacters(in: .whitespaces)
              guard !trimmed.isEmpty else { return }
              state.savePreset(name: trimmed)
              presetName = ""
            }
            .controlSize(.small)
            .disabled(presetName.trimmingCharacters(in: .whitespaces).isEmpty)
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

          ForEach(state.presetFiles, id: \.self) { name in
            HStack(spacing: 6) {
              Image(systemName: state.presetIsHeadphone(name) ? "headphones" : "speaker.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(name)
                .font(.caption)
                .lineLimit(1)
              Spacer()
              Button {
                presetRenameText = name
                renamingPreset = name
              } label: {
                Image(systemName: "pencil")
                  .font(.caption2)
              }
              .buttonStyle(.borderless)
              .help("Rename")
              Button { state.loadPreset(name: name) } label: {
                Image(systemName: "arrow.down.circle")
                  .font(.caption2)
              }
              .buttonStyle(.borderless)
              .help("Load")
              Button { state.deletePreset(name: name) } label: {
                Image(systemName: "trash")
                  .font(.caption2)
                  .foregroundStyle(.red)
              }
              .buttonStyle(.borderless)
              .help("Delete")
            }
          }

          if state.presetFiles.isEmpty {
            Text("No presets")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.leading, 4)
      }
    }
    .sheet(item: Binding(
      get: { renamingPreset.map { RenameItem(id: $0) } },
      set: { renamingPreset = $0?.id }
    )) { item in
      VStack(spacing: 12) {
        Text("Rename Preset")
          .font(.headline)
        TextField("Preset name", text: $presetRenameText)
          .textFieldStyle(.roundedBorder)
        HStack {
          Button("Cancel") { renamingPreset = nil }
          Spacer()
          Button("Rename") {
            let trimmed = presetRenameText.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed != item.id {
              state.renamePreset(oldName: item.id, newName: trimmed)
            }
            renamingPreset = nil
          }
          .keyboardShortcut(.defaultAction)
          .disabled(presetRenameText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
      .padding(20)
      .frame(width: 280)
    }
  }

  // MARK: - Devices

  @State private var renamingDeviceUID: String? = nil
  @State private var deviceRenameText: String = ""

  private var devicesSection: some View {
    VStack(spacing: 4) {
      HStack(spacing: 6) {
        Image(systemName: "chevron.right")
          .font(.caption2)
          .rotationEffect(.degrees(showDevices ? 90 : 0))
          .animation(.easeInOut(duration: 0.2), value: showDevices)
          .foregroundStyle(.secondary)
        Image(systemName: "speaker.wave.2.fill")
          .font(.caption)
          .foregroundStyle(Color.viperPurpleLight)
        Text("Devices")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(Color.viperPurpleLight)
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture { withAnimation { showDevices.toggle() } }

      if showDevices {
        VStack(spacing: 4) {
          ForEach(
            Array(state.deviceProfileList.enumerated()), id: \.offset
          ) { _, profile in
            let uid = profile["deviceUID"] as? String ?? ""
            let name = profile["deviceName"] as? String ?? "Unknown"
            let isHp = profile["isHeadphone"] as? Bool ?? true
            let lastMs = profile["lastConnected"] as? Int ?? 0
            let isActive = uid == state.currentDeviceUID
            let isBuiltIn = uid == "speaker" || uid.contains("BuiltIn")

            HStack(spacing: 6) {
              if isActive {
                Circle()
                  .fill(Color.green)
                  .frame(width: 6, height: 6)
              } else {
                Color.clear.frame(width: 6, height: 6)
              }
              Image(systemName: isHp ? "headphones" : "speaker.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(name)
                .font(.caption)
                .fontWeight(isActive ? .medium : .regular)
                .lineLimit(1)
              Spacer()
              if !isActive {
                Text(Self.timeAgo(ms: lastMs))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
              Button {
                showDeviceInfoUID = showDeviceInfoUID == uid ? nil : uid
              } label: {
                Image(systemName: "info.circle")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.borderless)
              .popover(
                isPresented: Binding(
                  get: { showDeviceInfoUID == uid },
                  set: { if !$0 { showDeviceInfoUID = nil } }
                ),
                arrowEdge: .bottom
              ) {
                deviceInfoPopover(
                  uid: uid, name: name, isHp: isHp,
                  lastMs: lastMs, isActive: isActive, isBuiltIn: isBuiltIn
                )
              }
            }
          }
        }
        .padding(.leading, 4)
      }
    }
    .sheet(item: Binding(
      get: { renamingDeviceUID.map { RenameItem(id: $0) } },
      set: { renamingDeviceUID = $0?.id }
    )) { item in
      VStack(spacing: 12) {
        Text("Rename Device")
          .font(.headline)
        TextField("Device name", text: $deviceRenameText)
          .textFieldStyle(.roundedBorder)
        HStack {
          Button("Cancel") { renamingDeviceUID = nil }
          Spacer()
          Button("Rename") {
            let trimmed = deviceRenameText.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
              state.renameDevice(item.id, newName: trimmed)
            }
            renamingDeviceUID = nil
          }
          .keyboardShortcut(.defaultAction)
          .disabled(deviceRenameText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
      .padding(20)
      .frame(width: 280)
    }
  }

  private func deviceInfoPopover(
    uid: String, name: String, isHp: Bool,
    lastMs: Int, isActive: Bool, isBuiltIn: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(name)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(Color.viperAccent)
        Button {
          showDeviceInfoUID = nil
          deviceRenameText = name
          renamingDeviceUID = uid
        } label: {
          Image(systemName: "pencil")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
      }

      statusRow(Text("UID"), value: Text(uid))
      statusRow(Text("Mode"), value: Text(isHp ? "Headphone" : "Speaker"))
      statusRow(
        Text("Last Connected"),
        value: Text(isActive ? "Active" : Self.formatDate(ms: lastMs)),
        color: isActive ? .green : nil
      )

      Divider()

      HStack(spacing: 12) {
        Button {
          state.loadDevicePreset(uid)
          showDeviceInfoUID = nil
        } label: {
          Label("Load", systemImage: "arrow.down.circle")
            .font(.caption)
            .foregroundStyle(Color.viperAccent.opacity(0.85))
        }
        .buttonStyle(.borderless)

        Button {
          state.saveDevicePreset(uid)
          showDeviceInfoUID = nil
        } label: {
          Label("Update", systemImage: "arrow.clockwise")
            .font(.caption)
            .foregroundStyle(Color.viperAccent.opacity(0.85))
        }
        .buttonStyle(.borderless)

        Button {
          state.deleteDeviceProfile(uid)
          showDeviceInfoUID = nil
        } label: {
          Label("Delete", systemImage: "trash")
            .font(.caption)
            .foregroundStyle(isActive || isBuiltIn ? Color.gray.opacity(0.4) : Color.red)
        }
        .buttonStyle(.borderless)
        .disabled(isActive || isBuiltIn)
      }
    }
    .padding(12)
    .frame(width: 280)
  }

  private static func formatDate(ms: Int) -> String {
    guard ms > 0 else { return "N/A" }
    let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd HH:mm"
    return fmt.string(from: date)
  }

  private struct RenameItem: Identifiable { let id: String }

  private static func timeAgo(ms: Int) -> String {
    guard ms > 0 else { return "" }
    let seconds = Int(Date().timeIntervalSince1970) - ms / 1000
    if seconds < 60 { return "just now" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m ago" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h ago" }
    let days = hours / 24
    return "\(days)d ago"
  }

  // MARK: - Output

  private var outputSection: some View {
    VStack(spacing: 6) {
      paramSlider(
        Text("Output Gain"), intValue: $state.outputVolume, range: 1 ... 200,
        displayFn: { v in
          let db = v > 0 ? 20.0 * log10(Double(v) / 100.0) : -99.9
          return String(format: "%.1fdB", db)
        }
      )

      paramSlider(
        Text("Output Pan"), intValue: $state.channelPan, range: -100 ... 100,
        displayFn: { v in "\(50 - v / 2):\(50 + v / 2)" }
      )

      paramSlider(
        Text("Threshold Limit"), intValue: $state.limiter, range: 30 ... 100,
        displayFn: { v in
          let db = v > 0 ? 20.0 * log10(Double(v) / 100.0) : -99.9
          return String(format: "%.1fdB", db)
        }
      )
    }
  }

  // MARK: - Effects

  private var effectSections: some View {
    VStack(spacing: 4) {
      agcSection
      compressorSection
      mbcSection
      ddcSection
      spectrumSection
      eqSection
      dynEqSection
      convolverSection
      surroundSection
      stereoImagerSection
      diffSurroundSection
      vheSection
      reverbSection
      dynamicSystemSection
      psychoacousticBassSection
      toggleOnlyHeader(
        Text("Tube Simulator (6N1J)"), icon: "music.note", isOn: $state.tubeSimulatorEnabled
      )
      bassSection
      bassMonoSection
      claritySection
      cureSection
      analogXSection
      lufsTargetingSection
      if state.fxType == .speaker {
        toggleOnlyHeader(
          Text("Speaker Optimization"), icon: "hifispeaker.fill",
          isOn: $state.speakerCorrectionEnabled
        )
      }
    }
  }

  // MARK: - EQ

  private var eqSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("FIR Equalizer"), icon: "slider.vertical.3", id: "eq", isOn: $state.equalizerEnabled
      )
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
      sectionHeader(Text("ViPER Bass"), icon: "waveform", id: "bass", isOn: $state.viperBassEnabled)
      if expandedSections.contains("bass") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperBassMode) {
            Text("Natural").tag(0)
            Text("Pure Bass+").tag(1)
            Text("Subwoofer").tag(2)
          }
          .pickerStyle(.segmented)
          if state.viperBassMode != 2 {
            paramSlider(
              Text("Frequency"), intValue: $state.viperBassFrequency, range: 0 ... 135,
              displayFn: { "\($0 + 15)Hz" }
            )
          }
          paramSlider(
            Text("Gain"), intValue: $state.viperBassGain, range: 50 ... 1000,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          toggleRow(Text("Fade-in"), isOn: $state.viperBassAntiPop)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var bassMonoSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("ViPER Bass Mono"), icon: "waveform", id: "bassMono", isOn: $state.viperBassMonoEnabled
      )
      if expandedSections.contains("bassMono") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperBassMonoMode) {
            Text("Natural").tag(0)
            Text("Pure Bass+").tag(1)
            Text("Subwoofer").tag(2)
          }
          .pickerStyle(.segmented)
          if state.viperBassMonoMode != 2 {
            paramSlider(
              Text("Frequency"), intValue: $state.viperBassMonoFrequency, range: 0 ... 135,
              displayFn: { "\($0 + 15)Hz" }
            )
          }
          paramSlider(
            Text("Gain"), intValue: $state.viperBassMonoGain, range: 50 ... 1000,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          toggleRow(Text("Fade-in"), isOn: $state.viperBassMonoAntiPop)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var claritySection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("ViPER Clarity"), icon: "ear", id: "clarity", isOn: $state.viperClarityEnabled
      )
      if expandedSections.contains("clarity") {
        VStack(spacing: 4) {
          Picker("Mode", selection: $state.viperClarityMode) {
            Text("Natural").tag(0)
            Text("OZone+").tag(1)
            Text("XHiFi").tag(2)
          }
          .pickerStyle(.segmented)
          paramSlider(
            Text("Gain"), intValue: $state.viperClarityGain, range: 0 ... 450,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var surroundSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Field Surround"), icon: "dot.radiowaves.left.and.right", id: "surround",
        isOn: $state.fieldSurroundEnabled
      )
      if expandedSections.contains("surround") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Widening"), intValue: $state.fieldSurroundWidening, range: 0 ... 8,
            displayFn: { "\($0)" }
          )
          steppedSlider(
            Text("Mid Image"), value: $state.fieldSurroundMidImage, maxIndex: 10, steps: 9
          )
          steppedSlider(Text("Depth"), value: $state.fieldSurroundDepth, maxIndex: 10, steps: 9)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var diffSurroundSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Differential Surround"), icon: "person.wave.2", id: "diffsurr",
        isOn: $state.diffSurroundEnabled
      )
      if expandedSections.contains("diffsurr") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Delay"), intValue: $state.diffSurroundDelay, range: 1 ... 20,
            displayFn: { "\($0) ms" }
          )
          toggleRow(Text("Reverse"), isOn: $state.diffSurroundReverse)
          paramSlider(
            Text("Wet/Dry"), intValue: $state.diffSurroundWetDryMix, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("LP Cutoff"),
            intValue: Binding(get: { state.diffSurroundLpCutoff }, set: { state.diffSurroundLpCutoff = (($0 + 2) / 5) * 5 }),
            range: 0 ... 20000,
            displayFn: { $0 == 0 ? "Off" : "\($0) Hz" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var reverbSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Reverberation"), icon: "aqi.medium", id: "reverb", isOn: $state.reverberationEnabled
      )
      if expandedSections.contains("reverb") {
        VStack(spacing: 4) {
          steppedSlider(
            Text("Room Size"), value: $state.reverberationRoomSize, maxIndex: 10, steps: 9
          )
          steppedSlider(Text("Width"), value: $state.reverberationRoomWidth, maxIndex: 10, steps: 9)
          steppedSlider(
            Text("Dampening"), value: $state.reverberationRoomDampening, maxIndex: 10, steps: 9
          )
          paramSlider(
            Text("Wet"), intValue: $state.reverberationWetSignal, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("Dry"), intValue: $state.reverberationDrySignal, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var dynamicSystemSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Dynamic System"), icon: "hifispeaker.fill", id: "dynsys",
        isOn: $state.dynamicSystemEnabled
      )
      if expandedSections.contains("dynsys") {
        VStack(spacing: 4) {
          HStack {
            Picker("Device", selection: $state.dynamicSystemDevice) {
              ForEach(0 ..< ViPERState.dynamicSystemDevices.count, id: \.self) { i in
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
            Text("Strength"), intValue: $state.dynamicSystemStrength, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("X Low Freq"),
            intValue: Binding(get: { state.dsXLow }, set: { state.dsXLow = (($0 + 2) / 5) * 5 }),
            range: 0 ... 2400, displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("X High Freq"),
            intValue: Binding(get: { state.dsXHigh }, set: { state.dsXHigh = (($0 + 2) / 5) * 5 }),
            range: 0 ... 12000, displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Y Low Freq"),
            intValue: Binding(get: { state.dsYLow }, set: { state.dsYLow = (($0 + 2) / 5) * 5 }),
            range: 0 ... 200, displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Y High Freq"),
            intValue: Binding(get: { state.dsYHigh }, set: { state.dsYHigh = (($0 + 2) / 5) * 5 }),
            range: 0 ... 300, displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Side Gain Lo"), intValue: $state.dsSideGainLow, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("Side Gain Hi"), intValue: $state.dsSideGainHigh, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var analogXSection: some View {
    VStack(spacing: 4) {
      sectionHeader(Text("AnalogX"), icon: "memorychip", id: "analogx", isOn: $state.analogXEnabled)
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
        Text("Auditory System Protection"), icon: "cross.case.fill", id: "cure",
        isOn: $state.cureEnabled
      )
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
        Text("FET Compressor"), icon: "rectangle.compress.vertical", id: "comp",
        isOn: $state.fetCompressorEnabled
      )
      if expandedSections.contains("comp") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Threshold"), intValue: $state.fetCompressorThreshold, range: -48 ... 0,
            displayFn: { "\($0) dB" }
          )
          paramSlider(
            Text("Ratio"), intValue: $state.fetCompressorRatio, range: 0 ... 200,
            displayFn: { String(format: "%.1f", Double($0) / 100.0) }
          )
          toggleRow(Text("Auto Knee"), isOn: $state.fetCompressorAutoKnee)
          paramSlider(
            Text("Knee"), intValue: $state.fetCompressorKnee, range: 0 ... 12,
            displayFn: { "\($0) dB" }, enabled: !state.fetCompressorAutoKnee
          )
          paramSlider(
            Text("Knee Multi"), intValue: $state.fetCompressorKneeMulti, range: 0 ... 400,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          toggleRow(Text("Auto Gain"), isOn: $state.fetCompressorAutoGain)
          paramSlider(
            Text("Gain"), intValue: $state.fetCompressorGain, range: 0 ... 24,
            displayFn: { "\($0) dB" }, enabled: !state.fetCompressorAutoGain
          )
          toggleRow(Text("Auto Attack"), isOn: $state.fetCompressorAutoAttack)
          paramSlider(
            Text("Attack"), intValue: $state.fetCompressorAttack, range: 1 ... 100,
            displayFn: { "\($0) ms" }, enabled: !state.fetCompressorAutoAttack
          )
          paramSlider(
            Text("Max Attack"), intValue: $state.fetCompressorMaxAttack, range: 1 ... 100,
            displayFn: { "\($0) ms" }
          )
          toggleRow(Text("Auto Release"), isOn: $state.fetCompressorAutoRelease)
          paramSlider(
            Text("Release"), intValue: $state.fetCompressorRelease, range: 5 ... 500,
            displayFn: { "\($0) ms" }, enabled: !state.fetCompressorAutoRelease
          )
          paramSlider(
            Text("Max Release"), intValue: $state.fetCompressorMaxRelease, range: 5 ... 500,
            displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Crest"), intValue: $state.fetCompressorCrest, range: 5 ... 300,
            displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Adapt"), intValue: $state.fetCompressorAdapt, range: 0 ... 200,
            displayFn: { "\($0)%" }
          )
          toggleRow(Text("No Clip"), isOn: $state.fetCompressorNoClip)
        }
        .padding(.leading, 4)
      }
    }
  }

  private var vheSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Headphone Surround+"), icon: "headphones", id: "vhe", isOn: $state.vheEnabled
      )
      if expandedSections.contains("vhe") {
        steppedSlider(Text("Quality"), value: $state.vheQuality, maxIndex: 4, steps: 3)
          .padding(.leading, 4)
      }
    }
  }

  private var spectrumSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Spectrum Extension"), icon: "water.waves", id: "vse",
        isOn: $state.spectrumExtensionEnabled
      )
      if expandedSections.contains("vse") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Strength"), intValue: $state.spectrumExtensionBark, range: 2200 ... 8200,
            displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Exciter"), intValue: $state.spectrumExtensionBarkReconstruct, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var agcSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Playback Gain Control"), icon: "chart.line.uptrend.xyaxis", id: "agc",
        isOn: $state.playbackGainEnabled
      )
      if expandedSections.contains("agc") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Strength"), intValue: $state.playbackGainStrength, range: 50 ... 300,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          paramSlider(
            Text("Max Gain"), intValue: $state.playbackGainMaxGain, range: 100 ... 1000,
            displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          paramSlider(
            Text("Threshold"), intValue: $state.playbackGainOutputThreshold, range: 30 ... 100,
            displayFn: { v in
              let db = v > 0 ? 20.0 * log10(Double(v) / 100.0) : -99.9
              return String(format: "%.1fdB", db)
            }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  private var ddcSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("ViPER-DDC"), icon: "slider.horizontal.3", id: "ddc", isOn: $state.ddcEnabled
      )
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
        Text("Convolver"), icon: "waveform.circle", id: "conv", isOn: $state.convolutionEnabled
      )
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
            Text("Cross Ch."), intValue: $state.convolutionCrossChannel, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Multiband Compressor

  private static let mbcBandNames = ["Sub", "Low", "Mid", "Pres", "Air"]

  private var mbcSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Multiband Compressor"), icon: "waveform.badge.plus", id: "mbc",
        isOn: $state.mbcEnabled
      )
      if expandedSections.contains("mbc") {
        VStack(spacing: 4) {
          Picker("Band", selection: $state.mbcSelectedBand) {
            ForEach(0 ..< 5, id: \.self) { i in
              Text(Self.mbcBandNames[i]).tag(i)
            }
          }
          .pickerStyle(.segmented)

          let b = state.mbcSelectedBand
          let lowFreq = b == 0 ? 20 : (state.mbcCrossovers[safe: b - 1] ?? 20)
          let highFreq = b < 4 ? (state.mbcCrossovers[safe: b] ?? 20000) : 20000
          Text("\(lowFreq) - \(b < 4 ? "\(highFreq)" : "20000+") Hz")
            .font(.caption2)
            .foregroundStyle(.secondary)

          toggleRow(
            Text("Band Enable"),
            isOn: Binding(
              get: { state.mbcBandEnables[safe: b] ?? true },
              set: { state.mbcBandEnables[b] = $0; state.dispatchMbcBand(b) }
            )
          )
          paramSlider(
            Text("Threshold"),
            intValue: Binding(
              get: { state.mbcThresholds[safe: b] ?? -18 },
              set: { state.mbcThresholds[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: -48 ... 0, displayFn: { "\($0) dB" }
          )
          paramSlider(
            Text("Ratio"),
            intValue: Binding(
              get: { state.mbcRatios[safe: b] ?? 50 },
              set: { state.mbcRatios[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 0 ... 200, displayFn: { String(format: "%.1f", Double($0) / 100.0) }
          )
          paramSlider(
            Text("Knee"),
            intValue: Binding(
              get: { state.mbcKnees[safe: b] ?? 0 },
              set: { state.mbcKnees[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 0 ... 12, displayFn: { "\($0) dB" }
          )
          toggleRow(
            Text("Auto Gain"),
            isOn: Binding(
              get: { state.mbcAutoGains[safe: b] ?? true },
              set: { state.mbcAutoGains[b] = $0; state.dispatchMbcBand(b) }
            )
          )
          paramSlider(
            Text("Gain"),
            intValue: Binding(
              get: { state.mbcGains[safe: b] ?? 24 },
              set: { state.mbcGains[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 0 ... 24, displayFn: { "\($0) dB" },
            enabled: !(state.mbcAutoGains[safe: b] ?? true)
          )
          toggleRow(
            Text("Auto Attack"),
            isOn: Binding(
              get: { state.mbcAutoAttacks[safe: b] ?? true },
              set: { state.mbcAutoAttacks[b] = $0; state.dispatchMbcBand(b) }
            )
          )
          paramSlider(
            Text("Attack"),
            intValue: Binding(
              get: { state.mbcAttacks[safe: b] ?? 1 },
              set: { state.mbcAttacks[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 1 ... 100, displayFn: { "\($0) ms" },
            enabled: !(state.mbcAutoAttacks[safe: b] ?? true)
          )
          toggleRow(
            Text("Auto Release"),
            isOn: Binding(
              get: { state.mbcAutoReleases[safe: b] ?? true },
              set: { state.mbcAutoReleases[b] = $0; state.dispatchMbcBand(b) }
            )
          )
          paramSlider(
            Text("Release"),
            intValue: Binding(
              get: { state.mbcReleases[safe: b] ?? 100 },
              set: { state.mbcReleases[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 5 ... 500, displayFn: { "\($0) ms" },
            enabled: !(state.mbcAutoReleases[safe: b] ?? true)
          )
          toggleRow(
            Text("Auto Knee"),
            isOn: Binding(
              get: { state.mbcAutoKnees[safe: b] ?? true },
              set: { state.mbcAutoKnees[b] = $0; state.dispatchMbcBand(b) }
            )
          )
          paramSlider(
            Text("Knee Multi"),
            intValue: Binding(
              get: { state.mbcKneeMultis[safe: b] ?? 0 },
              set: { state.mbcKneeMultis[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 0 ... 400, displayFn: { String(format: "%.1fx", Double($0) / 100.0) }
          )
          paramSlider(
            Text("Max Attack"),
            intValue: Binding(
              get: { state.mbcMaxAttacks[safe: b] ?? 44 },
              set: { state.mbcMaxAttacks[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 1 ... 100, displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Max Release"),
            intValue: Binding(
              get: { state.mbcMaxReleases[safe: b] ?? 200 },
              set: { state.mbcMaxReleases[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 5 ... 500, displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Crest"),
            intValue: Binding(
              get: { state.mbcCrests[safe: b] ?? 100 },
              set: { state.mbcCrests[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 5 ... 300, displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Adapt"),
            intValue: Binding(
              get: { state.mbcAdapts[safe: b] ?? 50 },
              set: { state.mbcAdapts[b] = $0; state.dispatchMbcBand(b) }
            ),
            range: 0 ... 200
          )
          toggleRow(
            Text("No Clip"),
            isOn: Binding(
              get: { state.mbcNoClips[safe: b] ?? true },
              set: { state.mbcNoClips[b] = $0; state.dispatchMbcBand(b) }
            )
          )

          if b < 4 {
            paramSlider(
              Text("Crossover"),
              intValue: Binding(
                get: { state.mbcCrossovers[safe: b] ?? 500 },
                set: { let v = (($0 + 2) / 5) * 5; state.mbcCrossovers[b] = v; state.dispatchMbcCrossover(b) }
              ),
              range: 20 ... 20000, displayFn: { "\($0) Hz" }
            )
          }
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Dynamic EQ

  private var dynEqSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Dynamic EQ"), icon: "waveform.path.ecg", id: "dyneq",
        isOn: $state.dynEqEnabled
      )
      if expandedSections.contains("dyneq") {
        VStack(spacing: 4) {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
              ForEach(0 ..< state.dynEqBandCount, id: \.self) { i in
                let freq = state.dynEqFreqs[safe: i] ?? 1000
                let label: String = {
                  if freq >= 1000 {
                    let k = Double(freq) / 1000.0
                    return k == k.rounded(.down) ? "\(Int(k))kHz" : String(format: "%.1fkHz", k)
                  }
                  return "\(freq)Hz"
                }()
                Button(action: { state.dynEqSelectedBand = i }) {
                  HStack(spacing: 2) {
                    Text(label)
                      .font(.caption)
                      .lineLimit(1)
                      .fixedSize()
                    if state.dynEqBandCount > 1 {
                      Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                          dynEqBandToDelete = i
                        }
                    }
                  }
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(
                    state.dynEqSelectedBand == i
                      ? Color.accentColor.opacity(0.2)
                      : Color.clear
                  )
                  .cornerRadius(4)
                }
                .buttonStyle(.plain)
              }
              if state.dynEqBandCount < 8,
                 (state.dynEqFreqs.last ?? 0) < 19990
              {
                Button(action: { state.addDynEqBand() }) {
                  Image(systemName: "plus")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .confirmationDialog(
            "Delete this band?",
            isPresented: Binding(
              get: { dynEqBandToDelete != nil },
              set: { if !$0 { dynEqBandToDelete = nil } }
            ),
            titleVisibility: .visible
          ) {
            Button("Delete", role: .destructive) {
              if let idx = dynEqBandToDelete {
                state.removeDynEqBand(at: idx)
                dynEqBandToDelete = nil
              }
            }
            Button("Cancel", role: .cancel) {
              dynEqBandToDelete = nil
            }
          }

          let b = min(state.dynEqSelectedBand, state.dynEqBandCount - 1)
          let minFreq = b > 0 ? (state.dynEqFreqs[safe: b - 1] ?? 20) + 5 : 20
          let maxFreq = b < state.dynEqBandCount - 1
            ? (state.dynEqFreqs[safe: b + 1] ?? 20000) - 5 : 20000
          paramSlider(
            Text("Frequency"),
            intValue: Binding(
              get: { state.dynEqFreqs[safe: b] ?? 1000 },
              set: { let v = (($0 + 2) / 5) * 5; state.dynEqFreqs[b] = v; state.dispatchDynEqBand(b) }
            ),
            range: minFreq ... maxFreq, displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Q"),
            intValue: Binding(
              get: { state.dynEqQs[safe: b] ?? 150 },
              set: { state.dynEqQs[b] = $0; state.dispatchDynEqBand(b) }
            ),
            range: 50 ... 800, displayFn: { String(format: "%.1f", Double($0) / 100.0) }
          )
          paramSlider(
            Text("Gain"),
            intValue: Binding(
              get: { state.dynEqGains[safe: b] ?? 0 },
              set: { state.dynEqGains[b] = $0; state.dispatchDynEqBand(b) }
            ),
            range: -120 ... 120, displayFn: { String(format: "%.1f dB", Double($0) / 10.0) }
          )
          paramSlider(
            Text("Threshold"),
            intValue: Binding(
              get: { state.dynEqThresholds[safe: b] ?? -250 },
              set: { state.dynEqThresholds[b] = $0; state.dispatchDynEqBand(b) }
            ),
            range: -800 ... 0, displayFn: { "\($0 / 10) dB" }
          )
          paramSlider(
            Text("Attack"),
            intValue: Binding(
              get: { state.dynEqAttacks[safe: b] ?? 10 },
              set: { state.dynEqAttacks[b] = $0; state.dispatchDynEqBand(b) }
            ),
            range: 1 ... 100, displayFn: { "\($0) ms" }
          )
          paramSlider(
            Text("Release"),
            intValue: Binding(
              get: { state.dynEqReleases[safe: b] ?? 100 },
              set: { state.dynEqReleases[b] = $0; state.dispatchDynEqBand(b) }
            ),
            range: 10 ... 500, displayFn: { "\($0) ms" }
          )
          Picker(
            "Filter",
            selection: Binding(
              get: { state.dynEqFilterTypes[safe: b] ?? 0 },
              set: { state.dynEqFilterTypes[b] = $0; state.dispatchDynEqBand(b) }
            )
          ) {
            Text("Peak").tag(0)
            Text("Low Shelf").tag(1)
            Text("High Shelf").tag(2)
          }
          .pickerStyle(.segmented)
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Stereo Imager

  private var stereoImagerSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Stereo Imager"), icon: "arrow.left.and.right", id: "stereoimg",
        isOn: $state.stereoImgEnabled
      )
      if expandedSections.contains("stereoimg") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Low Width"), intValue: $state.stereoImgLowWidth, range: 0 ... 200,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("Mid Width"), intValue: $state.stereoImgMidWidth, range: 0 ... 200,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("High Width"), intValue: $state.stereoImgHighWidth, range: 0 ... 200,
            displayFn: { "\($0)%" }
          )
          paramSlider(
            Text("Low X-over"),
            intValue: Binding(get: { state.stereoImgLowCrossover }, set: { state.stereoImgLowCrossover = (($0 + 2) / 5) * 5 }),
            range: 80 ... 400,
            displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("High X-over"),
            intValue: Binding(get: { state.stereoImgHighCrossover }, set: { state.stereoImgHighCrossover = (($0 + 2) / 5) * 5 }),
            range: 2000 ... 8000,
            displayFn: { "\($0) Hz" }
          )
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - LUFS Targeting

  private var lufsTargetingSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("LUFS Targeting"), icon: "gauge.with.needle", id: "lufs",
        isOn: $state.lufsEnabled
      )
      if expandedSections.contains("lufs") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Target"), intValue: $state.lufsTarget, range: 80 ... 240,
            displayFn: { String(format: "%.1f LUFS", Double($0) / -10.0) }
          )
          paramSlider(
            Text("Max Gain"), intValue: $state.lufsMaxGain, range: 0 ... 120,
            displayFn: { String(format: "%.1f dB", Double($0) / 10.0) }
          )
          Picker("Speed", selection: $state.lufsSpeed) {
            Text("Slow").tag(0)
            Text("Medium").tag(1)
            Text("Fast").tag(2)
          }
          .pickerStyle(.segmented)
        }
        .padding(.leading, 4)
      }
    }
  }

  // MARK: - Psychoacoustic Bass

  private var psychoacousticBassSection: some View {
    VStack(spacing: 4) {
      sectionHeader(
        Text("Psychoacoustic Bass"), icon: "speaker.wave.3", id: "psychobass",
        isOn: $state.psychoBassEnabled
      )
      if expandedSections.contains("psychobass") {
        VStack(spacing: 4) {
          paramSlider(
            Text("Cutoff"), intValue: $state.psychoBassCutoff, range: 60 ... 150,
            displayFn: { "\($0) Hz" }
          )
          paramSlider(
            Text("Intensity"), intValue: $state.psychoBassIntensity, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
          Picker("Harmonic", selection: $state.psychoBassHarmonicOrder) {
            Text("2nd").tag(2)
            Text("3rd").tag(3)
            Text("4th").tag(4)
            Text("5th").tag(5)
          }
          .pickerStyle(.segmented)
          paramSlider(
            Text("Orig. Level"), intValue: $state.psychoBassOriginalLevel, range: 0 ... 100,
            displayFn: { "\($0)%" }
          )
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

  // MARK: - Engine Status

  private var engineStatusPopover: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("ViPER4Mac")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(Color.viperAccent)

      statusRow(
        Text("App Version"),
        value: Text(
          Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "?"
        )
      )
      statusRow(
        Text("DSP Version"),
        value: Text(state.dspVersion)
      )
      statusRow(
        Text("Streaming"),
        value: Text(state.isProcessing ? "Active" : "Inactive"),
        color: state.isProcessing ? .green : .orange
      )

      Divider()

      statusRow(
        Text("Audio Mode"),
        value: Text(state.fxType == .headphone ? "Headphone" : "Speaker")
      )
      statusRow(
        Text("Sample Rate"),
        value: Text(
          state.currentSampleRate > 0
            ? "\(state.currentSampleRate) Hz" : "N/A"
        )
      )
      statusRow(
        Text("Output Device"),
        value: Text(state.outputDeviceName)
      )
    }
    .padding(12)
    .frame(width: 220)
  }

  private func statusRow(_ label: Text, value: Text, color: Color? = nil) -> some View {
    HStack {
      label
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      HStack(spacing: 4) {
        if let color {
          Circle()
            .fill(color)
            .frame(width: 6, height: 6)
        }
        value
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
      }
    }
  }

  // MARK: - Helpers

  private func toggleRow(_ label: Text, isOn: Binding<Bool>) -> some View {
    HStack {
      label
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
    _ label: Text, value: Binding<Int>, maxIndex: Int,
    steps _: Int, label displayLabel: String? = nil
  ) -> some View {
    let floatBinding = Binding<Float>(
      get: { Float(value.wrappedValue) },
      set: { value.wrappedValue = Int($0.rounded()) }
    )
    return HStack(spacing: 6) {
      label
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 65, alignment: .leading)
      Slider(value: floatBinding, in: 0 ... Float(maxIndex), step: 1)
        .tint(.viperPurple)
      Text(displayLabel ?? "\(value.wrappedValue)")
        .font(.caption)
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
        .frame(minWidth: 48, alignment: .trailing)
    }
  }

  private func paramSlider(
    _ label: Text, intValue: Binding<Int>, range: ClosedRange<Int>,
    unit: String = "", displayFn: ((Int) -> String)? = nil,
    enabled: Bool = true
  ) -> some View {
    let floatBinding = Binding<Float>(
      get: { Float(intValue.wrappedValue) },
      set: { intValue.wrappedValue = Int($0) }
    )
    let display = displayFn?(intValue.wrappedValue) ?? "\(intValue.wrappedValue)\(unit)"
    return HStack(spacing: 6) {
      label
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 65, alignment: .leading)
      Slider(value: floatBinding, in: Float(range.lowerBound) ... Float(range.upperBound))
        .tint(.viperPurple)
        .disabled(!enabled)
      Text(display)
        .font(.caption)
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
        .frame(minWidth: 48, alignment: .trailing)
    }
    .opacity(enabled ? 1.0 : 0.5)
  }
}
