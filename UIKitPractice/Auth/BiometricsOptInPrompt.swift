import SwiftUI

struct BiometricsOptInPrompt: View {
    let authManager: AuthManager
    let onFinished: () -> Void

    @State private var show = false
    @State private var unavailableReason: String?

    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
            .onAppear {
                // Show exactly once when this screen appears.
                DispatchQueue.main.async { show = true }
            }
            .alert("Использовать Face ID / Touch ID?", isPresented: $show) {
                Button("Да") {
                    switch authManager.biometricAvailability() {
                    case .available:
                        authManager.setBiometricsEnabled(true)
                        onFinished()
                    case .unavailable(let reason):
                        authManager.setBiometricsEnabled(false)
                        unavailableReason = reason
                    }
                }
                Button("Нет", role: .cancel) {
                    authManager.setBiometricsEnabled(false)
                    onFinished()
                }
            } message: {
                Text("Вы сможете изменить это в настройках позже.")
            }
            .alert("Информация", isPresented: Binding(get: { unavailableReason != nil }, set: { _ in unavailableReason = nil; onFinished() })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(unavailableReason ?? "")
            }
    }
}

