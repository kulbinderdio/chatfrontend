import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep a strong reference to the status item
    private var statusItem: NSStatusItem?
    
    // Keep a reference to the main window
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the activation policy to accessory to keep the app running without a dock icon
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Create a dummy status item to keep the app running
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem?.isVisible = false
        
        // Create a hidden window to keep the app running
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.orderOut(nil)
        self.mainWindow = window
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }
    
    @objc func windowWillClose(_ notification: Notification) {
        // Prevent the app from quitting when a window is closed
        if let window = notification.object as? NSWindow {
            // If it's not the main window, just let it close
            if window !== mainWindow {
                print("Window will close: \(window)")
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Prevent the app from terminating when all windows are closed
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources before termination
        print("Application will terminate")
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Only terminate when explicitly requested by the user via Quit menu item
        if let event = NSApp.currentEvent, event.type == .keyDown,
           event.modifierFlags.contains(.command), event.keyCode == 12 { // 'q' key
            return .terminateNow
        }
        
        // For all other cases, prevent termination
        return .terminateCancel
    }
}
