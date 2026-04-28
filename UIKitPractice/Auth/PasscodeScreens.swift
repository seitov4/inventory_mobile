import SwiftUI
import LocalAuthentication
import Combine
import UIKit

@MainActor
final class PasscodeSetupViewModel: ObservableObject {
    @Published var step: Int = 1
    @Published var passcode: String = ""
    @Published var confirmation: String = ""
    @Published var errorMessage: String?
    @Published var showBiometricsPrompt: Bool = false
    @Published var showMessageAlert: Bool = false
    @Published var messageAlertText: String = ""
    @Published var isExistingUser: Bool = false

    private let authManager: AuthManager

    init(authManager: AuthManager, isExistingUser: Bool) {
        self.authManager = authManager
        self.isExistingUser = isExistingUser
    }

    var entry: Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self else { return "" }
                return self.step == 1 ? self.passcode : self.confirmation
            },
            set: { [weak self] newValue in
                guard let self else { return }
                if self.step == 1 {
                    self.passcode = newValue
                } else {
                    self.confirmation = newValue
                }
            }
        )
    }

    func submit(onFinished: @escaping () -> Void) {
        errorMessage = nil
        let code = passcode
        let confirm = confirmation

        guard code.count == 6 else {
            errorMessage = "Введите 6-значный код"
            return
        }

        if step == 1 {
            step = 2
            return
        }

        guard confirm == code else {
            errorMessage = "Коды не совпадают"
            confirmation = ""
            return
        }

        do {
            try authManager.setPasscode(code)
            showBiometricsPrompt = true
        } catch {
            errorMessage = "Не удалось сохранить код. Повторите."
        }
    }

    func biometricsChoice(enable: Bool, onFinished: @escaping () -> Void) {
        if enable {
            switch authManager.biometricAvailability() {
            case .available:
                authManager.setBiometricsEnabled(true)
            case .unavailable(let reason):
                authManager.setBiometricsEnabled(false)
                messageAlertText = reason
                showMessageAlert = true
            }
        } else {
            authManager.setBiometricsEnabled(false)
        }
        onFinished()
    }
}

struct PasscodeSetupScreen: View {
    @ObservedObject var viewModel: PasscodeSetupViewModel
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            Text("InventiX")
                .font(.system(size: 34, weight: .bold))

            Text(viewModel.isExistingUser ? "С возвращением!" : "Добро пожаловать")
                .font(.title3.weight(.semibold))
                .padding(.top, 2)

            Text(viewModel.step == 1 ? "Установите 6‑значный код‑пароль" : "Повторите код‑пароль")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PinEntryField(code: viewModel.entry, length: 6) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.submit(onFinished: onFinished)
                }
            }
                .padding(.top, 8)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button(viewModel.step == 1 ? "Продолжить" : "Сохранить") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.submit(onFinished: onFinished)
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .alert("Использовать Face ID / Touch ID?", isPresented: $viewModel.showBiometricsPrompt) {
            Button("Да") { viewModel.biometricsChoice(enable: true, onFinished: onFinished) }
            Button("Нет", role: .cancel) { viewModel.biometricsChoice(enable: false, onFinished: onFinished) }
        } message: {
            Text("Вы сможете изменить это в настройках позже.")
        }
        .alert("Информация", isPresented: $viewModel.showMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.messageAlertText)
        }
    }
}

@MainActor
final class PasscodeUnlockViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var errorMessage: String?
    @Published var isBiometricsInProgress: Bool = false
    @Published var failedAttempts: Int = 0
    @Published var shakeTrigger: Int = 0

    private let authManager: AuthManager
    private var isEvaluating: Bool = false

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func unlockWithPasscode(onUnlocked: @escaping () -> Void, onLockout: @escaping () -> Void) {
        guard !isEvaluating else { return }
        errorMessage = nil
        guard code.count == 6 else {
            errorMessage = "Введите 6-значный код"
            return
        }
        isEvaluating = true
        defer { isEvaluating = false }

        guard authManager.verifyPasscode(code) else {
            failedAttempts += 1
            errorMessage = failedAttempts < 5
            ? "Неверный код. Попробуйте ещё раз."
            : "Превышено число попыток. Войдите заново."

            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakeTrigger += 1 }

            code = ""

            if failedAttempts >= 5 {
                // Security: force re-login after too many failures.
                KeychainManager.shared.deleteToken()
                authManager.setBiometricsEnabled(false)
                onLockout()
            }
            return
        }
        failedAttempts = 0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onUnlocked()
    }

    func tryBiometrics(onUnlocked: @escaping () -> Void) {
        guard authManager.isBiometricsEnabled else { return }
        isBiometricsInProgress = true
        Task { [weak self] in
            guard let self else { return }
            let result = await self.authManager.authenticateWithBiometrics(reason: "Разблокировать InventiX")
            await MainActor.run {
                self.isBiometricsInProgress = false
                switch result {
                case .success:
                    onUnlocked()
                case .failure:
                    self.errorMessage = "Не удалось использовать биометрию. Введите код‑пароль."
                }
            }
        }
    }
}

struct PasscodeUnlockScreen: View {
    @ObservedObject var viewModel: PasscodeUnlockViewModel
    let onUnlocked: () -> Void
    let onLockout: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            Text("InventiX")
                .font(.system(size: 34, weight: .bold))

            Text("С возвращением!")
                .font(.title3.weight(.semibold))
                .padding(.top, 2)

            Text("Введите код‑пароль")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PinEntryField(code: $viewModel.code, length: 6) {
                viewModel.unlockWithPasscode(onUnlocked: onUnlocked, onLockout: onLockout)
            }
            .modifier(ShakeEffect(animatableData: CGFloat(viewModel.shakeTrigger)))
                .padding(.top, 8)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
        .onAppear { viewModel.tryBiometrics(onUnlocked: onUnlocked) }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }
}

struct PinEntryField: View {
    @Binding var code: String
    let length: Int
    var onComplete: (() -> Void)? = nil

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { idx in
                    Circle()
                        .strokeBorder(Color(.separator), lineWidth: 1)
                        .background(
                            Circle().fill(idx < code.count ? Color.primary : Color.clear)
                        )
                        .frame(width: 14, height: 14)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: code.count)
                }
            }

            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    let next = String(filtered.prefix(length))
                    let wasComplete = code.count == length
                    code = next
                    if !wasComplete && next.count == length {
                        onComplete?()
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focused)
            .opacity(0.001)
        }
        .onTapGesture { focused = true }
        .onAppear { focused = true }
        .padding(.horizontal, 24)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

