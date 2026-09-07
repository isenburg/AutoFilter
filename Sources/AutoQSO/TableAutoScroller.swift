import SwiftUI
import AppKit

/// A helper view that tracks the enclosing or child NSTableView and NSScrollView
final class TableScrollTrackingNSView: NSView {
    var onFoundTableView: ((NSTableView, NSScrollView) -> Void)?

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
        if let sv = self.enclosingScrollView, let tv = sv.documentView as? NSTableView {
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
        if let tv = view as? NSTableView, let sv = tv.enclosingScrollView {
            return (tv, sv)
        }
        if let sv = view as? NSScrollView, let tv = sv.documentView as? NSTableView {
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
        weak var tableView: NSTableView?
        weak var scrollView: NSScrollView?
        var lastRowCount: Int = 0
        var lastIsNewestOnTop: Bool? = nil
        private var notificationObserver: NSObjectProtocol?
        
        override init() {
            super.init()
            notificationObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ScrollSpotsTableToActive"),
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let self = self else { return }
                let isTop = (notif.object as? Bool) ?? true
                self.scrollToActive(isNewestOnTop: isTop)
            }
        }
        
        deinit {
            if let obs = notificationObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
        
        func scrollToActive(isNewestOnTop: Bool) {
            let performScroll = { [weak self] in
                guard let self = self, let tv = self.tableView, let sv = self.scrollView else { return }
                let count = tv.numberOfRows
                guard count > 0 else { return }
                
                if isNewestOnTop {
                    tv.scrollRowToVisible(0)
                    sv.contentView.scroll(to: NSPoint(x: 0, y: 0))
                    sv.reflectScrolledClipView(sv.contentView)
                } else {
                    let lastRow = count - 1
                    tv.scrollRowToVisible(lastRow)
                    if let doc = sv.documentView {
                        let maxY = max(0, doc.bounds.height - sv.contentView.bounds.height)
                        sv.contentView.scroll(to: NSPoint(x: 0, y: maxY))
                        sv.reflectScrolledClipView(sv.contentView)
                    }
                }
            }
            
            DispatchQueue.main.async { performScroll() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { performScroll() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { performScroll() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { performScroll() }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> TableScrollTrackingNSView {
        let view = TableScrollTrackingNSView()
        view.onFoundTableView = { [weak coordinator = context.coordinator] tv, sv in
            coordinator?.tableView = tv
            coordinator?.scrollView = sv
            coordinator?.scrollToActive(isNewestOnTop: isNewestOnTop)
        }
        return view
    }

    func updateNSView(_ nsView: TableScrollTrackingNSView, context: Context) {
        nsView.findTableView()
        let coordinator = context.coordinator
        
        let directionChanged = (coordinator.lastIsNewestOnTop != isNewestOnTop)
        let rowsChanged = (coordinator.lastRowCount != rowCount)
        coordinator.lastIsNewestOnTop = isNewestOnTop
        coordinator.lastRowCount = rowCount

        if directionChanged || (rowsChanged && !isPaused) {
            coordinator.scrollToActive(isNewestOnTop: isNewestOnTop)
        }
    }
}
