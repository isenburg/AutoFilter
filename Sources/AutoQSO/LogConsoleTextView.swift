import SwiftUI
import AppKit

struct LogLine {
    let text: String
    let color: Color
}

struct LogConsoleTextView: NSViewRepresentable {
    let lines: [LogLine]
    let isPaused: Bool
    let fontSize: Double
    let isNewestOnTop: Bool
    let backgroundColor: Color
    
    class Coordinator: NSObject {
        var previousIsPaused: Bool = false
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.importsGraphics = false
        textView.isRichText = false
        textView.autoresizingMask = [.width]
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        textView.backgroundColor = NSColor(backgroundColor)
        
        let storage = textView.textStorage
        let attributed = attributedText()
        
        let stringChanged = (storage?.string != attributed.string)
        let unpaused = (context.coordinator.previousIsPaused && !isPaused)
        context.coordinator.previousIsPaused = isPaused
        
        let oldOffset = scrollView.contentView.bounds.origin.y
        let oldHeight = scrollView.documentView?.bounds.height ?? 0
        
        if stringChanged {
            storage?.setAttributedString(attributed)
            
            // Force layout pass to calculate new content height
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            
            let newHeight = scrollView.documentView?.bounds.height ?? 0
            
            if isPaused {
                var targetOffset = oldOffset
                if isNewestOnTop {
                    let heightDifference = newHeight - oldHeight
                    if heightDifference > 0 {
                        targetOffset = oldOffset + heightDifference
                    }
                }
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetOffset))
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
        
        if !isPaused && (stringChanged || unpaused) {
            let range = isNewestOnTop ? NSRange(location: 0, length: 0) : NSRange(location: attributed.length, length: 0)
            textView.scrollRangeToVisible(range)
        }
    }
    
    private func attributedText() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        
        for line in lines {
            let attrLine = NSAttributedString(string: line.text + "\n", attributes: [
                .font: font,
                .foregroundColor: NSColor(line.color)
            ])
            result.append(attrLine)
        }
        return result
    }
}
