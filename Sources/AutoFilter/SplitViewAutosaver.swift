import SwiftUI
import AppKit

/// A custom NSView that reliably finds its enclosing NSSplitView and specific subview container
final class SplitViewTrackingNSView: NSView {
    var onFoundSplitView: ((NSSplitView, NSView) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            findSplitView()
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        findSplitView()
    }

    private func findSplitView() {
        var current: NSView? = self.superview
        var childOfSplit: NSView? = self
        
        while let v = current {
            if let splitView = v as? NSSplitView, !splitView.isVertical {
                if let directChild = childOfSplit {
                    onFoundSplitView?(splitView, directChild)
                }
                return
            }
            childOfSplit = v
            current = v.superview
        }
    }
}

/// An NSViewRepresentable helper that memorizes and restores divider positions of an NSSplitView
/// across view detachments, dockings, and app launches without AppKit autosave conflicts.
public struct SplitViewAutosaver: NSViewRepresentable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(name: name)
    }
    
    public func makeNSView(context: Context) -> NSView {
        let trackingView = SplitViewTrackingNSView()
        trackingView.onFoundSplitView = { [weak coordinator = context.coordinator] splitView, child in
            coordinator?.attach(to: splitView, childView: child)
        }
        return trackingView
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        if let tracking = nsView as? SplitViewTrackingNSView {
            tracking.onFoundSplitView = { [weak coordinator = context.coordinator] splitView, child in
                coordinator?.attach(to: splitView, childView: child)
            }
        }
    }
    
    public class Coordinator: NSObject {
        let name: String
        private weak var splitView: NSSplitView?
        private weak var trackedChild: NSView?
        private var resizeObserver: NSObjectProtocol?
        private var isReadyToRecord: Bool = false
        
        init(name: String) {
            self.name = name
            super.init()
        }
        
        func attach(to splitView: NSSplitView, childView: NSView) {
            if self.splitView === splitView && self.trackedChild === childView { return }
            self.splitView = splitView
            self.trackedChild = childView
            self.isReadyToRecord = false
            
            // Disable AppKit built-in autosave to avoid conflicting array resets
            splitView.autosaveName = nil
            
            // 1. Restore saved height immediately and after layout pass
            let key = "AutoFilter_SplitPos_\(name)"
            let legacyKey = "AutoQSO_SplitPos_\(name)"
            var saved = UserDefaults.standard.double(forKey: key)
            if saved <= 0 {
                saved = UserDefaults.standard.double(forKey: legacyKey)
            }
            let heightToRestore = saved > 60 ? saved : 180.0
            
            applyPosition(heightToRestore, to: splitView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak splitView] in
                guard let self = self, let splitView = splitView else { return }
                self.applyPosition(heightToRestore, to: splitView)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self, weak splitView] in
                guard let self = self, let splitView = splitView else { return }
                self.applyPosition(heightToRestore, to: splitView)
            }
            
            // 2. Only arm recording AFTER layout has completely settled (0.4s delay)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.isReadyToRecord = true
            }
            
            // 3. Listen for manual user resize notifications
            if let obs = resizeObserver {
                NotificationCenter.default.removeObserver(obs)
            }
            
            resizeObserver = NotificationCenter.default.addObserver(
                forName: NSSplitView.didResizeSubviewsNotification,
                object: splitView,
                queue: .main
            ) { [weak self, weak splitView] _ in
                guard let self = self, self.isReadyToRecord, let splitView = splitView, let child = self.trackedChild else { return }
                let h = Double(child.frame.height)
                if h > 60 && h < 600 {
                    UserDefaults.standard.set(h, forKey: key)
                }
            }
        }
        
        private func applyPosition(_ pos: Double, to splitView: NSSplitView) {
            guard splitView.subviews.count > 1 else { return }
            let dividerPos = CGFloat(pos)
            splitView.setPosition(dividerPos, ofDividerAt: 0)
            splitView.layoutSubtreeIfNeeded()
        }
        
        deinit {
            if let obs = resizeObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }
}
