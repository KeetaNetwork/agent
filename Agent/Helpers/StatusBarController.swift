import AppKit

final class StatusBarController {
    
    private let popover: NSPopover
    private let mainItem: NSStatusItem
    
    init(_ popover: NSPopover) {
        self.popover = popover
        
        mainItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let mainItemButton = mainItem.button {
            mainItemButton.image = NSImage(named: "statusbar")
            mainItemButton.image?.size = NSSize(width: 22, height: 12)
            mainItemButton.image?.isTemplate = true
            
            mainItemButton.action = #selector(togglePopover(sender:))
            mainItemButton.target = self
        }
    }
    
    // MARK: Helper
    
    @objc private func togglePopover(sender: AnyObject) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let statusBarButton = mainItem.button else { return }
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
        popover.contentViewController?.view.window?.makeKey()
    }
    
    private func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    private func mouseEventHandler(_ event: NSEvent?) {
        if popover.isShown {
            hidePopover(event)
        }
    }
}
