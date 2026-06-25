import SwiftUI

@main
struct MacClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("MacClipboard", systemImage: "doc.on.clipboard") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run purely in the background / menu bar. Dock icon will be hidden via Info.plist anyway,
        // but it's good to be explicit here if Info.plist parsing fails.
        NSApp.setActivationPolicy(.accessory)
    }
}
