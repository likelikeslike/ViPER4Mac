import SwiftUI

@main
struct ViPER4MacApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {}
  }
}
