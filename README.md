# InventiX iOS

InventiX iOS is a modern mobile companion app for retail and inventory management. It gives business owners, cashiers, and staff a fast way to access the platform on the go, manage everyday actions, and move through key workflows with a clean native experience.

Built for speed, clarity, and security, the app combines account-based authentication, local passcode protection, Face ID / Touch ID unlock, and a role-aware interface designed for real daily business use.

## Key Features

- Email / phone login
- Local passcode protection
- Face ID / Touch ID unlock
- Smooth auth flow with polished transitions
- Settings screen with biometric control
- Quick access to business modules
- Role-based app experience
- Coordinator-based app navigation

## Preview

### Login
Clean sign-in screen with email / phone switcher.

`Insert screenshot: Login screen`

![Login Screen](docs/screenshots/login-screen.png)

### Passcode Setup
First-time local security setup after account login.

`Insert screenshot: Passcode setup screen`

![Passcode Setup](docs/screenshots/passcode-setup.png)

### Passcode Unlock
Fast returning-user unlock with passcode and biometric fallback.

`Insert screenshot: Passcode unlock screen`

![Passcode Unlock](docs/screenshots/passcode-unlock.png)

### Face ID / Touch ID Prompt
Biometric opt-in shown after secure setup.

`Insert screenshot: biometric opt-in alert`

![Biometric Prompt](docs/screenshots/biometric-opt-in.png)

### Main App
Main tab-based shell for daily business actions.

`Insert screenshot: main tab bar screen`

![Main App](docs/screenshots/main-tabbar.png)

### Settings
Security preferences including biometric login toggle.

`Insert screenshot: settings screen with biometric toggle`

![Settings](docs/screenshots/settings-screen.png)

## Why InventiX

- Fast everyday access for store operations
- Secure local unlock with passcode and biometrics
- Clean mobile experience on top of an existing business platform
- Designed for quick growth with scalable navigation and modular features

## Tech Stack

- Swift
- UIKit
- SwiftUI
- LocalAuthentication
- KeychainAccess
- Coordinator pattern

## Git / Run

```bash
git clone <https://github.com/seitov4/inventory_mobile>
cd inventory_mobile
open UIKitPractice.xcodeproj
```

Then build and run the `UIKitPractice` scheme in Xcode.

## Notes

- Best experienced on a real device or a simulator with biometric support
- Screenshots can be added into `docs/screenshots/`

