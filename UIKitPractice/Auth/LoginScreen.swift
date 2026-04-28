import SwiftUI
import Combine

@MainActor
final class LoginScreenViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loginType: LoginType = .email

    private let authService: AuthService
    /// Temporary: allow skipping backend auth to demo passcode flow.
    private let isMockLoginEnabled: Bool

    init(authService: AuthService = AuthService(), isMockLoginEnabled: Bool = true) {
        self.authService = authService
        self.isMockLoginEnabled = isMockLoginEnabled
    }

    func login(onSuccess: @escaping () -> Void) {
        errorMessage = nil

        let loginValue: String
        switch loginType {
        case .email:
            let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { errorMessage = "Введите email"; return }
            loginValue = value
        case .phone:
            let value = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { errorMessage = "Введите номер телефона"; return }
            loginValue = value
        }

        guard !password.isEmpty else {
            errorMessage = "Введите пароль"
            return
        }

        if isMockLoginEnabled {
            // Mock a successful login so passcode flow can be tested without backend.
            KeychainManager.shared.saveToken("mock-token")
            onSuccess()
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
}

struct LoginScreen: View {
    @StateObject var viewModel: LoginScreenViewModel
    let onLoginSuccess: () -> Void

    @FocusState private var focus: Field?
    private enum Field { case email, password }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text("InventiX")
                .font(.system(size: 40, weight: .bold))
                .tracking(0.2)

            VStack(spacing: 12) {
                Picker("", selection: $viewModel.loginType) {
                    Text("Email").tag(LoginType.email)
                    Text("Телефон").tag(LoginType.phone)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

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
                    TextField("Номер телефона", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .modifier(AuthTextFieldStyle())
                }

                SecureField("Пароль", text: $viewModel.password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { viewModel.login(onSuccess: onLoginSuccess) }
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
                        Text("Войти")
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

            Button("Забыли пароль?") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.errorMessage = "Восстановление пароля будет добавлено после подключения backend API."
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .background(Color(.systemBackground))
        .onAppear { focus = .email }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
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

