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
                        .foregroundStyle(Color.textSecondary)

                    TextField("e.g. Personal, Savings", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .fill(Color.white.opacity(0.05))
                        )
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
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
                    .foregroundStyle(isValid ? Color.bitcoinOrange : Color.bitcoinOrangeDisabled)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)
    
    return AddWalletView()
        .modelContainer(container)
}

