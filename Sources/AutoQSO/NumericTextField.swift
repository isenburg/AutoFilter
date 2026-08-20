import SwiftUI

struct NumericTextField: View {
    let titleKey: LocalizedStringKey
    @Binding var value: Int
    var range: ClosedRange<Int>? = nil
    var prompt: Text? = nil
    
    @State private var text: String = ""
    
    init(_ titleKey: LocalizedStringKey, value: Binding<Int>, range: ClosedRange<Int>? = nil, prompt: Text? = nil) {
        self.titleKey = titleKey
        self._value = value
        self.range = range
        self.prompt = prompt
    }
    
    var body: some View {
        TextField(titleKey, text: $text, prompt: prompt)
            .onAppear {
                text = String(value)
            }
            .onChange(of: value) { _, newValue in
                if Int(text) != newValue {
                    text = String(newValue)
                }
            }
            .onChange(of: text) { _, newValue in
                let cleaned = newValue.filter { $0.isNumber }
                if let intVal = Int(cleaned) {
                    var targetVal = intVal
                    if let range = range {
                        targetVal = min(range.upperBound, max(range.lowerBound, targetVal))
                    }
                    if targetVal != value {
                        value = targetVal
                    }
                }
            }
    }
}
