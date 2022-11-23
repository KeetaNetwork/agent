import Foundation
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        hideMainWindow()
        
        NSApplication.shared.setActivationPolicy(.accessory)
        NSWindow.allowsAutomaticWindowTabbing = false
        
        popover.contentSize = NSSize(width: 330, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        
        statusBar = StatusBarController(popover, show: Dependencies.all.storage.gpgKey == nil)
    }
    
    func handle(url: URL) {
        Dependencies.all.keetaAgent.didReceive(url: url)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideMainWindow()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusBar?.showPopoverIfNeeded()
        }
    }
    
    private func hideMainWindow() {
        NSApplication.shared.windows.first?.orderOut(nil)
    }
}
