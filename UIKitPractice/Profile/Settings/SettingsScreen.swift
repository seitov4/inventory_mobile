import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class SettingsScreenViewModel: ObservableObject {
    @Published var notificationsOn: Bool
    @Published var appearance: AppTheme
    @Published var language: AppLanguage
    @Published var biometricsOn: Bool
    @Published var biometricsUnavailableReason: String?
    @Published var showBiometricsConfirm: Bool = false

    private let settings = SettingsViewModel()
    private let authManager: AuthManager

    init(authManager: AuthManager? = nil) {
        self.authManager = authManager ?? .shared
        self.notificationsOn = settings.currentNotifications
        self.appearance = AppTheme(rawValue: settings.currentAppearanceIndex) ?? .system
        self.language = settings.currentLanguage
        self.biometricsOn = self.authManager.isBiometricsEnabled
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

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        settings.currentLanguage = language
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
            Section(L10n.tr("settings.notifications.section")) {
                Toggle(L10n.tr("settings.notifications.toggle"), isOn: Binding(
                    get: { viewModel.notificationsOn },
                    set: { viewModel.setNotifications($0) }
                ))
            }

            Section(L10n.tr("settings.appearance.section")) {
                Picker(L10n.tr("settings.theme.title"), selection: Binding(
                    get: { viewModel.appearance },
                    set: { viewModel.setAppearance($0) }
                )) {
                    Text(L10n.tr("settings.theme.system")).tag(AppTheme.system)
                    Text(L10n.tr("settings.theme.light")).tag(AppTheme.light)
                    Text(L10n.tr("settings.theme.dark")).tag(AppTheme.dark)
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.tr("settings.language.section")) {
                Picker(L10n.tr("settings.language.title"), selection: Binding(
                    get: { viewModel.language },
                    set: { viewModel.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(L10n.tr("settings.security.section")) {
                NavigationLink {
                    PasscodeChangeScreen(viewModel: PasscodeChangeViewModel(authManager: .shared))
                } label: {
                    Label(L10n.tr("settings.change_passcode"), systemImage: "lock.rotation")
                }

                Toggle(L10n.tr("settings.biometrics.login_toggle"), isOn: Binding(
                    get: { viewModel.biometricsOn },
                    set: { viewModel.setBiometrics($0) }
                ))
                .disabled(viewModel.biometricsUnavailableReason != nil)
                .alert(L10n.tr("settings.biometrics.alert_title"), isPresented: $viewModel.showBiometricsConfirm) {
                    Button(L10n.tr("common.yes")) { viewModel.confirmEnableBiometrics(true) }
                    Button(L10n.tr("common.no"), role: .cancel) { viewModel.confirmEnableBiometrics(false) }
                } message: {
                    Text(L10n.tr("settings.biometrics.alert_message"))
                }

                if let reason = viewModel.biometricsUnavailableReason {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L10n.tr("settings.biometrics.footer"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.tr("settings.title"))
        .onAppear { viewModel.refreshBiometricsAvailability() }
        .appLocalized()
    }
}
