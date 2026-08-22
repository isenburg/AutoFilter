import SwiftUI
import AppKit

struct MapAnnotationZPriorityModifier: ViewModifier {
    let zPosition: CGFloat

    func body(content: Content) -> some View {
        content
            .zIndex(Double(zPosition))
            .background(
                MapAnnotationZPositionSetter(zPosition: zPosition)
                    .allowsHitTesting(false)
            )
    }
}

private struct MapAnnotationZPositionSetter: NSViewRepresentable {
    let zPosition: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = MapAnnotationZPositionReportingView()
        view.targetZPosition = zPosition
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? MapAnnotationZPositionReportingView {
            view.targetZPosition = zPosition
            view.applyZPosition()
        }
    }
}

private class MapAnnotationZPositionReportingView: NSView {
    var targetZPosition: CGFloat = 0

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        applyZPosition()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyZPosition()
    }

    func applyZPosition() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var curr: NSView? = self
            while let v = curr {
                v.wantsLayer = true
                v.layer?.zPosition = self.targetZPosition
                let typeName = String(describing: type(of: v))
                if typeName.contains("AnnotationView") {
                    v.layer?.zPosition = self.targetZPosition
                    break
                }
                curr = v.superview
            }
        }
    }
}

extension View {
    func mapAnnotationZPriority(_ zPosition: CGFloat) -> some View {
        self.modifier(MapAnnotationZPriorityModifier(zPosition: zPosition))
    }
}
