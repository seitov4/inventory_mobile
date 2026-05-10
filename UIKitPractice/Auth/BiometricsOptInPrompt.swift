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
            .alert(L10n.tr("settings.biometrics.alert_title"), isPresented: $show) {
                Button(L10n.tr("common.yes")) {
                    switch authManager.biometricAvailability() {
                    case .available:
                        authManager.setBiometricsEnabled(true)
                        onFinished()
                    case .unavailable(let reason):
                        authManager.setBiometricsEnabled(false)
                        unavailableReason = reason
                    }
                }
                Button(L10n.tr("common.no"), role: .cancel) {
                    authManager.setBiometricsEnabled(false)
                    onFinished()
                }
            } message: {
                Text(L10n.tr("auth.use_biometrics_message"))
            }
            .alert(L10n.tr("common.info"), isPresented: Binding(get: { unavailableReason != nil }, set: { _ in unavailableReason = nil; onFinished() })) {
                Button(L10n.tr("common.ok"), role: .cancel) {}
            } message: {
                Text(unavailableReason ?? "")
            }
    }
}
