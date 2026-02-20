import SwiftUI

struct AnimatingNumber: View {
    let value: Double
    let formatter: (Double) -> String

    @State private var displayValue: Double = 0

    var body: some View {
        Text(formatter(displayValue))
            .contentTransition(.numericText(value: displayValue))
            .onChange(of: value, initial: true) { _, newValue in
                withAnimation(.easeOut(duration: 0.6)) {
                    displayValue = newValue
                }
            }
    }
}
