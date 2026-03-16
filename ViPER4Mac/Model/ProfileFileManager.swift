import Foundation

private let logger = AppLogger(category: "ProfileFileManager")

final class ProfileFileManager {
  static let shared = ProfileFileManager()

  private let appSupportDir: URL

  private init() {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first!
    appSupportDir = base.appendingPathComponent("ViPER4Mac", isDirectory: true)
    ensureDirectories()
  }

  private func ensureDirectories() {
    let fm = FileManager.default
    for sub in ["DDC", "Kernel", "Preset", "EQPreset", "DynSysPreset"] {
      let dir = appSupportDir.appendingPathComponent(sub, isDirectory: true)
      if !fm.fileExists(atPath: dir.path) {
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
      }
    }
  }

  private func directory(for type: FileType) -> URL {
    switch type {
    case .ddc: return appSupportDir.appendingPathComponent("DDC", isDirectory: true)
    case .kernel: return appSupportDir.appendingPathComponent("Kernel", isDirectory: true)
    case .preset: return appSupportDir.appendingPathComponent("Preset", isDirectory: true)
    case .eqPreset: return appSupportDir.appendingPathComponent("EQPreset", isDirectory: true)
    case .dynSysPreset:
      return appSupportDir.appendingPathComponent("DynSysPreset", isDirectory: true)
    }
  }

  enum FileType: CustomStringConvertible {
    case ddc
    case kernel
    case preset
    case eqPreset
    case dynSysPreset

    var description: String {
      switch self {
      case .ddc: return "DDC"
      case .kernel: return "Kernel"
      case .preset: return "Preset"
      case .eqPreset: return "EQPreset"
      case .dynSysPreset: return "DynSysPreset"
      }
    }
  }

  func importFile(from sourceURL: URL, type: FileType) -> String? {
    let dest = directory(for: type).appendingPathComponent(sourceURL.lastPathComponent)
    let fm = FileManager.default
    do {
      if fm.fileExists(atPath: dest.path) {
        try fm.removeItem(at: dest)
      }
      try fm.copyItem(at: sourceURL, to: dest)
      logger.info("Imported \(type): \(sourceURL.lastPathComponent)")
      return sourceURL.lastPathComponent
    } catch {
      logger.error("Import failed: \(error.localizedDescription)")
      return nil
    }
  }

  func listFiles(type: FileType) -> [String] {
    let dir = directory(for: type)
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(atPath: dir.path) else { return [] }
    let ext: Set<String>
    switch type {
    case .ddc: ext = ["vdc"]
    case .kernel: ext = ["wav", "irs"]
    case .preset: ext = ["json"]
    case .eqPreset: ext = ["json"]
    case .dynSysPreset: ext = ["json"]
    }
    return
      contents
      .filter { ext.contains(($0 as NSString).pathExtension.lowercased()) }
      .sorted()
  }

  func fileURL(name: String, type: FileType) -> URL {
    directory(for: type).appendingPathComponent(name)
  }

  func deleteFile(name: String, type: FileType) {
    let url = fileURL(name: name, type: type)
    try? FileManager.default.removeItem(at: url)
    logger.info("Deleted \(type): \(name)")
  }
}
