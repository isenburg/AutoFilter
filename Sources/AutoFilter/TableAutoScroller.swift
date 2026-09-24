import SwiftUI
import AppKit

/// A helper view that tracks the enclosing or child NSTableView and NSScrollView
final class TableScrollTrackingNSView: NSView {
    var onFoundTableView: ((NSTableView, NSScrollView) -> Void)?

    static func isValidSpotsTable(_ tv: NSTableView) -> Bool {
        let className = String(describing: type(of: tv))
        if className.contains("ListView") { return false }
        return tv.tableColumns.count > 1
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            findTableView()
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        findTableView()
    }

    func findTableView() {
        if let (tv, sv) = searchForTableView() {
            onFoundTableView?(tv, sv)
        }
    }

    private func searchForTableView() -> (NSTableView, NSScrollView)? {
        if let sv = self.enclosingScrollView, let tv = sv.documentView as? NSTableView, TableScrollTrackingNSView.isValidSpotsTable(tv) {
            return (tv, sv)
        }
        
        var current: NSView? = self.superview
        while let v = current {
            if let found = findInSubviews(of: v) {
                return found
            }
            current = v.superview
        }
        return nil
    }

    private func findInSubviews(of view: NSView) -> (NSTableView, NSScrollView)? {
        if let tv = view as? NSTableView, let sv = tv.enclosingScrollView, TableScrollTrackingNSView.isValidSpotsTable(tv) {
            return (tv, sv)
        }
        if let sv = view as? NSScrollView, let tv = sv.documentView as? NSTableView, TableScrollTrackingNSView.isValidSpotsTable(tv) {
            return (tv, sv)
        }
        for sub in view.subviews {
            if sub !== self {
                if let found = findInSubviews(of: sub) {
                    return found
                }
            }
        }
        return nil
    }
}

/// An NSViewRepresentable that auto-scrolls the Spots Table to the active end
/// (top when newest on top, bottom when newest on bottom) matching the console behavior.
struct TableAutoScroller: NSViewRepresentable {
    let isNewestOnTop: Bool
    let isPaused: Bool
    let rowCount: Int

    class Coordinator: NSObject {
        weak var trackingView: TableScrollTrackingNSView?
        weak var tableView: NSTableView?
        weak var scrollView: NSScrollView?
        var lastRowCount: Int = 0
        var lastIsNewestOnTop: Bool? = nil
        var currentIsNewestOnTop: Bool = true
        private var notificationObserver: NSObjectProtocol?
        
        override init() {
            super.init()
            notificationObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ScrollSpotsTableToActive"),
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let self = self else { return }
                let isTop = (notif.object as? Bool) ?? self.currentIsNewestOnTop
                self.currentIsNewestOnTop = isTop
                self.scrollToActive(isNewestOnTop: isTop, attemptsRemaining: 10)
            }
        }
        
        deinit {
            if let obs = notificationObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
        
        func scrollToActive(isNewestOnTop: Bool? = nil, attemptsRemaining: Int = 0) {
            let isTop = isNewestOnTop ?? self.currentIsNewestOnTop
            
            if self.tableView == nil || self.tableView?.window == nil {
                self.trackingView?.findTableView()
            }
            
            guard let tv = self.tableView, let sv = self.scrollView, tv.window != nil else {
                if attemptsRemaining > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                        self?.scrollToActive(isNewestOnTop: isTop, attemptsRemaining: attemptsRemaining - 1)
                    }
                }
                return
            }
            let count = tv.numberOfRows
            guard count > 0 else {
                if attemptsRemaining > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                        self?.scrollToActive(isNewestOnTop: isTop, attemptsRemaining: attemptsRemaining - 1)
                    }
                }
                return
            }
            
            let currentX = sv.contentView.bounds.origin.x
            if isTop {
                tv.scrollRowToVisible(0)
                sv.contentView.scroll(to: NSPoint(x: currentX, y: 0))
                sv.reflectScrolledClipView(sv.contentView)
            } else {
                let lastRow = count - 1
                tv.scrollRowToVisible(lastRow)
                
                let docView = sv.documentView ?? tv
                let clipHeight = sv.contentView.bounds.height
                let lastRowRect = tv.rect(ofRow: lastRow)
                let docHeight = max(docView.frame.height, lastRowRect.maxY)
                let maxOffset = max(0, docHeight - clipHeight)
                
                sv.contentView.scroll(to: NSPoint(x: currentX, y: maxOffset))
                sv.reflectScrolledClipView(sv.contentView)
            }
            
            if attemptsRemaining > 0 {
                let delay = (attemptsRemaining > 5) ? 0.05 : 0.08
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.scrollToActive(isNewestOnTop: isTop, attemptsRemaining: attemptsRemaining - 1)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> TableScrollTrackingNSView {
        let view = TableScrollTrackingNSView()
        context.coordinator.trackingView = view
        context.coordinator.currentIsNewestOnTop = isNewestOnTop
        view.onFoundTableView = { [weak coordinator = context.coordinator] tv, sv in
            coordinator?.tableView = tv
            coordinator?.scrollView = sv
            coordinator?.scrollToActive(isNewestOnTop: isNewestOnTop, attemptsRemaining: isNewestOnTop ? 1 : 10)
        }
        return view
    }

    func updateNSView(_ nsView: TableScrollTrackingNSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.trackingView = nsView
        coordinator.currentIsNewestOnTop = isNewestOnTop
        
        nsView.onFoundTableView = { [weak coordinator] tv, sv in
            coordinator?.tableView = tv
            coordinator?.scrollView = sv
        }
        nsView.findTableView()
        
        let directionChanged = (coordinator.lastIsNewestOnTop != isNewestOnTop)
        let rowsChanged = (coordinator.lastRowCount != rowCount)
        coordinator.lastIsNewestOnTop = isNewestOnTop
        coordinator.lastRowCount = rowCount

        if directionChanged {
            coordinator.scrollToActive(isNewestOnTop: isNewestOnTop, attemptsRemaining: 10)
        } else if rowsChanged && !isPaused {
            coordinator.scrollToActive(isNewestOnTop: isNewestOnTop, attemptsRemaining: isNewestOnTop ? 0 : 2)
        }
    }
}
