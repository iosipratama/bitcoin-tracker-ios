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
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wallet Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("e.g. Personal, Savings", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                }

                Spacer()
            }
            .padding()
            .background(Color(hex: 0x0A0A0A))
            .navigationTitle("New Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let wallet = Wallet(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                        modelContext.insert(wallet)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? Color.bitcoinOrange : .secondary)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
