import SwiftUI
import Combine

@MainActor
final class LoginScreenViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var language: AppLanguage = LocalizationManager.shared.currentLanguage
    @Published var loginType: LoginType = .phone {
        didSet {
            if loginType == .phone {
                ensurePhonePrefix()
            }
        }
    }

    private let authService: AuthService
    private let isMockLoginEnabled: Bool
    private let localizationManager: LocalizationManager

    init(
        authService: AuthService? = nil,
        isMockLoginEnabled: Bool = true,
        localizationManager: LocalizationManager? = nil
    ) {
        self.authService = authService ?? AuthService()
        self.isMockLoginEnabled = isMockLoginEnabled
        self.localizationManager = localizationManager ?? .shared
        self.language = self.localizationManager.currentLanguage
        ensurePhonePrefix()
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        localizationManager.currentLanguage = language
    }

    func updatePhone(_ value: String) {
        let digits = value.filter(\.isNumber)
        var nationalDigits = digits

        if nationalDigits.hasPrefix("7") || nationalDigits.hasPrefix("8") {
            nationalDigits.removeFirst()
        }

        phone = "+7" + nationalDigits.prefix(10)
    }

    func ensurePhonePrefix() {
        if phone.isEmpty {
            phone = "+7"
        }
    }

    func login(onSuccess: @escaping () -> Void) {
        errorMessage = nil

        if isMockLoginEnabled {
            // Mock a successful login so passcode flow can be tested without backend.
            KeychainManager.shared.saveToken("mock-token")
            UserSessionManager.shared.ensureMockRoleIfNeeded()
            onSuccess()
            return
        }

        let loginValue: String
        switch loginType {
        case .email:
            let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { errorMessage = L10n.tr("Введите email"); return }
            loginValue = value
        case .phone:
            let value = normalizedPhone
            guard value.count > 2 else { errorMessage = L10n.tr("Введите номер телефона"); return }
            loginValue = value
        }

        guard !password.isEmpty else {
            errorMessage = L10n.tr("Введите пароль")
            return
        }

        isLoading = true
        authService.login(login: loginValue, password: password, type: loginType) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var normalizedPhone: String {
        let digits = phone.filter(\.isNumber)
        if digits.hasPrefix("7") {
            return "+" + digits
        }
        return "+7" + digits
    }
}

struct LoginScreen: View {
    @StateObject var viewModel: LoginScreenViewModel
    let onLoginSuccess: () -> Void

    @FocusState private var focus: Field?
    @State private var isPasswordVisible = false
    private enum Field { case email, password }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                languageMenu
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            Text("InventiX")
                .font(.system(size: 40, weight: .bold))
                .tracking(0.2)

            VStack(spacing: 12) {
                Picker("", selection: $viewModel.loginType) {
                    Text(L10n.tr("Телефон")).tag(LoginType.phone)
                    Text("Email").tag(LoginType.email)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .onChange(of: viewModel.loginType) { _, newValue in
                    if newValue == .phone {
                        viewModel.ensurePhonePrefix()
                    }
                }

                if viewModel.loginType == .email {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .modifier(AuthTextFieldStyle())
                } else {
                    TextField(L10n.tr("Номер телефона"), text: Binding(
                        get: { viewModel.phone },
                        set: { viewModel.updatePhone($0) }
                    ))
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .modifier(AuthTextFieldStyle())
                }

                HStack(spacing: 10) {
                    Group {
                        if isPasswordVisible {
                            TextField(L10n.tr("Пароль"), text: $viewModel.password)
                        } else {
                            SecureField(L10n.tr("Пароль"), text: $viewModel.password)
                        }
                    }
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { viewModel.login(onSuccess: onLoginSuccess) }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible ? L10n.tr("auth.password_hide") : L10n.tr("auth.password_show"))
                }
                .modifier(AuthTextFieldStyle())
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.login(onSuccess: onLoginSuccess)
                }
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.tr("Войти"))
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

            Button(L10n.tr("Забыли пароль?")) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.errorMessage = L10n.tr("auth.password_recovery_todo")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.ensurePhonePrefix()
            focus = .email
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .appLocalized()
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    viewModel.setLanguage(language)
                } label: {
                    Label {
                        Text(language.displayName)
                    } icon: {
                        if language == viewModel.language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                Text(viewModel.language.rawValue.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .monospaced()
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color(.secondarySystemBackground), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .accessibilityLabel(L10n.tr("auth.language_selector"))
    }
}

private struct AuthTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .padding(.horizontal, 24)
    }
}
