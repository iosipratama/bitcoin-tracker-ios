import SwiftUI
import SwiftData

struct AddWalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Wallet Name")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                    .padding(.bottom, 12)

                TextField("e.g. Personal, Savings, Cold Storage", text: $name)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: .rowRadius)
                            .fill(Color.surfaceWarm)
                            .overlay(
                                RoundedRectangle(cornerRadius: .rowRadius)
                                    .strokeBorder(Color.rowDivider, lineWidth: 0.5)
                            )
                    )

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("New Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let wallet = Wallet(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                        modelContext.insert(wallet)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? Color.bitcoinOrange : Color.bitcoinOrangeDisabled)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    return AddWalletView()
        .modelContainer(container)
}
