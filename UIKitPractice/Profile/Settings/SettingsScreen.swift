import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class SettingsScreenViewModel: ObservableObject {
    @Published var notificationsOn: Bool
    @Published var appearance: AppTheme
    @Published var biometricsOn: Bool
    @Published var biometricsUnavailableReason: String?
    @Published var showBiometricsConfirm: Bool = false

    private let settings = SettingsViewModel()
    private let authManager: AuthManager

    init(authManager: AuthManager = .shared) {
        self.authManager = authManager
        self.notificationsOn = settings.currentNotifications
        self.appearance = AppTheme(rawValue: settings.currentAppearanceIndex) ?? .system
        self.biometricsOn = authManager.isBiometricsEnabled
        self.refreshBiometricsAvailability()
    }

    func setNotifications(_ isOn: Bool) {
        notificationsOn = isOn
        settings.toggleNotifications(isOn)
    }

    func setAppearance(_ theme: AppTheme) {
        appearance = theme
        settings.updateAppearance(theme.rawValue)
    }

    func refreshBiometricsAvailability() {
        switch authManager.biometricAvailability() {
        case .available:
            biometricsUnavailableReason = nil
        case .unavailable(let reason):
            biometricsUnavailableReason = reason
            biometricsOn = false
            authManager.setBiometricsEnabled(false)
        }
    }

    func setBiometrics(_ isOn: Bool) {
        refreshBiometricsAvailability()
        guard biometricsUnavailableReason == nil else { return }
        if isOn {
            // Confirm with user first (also covers "unknown" state).
            showBiometricsConfirm = true
        } else {
            biometricsOn = false
            authManager.setBiometricsEnabled(false)
        }
    }

    func confirmEnableBiometrics(_ enable: Bool) {
        if enable {
            refreshBiometricsAvailability()
            guard biometricsUnavailableReason == nil else {
                biometricsOn = false
                authManager.setBiometricsEnabled(false)
                return
            }
            biometricsOn = true
            authManager.setBiometricsEnabled(true)
        } else {
            biometricsOn = false
            authManager.setBiometricsEnabled(false)
        }
    }
}

struct SettingsScreen: View {
    @StateObject var viewModel: SettingsScreenViewModel

    var body: some View {
        Form {
            Section("Уведомления") {
                Toggle("Уведомления", isOn: Binding(
                    get: { viewModel.notificationsOn },
                    set: { viewModel.setNotifications($0) }
                ))
            }

            Section("Внешний вид") {
                Picker("Тема", selection: Binding(
                    get: { viewModel.appearance },
                    set: { viewModel.setAppearance($0) }
                )) {
                    Text("Системная").tag(AppTheme.system)
                    Text("Светлая").tag(AppTheme.light)
                    Text("Тёмная").tag(AppTheme.dark)
                }
                .pickerStyle(.segmented)
            }

            Section("Безопасность") {
                Toggle("Login with Face ID / Touch ID", isOn: Binding(
                    get: { viewModel.biometricsOn },
                    set: { viewModel.setBiometrics($0) }
                ))
                .disabled(viewModel.biometricsUnavailableReason != nil)
                .alert("Использовать Face ID / Touch ID?", isPresented: $viewModel.showBiometricsConfirm) {
                    Button("Да") { viewModel.confirmEnableBiometrics(true) }
                    Button("Нет", role: .cancel) { viewModel.confirmEnableBiometrics(false) }
                } message: {
                    Text("Если включено — вы сможете входить с помощью биометрии. Иначе будет запрашиваться код‑пароль.")
                }

                if let reason = viewModel.biometricsUnavailableReason {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Если выключено — вход выполняется по коду‑паролю.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Настройки")
        .onAppear { viewModel.refreshBiometricsAvailability() }
    }
}
