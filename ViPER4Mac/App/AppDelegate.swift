import AppKit
import SwiftUI

private let logger = AppLogger(category: "AppDelegate")

class AppDelegate: NSObject, NSApplicationDelegate {
  static var shared: AppDelegate?
  private var statusItem: NSStatusItem?
  private(set) var popover: NSPopover?

  func applicationDidFinishLaunching(_ notification: Notification) {
    AppDelegate.shared = self
    logger.info("applicationDidFinishLaunching")
    AudioEngine.shared.start()
    setupEngineDeviceCallback()
    setupStatusItem()
    setupOutputDetector()
  }

  func applicationWillTerminate(_ notification: Notification) {
    ViPERState.shared.saveSettings()
    AudioOutputDetector.shared.stop()
    AudioEngine.shared.stop()
  }

  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    if let button = statusItem?.button {
      button.image = makeViperIcon()
      button.action = #selector(togglePopover)
      button.target = self
    }

    let pop = NSPopover()
    pop.contentSize = NSSize(width: 340, height: 560)
    pop.behavior = .transient
    pop.contentViewController = NSHostingController(rootView: PopoverContentView())
    popover = pop
  }

  private func setupOutputDetector() {
    let detector = AudioOutputDetector.shared
    detector.onOutputTypeChanged = { newType in
      ViPERState.shared.handleDeviceTypeChange(newType)
    }
    detector.start()
  }

  private func setupEngineDeviceCallback() {
    AudioEngine.shared.onOutputDeviceChanged = {
      AudioOutputDetector.shared.checkAndNotify()
      ViPERState.shared.refreshDriverStatus()
    }
  }
  @objc private func togglePopover() {
    guard let popover, let button = statusItem?.button else { return }
    if popover.isShown {
      popover.performClose(nil)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  private func makeViperIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
      let path = NSBezierPath()
      let sx = rect.width / 48.0
      let sy = rect.height / 48.0
      let ox: CGFloat = 4.0 * sx
      let flipY = { (y: CGFloat) -> CGFloat in rect.height - y * sy }

      path.move(to: NSPoint(x: ox + 35.56 * sx, y: flipY(8)))
      path.line(to: NSPoint(x: ox + 27.41 * sx, y: flipY(27.72)))
      path.line(to: NSPoint(x: ox + 19.29 * sx, y: flipY(8.01)))
      path.line(to: NSPoint(x: ox + 19.27 * sx, y: flipY(8.03)))
      path.line(to: NSPoint(x: ox + 8.0 * sx, y: flipY(8.03)))
      path.line(to: NSPoint(x: ox + 24.09 * sx, y: flipY(44.01)))
      path.line(to: NSPoint(x: ox + 40.0 * sx, y: flipY(8.04)))
      path.close()

      NSColor.black.setFill()
      path.fill()
      return true
    }
    image.isTemplate = true
    return image
  }
}
