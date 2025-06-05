import SwiftUI
import SwiftKEF
import AsyncHTTPClient
import KeyboardShortcuts

@main
struct KefirMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState ?? AppState())
                .frame(width: CGFloat(Constants.UI.settingsWidth), height: CGFloat(Constants.UI.settingsHeight))
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var appState: AppState!
    var miniPlayerWindowController: MiniPlayerWindowController?
    
    func applicationWillTerminate(_ notification: Notification) {
        Task {
            await appState?.cleanup()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
        
        // Create app state
        appState = AppState()
        
        // Set up mini player keyboard shortcut
        KeyboardShortcuts.onKeyUp(for: .toggleMiniPlayer) { [weak self] in
            Task { @MainActor in
                self?.toggleMiniPlayer()
            }
        }
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: Constants.Symbols.speaker, accessibilityDescription: Constants.App.name)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: PopoverView(appState: appState, appDelegate: self))
        popover.behavior = .transient
        popover.animates = true
        
        // Monitor window notifications to handle settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }
    
    @objc func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow,
           window.title == "Settings" || window.title.contains("Preferences") {
            // Return to accessory mode when settings window closes
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    @MainActor @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Activate app to ensure popover gets focus
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func showMiniPlayer() {
        DispatchQueue.main.async { [weak self] in
            if self?.miniPlayerWindowController == nil {
                self?.miniPlayerWindowController = MiniPlayerWindowController(appState: self?.appState ?? AppState())
            }
            self?.miniPlayerWindowController?.window?.makeKeyAndOrderFront(nil)
            self?.miniPlayerWindowController?.window?.orderFrontRegardless()
        }
    }
    
    func hideMiniPlayer() {
        DispatchQueue.main.async { [weak self] in
            self?.miniPlayerWindowController?.window?.close()
            self?.miniPlayerWindowController = nil
        }
    }
    
    func toggleMiniPlayer() {
        if miniPlayerWindowController?.window?.isVisible ?? false {
            hideMiniPlayer()
        } else {
            showMiniPlayer()
        }
    }
}

// MARK: - Keyboard Shortcut Names

extension KeyboardShortcuts.Name {
    static let volumeUp = Self("volumeUp")
    static let volumeDown = Self("volumeDown")
    static let toggleMute = Self("toggleMute")
    static let playPause = Self("playPause")
    static let nextTrack = Self("nextTrack")
    static let previousTrack = Self("previousTrack")
    static let toggleMiniPlayer = Self("toggleMiniPlayer")
}