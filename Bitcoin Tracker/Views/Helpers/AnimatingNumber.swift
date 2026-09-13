import SwiftUI

struct AnimatingNumber: View {
    let value: Double
    let formatter: (Double) -> String

    // nil until the first value lands, so the figure appears settled rather than
    // counting up from zero every time the screen opens.
    @State private var displayValue: Double?

    var body: some View {
        Text(formatter(displayValue ?? value))
            .contentTransition(.numericText(value: displayValue ?? value))
            .onChange(of: value, initial: true) { _, newValue in
                guard displayValue != nil else {
                    displayValue = newValue
                    return
                }
                withAnimation(.smooth) {
                    displayValue = newValue
                }
            }
    }
}
