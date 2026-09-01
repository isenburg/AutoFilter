import SwiftUI
import AppKit

/// An NSViewRepresentable helper that safely attaches a native AppKit `autosaveName` to the parent `NSSplitView`,
/// enabling macOS to automatically save and restore divider positions across app launches and view switches
/// without causing recursive SwiftUI layout invalidations.
public struct SplitViewAutosaver: NSViewRepresentable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            var current: NSView? = view
            while let v = current {
                if let splitView = v as? NSSplitView {
                    if splitView.autosaveName != name {
                        splitView.autosaveName = name
                    }
                    break
                }
                current = v.superview
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        var current: NSView? = nsView
        while let v = current {
            if let splitView = v as? NSSplitView {
                if splitView.autosaveName != name {
                    splitView.autosaveName = name
                }
                break
            }
            current = v.superview
        }
    }
}
