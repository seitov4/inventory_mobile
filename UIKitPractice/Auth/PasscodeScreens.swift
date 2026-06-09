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
            errorMessage = L10n.tr("auth.enter_6_digits")
            return
        }

        if step == 1 {
            step = 2
            return
        }

        guard confirm == code else {
            errorMessage = L10n.tr("auth.passcodes_mismatch")
            confirmation = ""
            return
        }

        do {
            try authManager.setPasscode(code)
            showBiometricsPrompt = true
        } catch {
            errorMessage = L10n.tr("auth.save_passcode_failed")
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

            Text(viewModel.isExistingUser ? L10n.tr("auth.welcome_back") : L10n.tr("auth.welcome"))
                .font(.title3.weight(.semibold))
                .padding(.top, 2)

            Text(viewModel.step == 1 ? L10n.tr("auth.setup_passcode") : L10n.tr("auth.repeat_passcode"))
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

            Button(viewModel.step == 1 ? L10n.tr("auth.continue") : L10n.tr("auth.save")) {
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
        .alert(L10n.tr("settings.biometrics.alert_title"), isPresented: $viewModel.showBiometricsPrompt) {
            Button(L10n.tr("common.yes")) { viewModel.biometricsChoice(enable: true, onFinished: onFinished) }
            Button(L10n.tr("common.no"), role: .cancel) { viewModel.biometricsChoice(enable: false, onFinished: onFinished) }
        } message: {
            Text(L10n.tr("auth.use_biometrics_message"))
        }
        .alert(L10n.tr("common.info"), isPresented: $viewModel.showMessageAlert) {
            Button(L10n.tr("common.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.messageAlertText)
        }
        .appLocalized()
    }
}

@MainActor
final class PasscodeUnlockViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var errorMessage: String?
    @Published var isBiometricsInProgress: Bool = false
    @Published var failedAttempts: Int = 0
    @Published var shakeTrigger: Int = 0
    @Published var showForgotPasscodeAlert: Bool = false

    private let authManager: AuthManager
    private var isEvaluating: Bool = false

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func unlockWithPasscode(onUnlocked: @escaping () -> Void, onLockout: @escaping () -> Void) {
        guard !isEvaluating else { return }
        errorMessage = nil
        guard code.count == 6 else {
            errorMessage = L10n.tr("auth.enter_6_digits")
            return
        }
        isEvaluating = true
        defer { isEvaluating = false }

        guard authManager.verifyPasscode(code) else {
            failedAttempts += 1
            errorMessage = failedAttempts < 5
            ? L10n.tr("auth.invalid_passcode")
            : L10n.tr("auth.too_many_attempts")

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
            let result = await self.authManager.authenticateWithBiometrics(reason: L10n.tr("auth.unlock_reason"))
            await MainActor.run {
                self.isBiometricsInProgress = false
                switch result {
                case .success:
                    onUnlocked()
                case .failure:
                    self.errorMessage = L10n.tr("auth.biometry_use_failed")
                }
            }
        }
    }

    func forgotPasscode() {
        showForgotPasscodeAlert = true
    }

    func confirmForgotPasscode(onLockout: @escaping () -> Void) {
        code = ""
        failedAttempts = 0
        KeychainManager.shared.deleteToken()
        UserSessionManager.shared.clear()
        authManager.clearPasscode()
        authManager.setBiometricsEnabled(false)
        AppAnalytics.shared.track(.logout, properties: [
            "source": "forgot_passcode"
        ])
        onLockout()
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

            Text(L10n.tr("auth.welcome_back"))
                .font(.title3.weight(.semibold))
                .padding(.top, 2)

            Text(L10n.tr("auth.enter_passcode"))
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

            Button {
                viewModel.forgotPasscode()
            } label: {
                Text(L10n.tr("auth.forgot_passcode"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
        .onAppear { viewModel.tryBiometrics(onUnlocked: onUnlocked) }
        .alert(L10n.tr("auth.forgot_passcode_alert_title"), isPresented: $viewModel.showForgotPasscodeAlert) {
            Button(L10n.tr("common.no"), role: .cancel) {}
            Button(L10n.tr("common.yes"), role: .destructive) {
                viewModel.confirmForgotPasscode(onLockout: onLockout)
            }
        } message: {
            Text(L10n.tr("auth.forgot_passcode_alert_message"))
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .appLocalized()
    }
}

@MainActor
final class PasscodeChangeViewModel: ObservableObject {
    enum Step: Int {
        case current = 1
        case new = 2
        case confirm = 3
    }

    @Published var step: Step = .current
    @Published var currentPasscode: String = ""
    @Published var newPasscode: String = ""
    @Published var confirmation: String = ""
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var shakeTrigger: Int = 0

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    var title: String {
        switch step {
        case .current: return L10n.tr("auth.change.current_title")
        case .new: return L10n.tr("auth.change.new_title")
        case .confirm: return L10n.tr("auth.change.confirm_title")
        }
    }

    var subtitle: String {
        switch step {
        case .current: return L10n.tr("auth.change.current_subtitle")
        case .new: return L10n.tr("auth.change.new_subtitle")
        case .confirm: return L10n.tr("auth.change.confirm_subtitle")
        }
    }

    var buttonTitle: String {
        step == .confirm ? L10n.tr("auth.change.save_code") : L10n.tr("auth.continue")
    }

    var entry: Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self else { return "" }
                switch self.step {
                case .current: return self.currentPasscode
                case .new: return self.newPasscode
                case .confirm: return self.confirmation
                }
            },
            set: { [weak self] newValue in
                guard let self else { return }
                switch self.step {
                case .current: self.currentPasscode = newValue
                case .new: self.newPasscode = newValue
                case .confirm: self.confirmation = newValue
                }
            }
        )
    }

    func submit() {
        errorMessage = nil

        switch step {
        case .current:
            guard currentPasscode.count == 6 else {
                fail(L10n.tr("auth.enter_6_digits"))
                return
            }

            guard authManager.verifyPasscode(currentPasscode) else {
                currentPasscode = ""
                fail(L10n.tr("auth.change.invalid_current"))
                return
            }

            step = .new

        case .new:
            guard newPasscode.count == 6 else {
                fail(L10n.tr("auth.enter_6_digits"))
                return
            }

            guard newPasscode != currentPasscode else {
                newPasscode = ""
                fail(L10n.tr("auth.change.same_code"))
                return
            }

            step = .confirm

        case .confirm:
            guard confirmation.count == 6 else {
                fail(L10n.tr("auth.enter_6_digits"))
                return
            }

            guard confirmation == newPasscode else {
                confirmation = ""
                fail(L10n.tr("auth.passcodes_mismatch"))
                return
            }

            do {
                let changed = try authManager.changePasscode(currentPasscode: currentPasscode, newPasscode: newPasscode)
                guard changed else {
                    reset()
                    fail(L10n.tr("auth.change.current_expired"))
                    return
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showSuccess = true
            } catch {
                fail(L10n.tr("auth.save_passcode_failed"))
            }
        }
    }

    func reset() {
        step = .current
        currentPasscode = ""
        newPasscode = ""
        confirmation = ""
    }

    private func fail(_ message: String) {
        errorMessage = message
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        withAnimation(.default) { shakeTrigger += 1 }
    }
}

struct PasscodeChangeScreen: View {
    @ObservedObject var viewModel: PasscodeChangeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 28)

            Image(systemName: "lock.rotation")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 72, height: 72)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 7) {
                Text(viewModel.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(viewModel.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            PinEntryField(code: viewModel.entry, length: 6) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.submit()
                }
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

            Button(viewModel.buttonTitle) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.submit()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, 24)
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .navigationTitle(L10n.tr("auth.change.title"))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: viewModel.step.rawValue)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .alert(L10n.tr("auth.change.success_title"), isPresented: $viewModel.showSuccess) {
            Button(L10n.tr("common.ok")) { dismiss() }
        } message: {
            Text(L10n.tr("auth.change.success_message"))
        }
        .appLocalized()
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
