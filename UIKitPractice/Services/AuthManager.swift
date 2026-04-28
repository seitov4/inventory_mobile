import Foundation
import LocalAuthentication
import CryptoKit
import Security

/// App-level authentication: passcode + optional biometrics.
///
/// - Passcode is stored as `salt + SHA256(salt + passcode)` in Keychain.
/// - Biometrics are an opt-in convenience; passcode is always the fallback.
final class AuthManager {
    static let shared = AuthManager()

    private let keychain = KeychainManager.shared
    private let biometricsPreferenceKey = "auth_biometrics_preference"

    private let passcodeSaltKey = "appPasscodeSalt"
    private let passcodeHashKey = "appPasscodeHash"

    private init() {}

    var hasPasscode: Bool {
        guard let _ = keychain.getString(key: passcodeSaltKey),
              let _ = keychain.getString(key: passcodeHashKey) else { return false }
        return true
    }

    var isBiometricsEnabled: Bool {
        biometricPreference == .enabled
    }

    enum BiometricsPreference: Int {
        case unknown = 0
        case enabled = 1
        case disabled = 2
    }

    var biometricPreference: BiometricsPreference {
        get { BiometricsPreference(rawValue: UserDefaults.standard.integer(forKey: biometricsPreferenceKey)) ?? .unknown }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: biometricsPreferenceKey) }
    }

    func setBiometricsEnabled(_ enabled: Bool) {
        biometricPreference = enabled ? .enabled : .disabled
    }

    func setPasscode(_ passcode: String) throws {
        let salt = Self.randomSaltBase64()
        let hash = Self.hash(passcode: passcode, saltBase64: salt)
        keychain.saveString(salt, key: passcodeSaltKey)
        keychain.saveString(hash, key: passcodeHashKey)
    }

    func verifyPasscode(_ passcode: String) -> Bool {
        guard let salt = keychain.getString(key: passcodeSaltKey),
              let storedHash = keychain.getString(key: passcodeHashKey) else { return false }
        let candidate = Self.hash(passcode: passcode, saltBase64: salt)
        return candidate == storedHash
    }

    func clearPasscode() {
        keychain.delete(key: passcodeSaltKey)
        keychain.delete(key: passcodeHashKey)
    }

    enum BiometricAvailability {
        case available(kind: LABiometryType)
        case unavailable(reason: String)
    }

    func biometricAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        let ok = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard ok else {
            return .unavailable(reason: error?.localizedDescription ?? "Биометрия недоступна на этом устройстве.")
        }
        return .available(kind: context.biometryType)
    }

    func authenticateWithBiometrics(reason: String) async -> Result<Void, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(error ?? NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Биометрия недоступна."]))
        }

        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return ok ? .success(()) : .failure(NSError(domain: "AuthManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Не удалось выполнить биометрическую аутентификацию."]))
        } catch {
            return .failure(error)
        }
    }
}

private extension AuthManager {
    static func randomSaltBase64() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    static func hash(passcode: String, saltBase64: String) -> String {
        let salt = Data(base64Encoded: saltBase64) ?? Data()
        let pass = Data(passcode.utf8)
        var data = Data()
        data.append(salt)
        data.append(pass)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
    }
}

