import SwiftUI
import AppKit

class MiniPlayerWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Constants.UI.miniPlayerWidth, height: Constants.UI.miniPlayerHeight),
            styleMask: [.borderless, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        
        // Enable visual effect
        contentView?.wantsLayer = true
        
        // Position in top-right corner
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth = frame.width
            let windowHeight = frame.height
            let xPos = screenRect.maxX - windowWidth - 20
            let yPos = screenRect.maxY - windowHeight - 20
            setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
    }
}

class MiniPlayerWindowController: NSWindowController {
    convenience init(appState: AppState) {
        let window = MiniPlayerWindow()
        self.init(window: window)
        
        let contentView = MiniPlayerView(appState: appState) {
            window.close()
        }
        
        window.contentView = NSHostingView(rootView: contentView)
    }
}