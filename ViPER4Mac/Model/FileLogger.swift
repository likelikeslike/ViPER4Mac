import Foundation

final class FileLogger {
  static let shared = FileLogger()

  private let queue = DispatchQueue(label: "com.viper4mac.filelogger", qos: .utility)
  private var fileHandle: FileHandle?
  private let maxFileSize: UInt64 = 2 * 1024 * 1024
  private let logURL: URL
  private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  private init() {
    let logsDir = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Logs/ViPER4Mac")
    try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    logURL = logsDir.appendingPathComponent("viper.log")
    openLogFile()
  }

  private func openLogFile() {
    if !FileManager.default.fileExists(atPath: logURL.path) {
      FileManager.default.createFile(atPath: logURL.path, contents: nil)
    }
    fileHandle = try? FileHandle(forWritingTo: logURL)
    fileHandle?.seekToEndOfFile()
  }

  private func rotateIfNeeded() {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: logURL.path),
      let size = attrs[.size] as? UInt64,
      size > maxFileSize
    else { return }
    fileHandle?.closeFile()
    let oldURL = logURL.deletingLastPathComponent().appendingPathComponent("viper.old.log")
    try? FileManager.default.removeItem(at: oldURL)
    try? FileManager.default.moveItem(at: logURL, to: oldURL)
    openLogFile()
  }

  private func writeRaw(_ text: String) {
    queue.async { [weak self] in
      guard let self, let data = text.data(using: .utf8) else { return }
      self.rotateIfNeeded()
      self.fileHandle?.write(data)
    }
  }

  func log(_ level: String, category: String, _ message: String) {
    let timestamp = dateFormatter.string(from: Date())
    let line = "\(timestamp) [\(category)][\(level)] \(message)\n"
    writeRaw(line)
  }
}

struct AppLogger {
  let category: String

  func debug(_ message: String) {
    FileLogger.shared.log("DEBUG", category: category, message)
  }

  func info(_ message: String) {
    FileLogger.shared.log("INFO", category: category, message)
  }

  func warning(_ message: String) {
    FileLogger.shared.log("WARN", category: category, message)
  }

  func error(_ message: String) {
    FileLogger.shared.log("ERROR", category: category, message)
  }
}
