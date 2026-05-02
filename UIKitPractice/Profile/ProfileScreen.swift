import SwiftUI
import UIKit
import Combine

@MainActor
final class ProfileScreenViewModel: ObservableObject {
    @Published var fullName: String
    @Published var email: String
    @Published var phone: String
    @Published var role: String
    @Published var position: String
    @Published var avatarImage: UIImage?
    @Published var enterpriseViewModel: MyEnterpriseViewModel

    init(
        fullName: String = "Иван Иванов",
        email: String = "ivan@example.com",
        phone: String = "+7 700 123 45 67",
        role: String = "Администратор",
        position: String = "Управляющий магазином",
        enterpriseViewModel: MyEnterpriseViewModel? = nil
    ) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.role = role
        self.position = position
        self.enterpriseViewModel = enterpriseViewModel ?? MyEnterpriseViewModel.mock()
    }

    var initials: String {
        fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

struct ProfileScreen: View {
    @StateObject var viewModel: ProfileScreenViewModel

    let onAvatarTap: () -> Void
    let onEnterpriseTap: () -> Void
    let onPersonalDataTap: () -> Void
    let onSettingsTap: () -> Void
    let onChangePasswordTap: () -> Void
    let onLogoutTap: () -> Void

    @State private var hasAppeared = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ProfileHeaderCard(
                    fullName: viewModel.fullName,
                    role: viewModel.role,
                    initials: viewModel.initials,
                    avatarImage: viewModel.avatarImage,
                    onAvatarTap: onAvatarTap
                )
                .profileAppear(index: 0, active: hasAppeared)

                EnterpriseBannerCard(
                    enterprise: viewModel.enterpriseViewModel.enterprise,
                    employees: viewModel.enterpriseViewModel.employees,
                    onTap: onEnterpriseTap
                )
                .padding(.horizontal, 16)
                .profileAppear(index: 1, active: hasAppeared)

                ProfileGroupedCard(title: "Личные данные") {
                    ProfileActionRow(
                        icon: "envelope.fill",
                        title: "Email",
                        value: viewModel.email,
                        showsChevron: true,
                        action: onPersonalDataTap
                    )

                    ProfileDivider()

                    ProfileActionRow(
                        icon: "phone.fill",
                        title: "Телефон",
                        value: viewModel.phone,
                        showsChevron: true,
                        action: onPersonalDataTap
                    )

                    ProfileDivider()

                    ProfileActionRow(
                        icon: "briefcase.fill",
                        title: "Должность",
                        value: viewModel.position,
                        showsChevron: true,
                        action: onPersonalDataTap
                    )
                }
                .padding(.horizontal, 16)
                .profileAppear(index: 2, active: hasAppeared)

                ProfileGroupedCard(title: "Быстрые действия") {
                    ProfileActionRow(
                        icon: "bell.fill",
                        title: "Настройки",
                        value: "Настроить",
                        showsChevron: true,
                        action: onSettingsTap
                    )

                    ProfileDivider()

                    ProfileActionRow(
                        icon: "globe",
                        title: "Язык интерфейса",
                        value: Locale.current.language.languageCode?.identifier.uppercased() ?? "RU",
                        showsChevron: true,
                        action: onSettingsTap
                    )

                    ProfileDivider()

                    ProfileActionRow(
                        icon: "lock.fill",
                        title: "Сменить пароль",
                        value: nil,
                        showsChevron: true,
                        action: onChangePasswordTap
                    )
                }
                .padding(.horizontal, 16)
                .profileAppear(index: 3, active: hasAppeared)

                Button(action: onLogoutTap) {
                    Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(ProfileDestructiveButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .profileAppear(index: 4, active: hasAppeared)
            }
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                hasAppeared = true
            }
        }
    }
}

private struct ProfileHeaderCard: View {
    let fullName: String
    let role: String
    let initials: String
    let avatarImage: UIImage?
    let onAvatarTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onAvatarTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.95),
                                    Color.accentColor.opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    } else {
                        Text(initials)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Изменить фото профиля")

            VStack(spacing: 7) {
                Text(fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)

                Text(role)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemGroupedBackground),
                    Color.accentColor.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct EnterpriseBannerCard: View {
    let enterprise: EnterpriseInfo
    let employees: [Employee]
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var activeEmployeesCount: Int {
        employees.filter(\.isActive).count
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 5) {
                            Text(enterprise.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            Text("Ваше предприятие и команда")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    HStack(spacing: 8) {
                        EnterpriseStatBadge(text: "Сотрудников: \(employees.count)")
                        EnterpriseStatBadge(text: "Активных: \(activeEmployeesCount)")
                    }
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(colorScheme == .dark ? 0.55 : 0.72),
                        Color(.systemFill)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.accentColor.opacity(colorScheme == .dark ? 0.18 : 0.24), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(ScalePressButtonStyle())
        .accessibilityLabel("Моё предприятие")
    }
}

private struct EnterpriseStatBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.18), in: Capsule())
    }
}

private struct ProfileGroupedCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
            )
        }
    }
}

private struct ProfileActionRow: View {
    let icon: String
    let title: String
    let value: String?
    let showsChevron: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    )

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                if let value {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(ProfileRowButtonStyle())
    }
}

private struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.6))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }
}

private struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct ProfileRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(.tertiarySystemFill) : Color.clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ProfileDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.red)
            .background(Color.red.opacity(configuration.isPressed ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.red.opacity(0.55), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private extension View {
    func profileAppear(index: Int, active: Bool) -> some View {
        opacity(active ? 1 : 0)
            .offset(y: active ? 0 : 12)
            .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.04), value: active)
    }
}
