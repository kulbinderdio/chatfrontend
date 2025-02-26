import SwiftUI
import AppKit
import Combine

class MenuBarManager: NSObject, ObservableObject, NSWindowDelegate {
    @Published private(set) var isPopoverShown: Bool = false
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var settingsWindow: NSWindow?
    
    // Expose the popover window for document picker
    var popoverWindow: NSWindow? {
        return popover?.contentViewController?.view.window
    }
    
    // References to managers and view models needed for settings
    private var settingsViewModel: SettingsViewModel?
    private var profileManager: ProfileManager?
    
    func setupMenuBar<T: View>(with rootView: T, settingsViewModel: SettingsViewModel, profileManager: ProfileManager) {
        // Store references to managers and view models
        self.settingsViewModel = settingsViewModel
        self.profileManager = profileManager
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 800, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: rootView)
        self.popover = popover
        
        // Create the status item
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Chat")
            button.action = #selector(togglePopover(_:))
            button.target = self
            
            // Add a right-click menu
            let menu = NSMenu()
            
            let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            quitItem.target = NSApplication.shared
            menu.addItem(quitItem)
            
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem
        
        // Create event monitor to detect clicks outside the popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let popover = self.popover else { return }
            
            if popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        
        // Set up menu
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let newChatItem = NSMenuItem(title: "New Chat", action: #selector(newChat), keyEquivalent: "n")
        newChatItem.target = self
        menu.addItem(newChatItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        // Check if it's a right-click event
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            // Show the menu on right-click
            statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: button.bounds.midX, y: button.bounds.midY), in: button)
            return
        }
        
        // Handle left-click event
        if popover.isShown {
            closePopover(sender)
        } else {
            statusItem?.menu = nil
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func newChat() {
        // Post notification to create new chat
        NotificationCenter.default.post(name: Notification.Name("NewChatRequested"), object: nil)
        
        // Show popover
        if let button = statusItem?.button, let popover = popover, !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func openSettings() {
        guard let settingsViewModel = settingsViewModel, let profileManager = profileManager else {
            print("Error: settingsViewModel or profileManager is nil")
            return
        }
        
        // Create the settings view
        let settingsView = SettingsView(
            viewModel: settingsViewModel,
            profileManager: profileManager
        )
        
        // Create a hosting controller with a fixed size
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.preferredContentSize = NSSize(width: 800, height: 600)
        
        // Create a window to host the settings view
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Set this property to ensure the window doesn't cause the app to terminate
        window.isReleasedWhenClosed = false
        window.center()
        window.title = "Settings"
        window.contentMinSize = NSSize(width: 800, height: 600)
        
        // Set the content view controller
        window.contentViewController = hostingController
        
        // Make the window key and bring it to front
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Store a reference to the window
        self.settingsWindow = window
        
        // Set the window's delegate to self to handle window closing
        window.delegate = self
    }
    
    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        setupMenu()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Check if the closing window is the settings window
        if let closingWindow = notification.object as? NSWindow,
           closingWindow === settingsWindow {
            // Clear the reference to the settings window
            settingsWindow = nil
        }
    }
}
