import SwiftUI
import Combine

struct EnterpriseInfo {
    let name: String
    let address: String
    let phone: String
    let email: String
    let taxId: String
}

struct Employee: Identifiable {
    let id: Int
    let fullName: String
    let role: String
    let phone: String
    let isActive: Bool
}

enum EnterpriseNotice: Equatable {
    case success(String)
    case error(String)

    var message: String {
        switch self {
        case .success(let message), .error(let message):
            return message
        }
    }

    var systemImage: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: return Color(.systemGreen)
        case .error: return Color(.systemOrange)
        }
    }
}

enum EmployeeRoleOption: String, CaseIterable, Identifiable {
    case manager
    case cashier
    case admin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manager: return L10n.tr("enterprise.employee.manager")
        case .cashier: return L10n.tr("enterprise.employee.cashier")
        case .admin: return L10n.tr("enterprise.employee.admin")
        }
    }
}

@MainActor
final class MyEnterpriseViewModel: ObservableObject {
    @Published var enterprise: EnterpriseInfo
    @Published var employees: [Employee]
    @Published var isLoading = false
    @Published var notice: EnterpriseNotice?
    private let service: EnterpriseService
    private var languageObserver: NSObjectProtocol?

    init(
        enterprise: EnterpriseInfo,
        employees: [Employee],
        service: EnterpriseService = .shared
    ) {
        self.enterprise = enterprise
        self.employees = employees
        self.service = service
        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.localizeMockEmployeeRoles()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    static func mock() -> MyEnterpriseViewModel {
        .init(
            enterprise: .init(
                name: "InventiX Market LLC",
                address: "Almaty, Abay Ave 120",
                phone: "+7 700 123 45 67",
                email: "contact@inventix.kz",
                taxId: "BIN 123456789012"
            ),
            employees: [
                .init(id: 1, fullName: "Aruzhan Sarsembayeva", role: L10n.tr("enterprise.employee.owner"), phone: "+7 701 000 11 22", isActive: true),
                .init(id: 2, fullName: "Dias Nurpeissov", role: L10n.tr("enterprise.employee.cashier"), phone: "+7 702 111 22 33", isActive: true),
                .init(id: 3, fullName: "Madina Orazova", role: L10n.tr("enterprise.employee.cashier"), phone: "+7 705 444 55 66", isActive: false),
                .init(id: 4, fullName: "Timur Abdrakhmanov", role: L10n.tr("enterprise.employee.admin"), phone: "+7 707 987 65 43", isActive: true)
            ]
        )
    }

    static func backend() -> MyEnterpriseViewModel {
        let viewModel = MyEnterpriseViewModel.mock()
        viewModel.load()
        return viewModel
    }

    func load() {
        isLoading = true
        service.fetchEnterprise { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let payload):
                    self.enterprise = payload.0
                    self.employees = payload.1
                case .failure(let error):
                    self.showNotice(.error(AppError.map(error).localizedDescription))
                }
            }
        }
    }

    func createEmployee(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        role: EmployeeRoleOption,
        password: String,
        completion: @escaping (Bool) -> Void
    ) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = Self.compactKazakhstanPhone(phone)
        let contact = trimmedEmail.isEmpty ? trimmedPhone : trimmedEmail
        let request = CreateEmployeeRequest(
            contact: contact,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role.rawValue,
            password: password
        )

        isLoading = true
        service.createEmployee(request: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.showNotice(.success(L10n.tr("enterprise.employee.created")))
                    self.load()
                    completion(true)
                case .failure(let error):
                    self.showNotice(.error(AppError.map(error).localizedDescription))
                    completion(false)
                }
            }
        }
    }

    func deleteEmployee(_ employee: Employee) {
        isLoading = true
        service.deleteEmployee(id: employee.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.employees.removeAll { $0.id == employee.id }
                    self.showNotice(.success(L10n.tr("enterprise.employee.deleted")))
                case .failure(let error):
                    self.showNotice(.error(AppError.map(error).localizedDescription))
                }
            }
        }
    }

    func showNotice(_ notice: EnterpriseNotice) {
        self.notice = notice
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            guard self?.notice == notice else { return }
            self?.notice = nil
        }
    }

    static func compactKazakhstanPhone(_ value: String) -> String {
        var digits = value.filter(\.isNumber)
        if digits.hasPrefix("7") || digits.hasPrefix("8") {
            digits.removeFirst()
        }
        return "+7" + String(digits.prefix(10))
    }

    private func localizeMockEmployeeRoles() {
        employees = employees.map { employee in
            let role: String
            switch employee.id {
            case 1:
                role = L10n.tr("enterprise.employee.owner")
            case 2, 3:
                role = L10n.tr("enterprise.employee.cashier")
            default:
                role = L10n.tr("enterprise.employee.admin")
            }
            return Employee(id: employee.id, fullName: employee.fullName, role: role, phone: employee.phone, isActive: employee.isActive)
        }
    }
}

struct MyEnterpriseScreen: View {
    @StateObject var viewModel: MyEnterpriseViewModel

    var body: some View {
        Form {
            Section(L10n.tr("enterprise.general")) {
                InfoRow(title: L10n.tr("enterprise.name"), value: viewModel.enterprise.name)
                InfoRow(title: L10n.tr("enterprise.address"), value: viewModel.enterprise.address)
                InfoRow(title: L10n.tr("Телефон"), value: viewModel.enterprise.phone)
                InfoRow(title: "Email", value: viewModel.enterprise.email)
                InfoRow(title: L10n.tr("enterprise.tax_id"), value: viewModel.enterprise.taxId)
            }

            Section {
                NavigationLink {
                    EmployeesScreen(viewModel: viewModel)
                } label: {
                    EmployeeManagementBanner(
                        employeeCount: viewModel.employees.count,
                        activeCount: viewModel.employees.filter(\.isActive).count
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .safeAreaInset(edge: .top) {
            if let notice = viewModel.notice {
                EnterpriseNoticeBanner(notice: notice)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.notice)
        .navigationTitle(L10n.tr("enterprise.my_enterprise"))
        .appLocalized()
    }
}

private struct EnterpriseNoticeBanner: View {
    let notice: EnterpriseNotice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notice.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(notice.tint)
                .frame(width: 38, height: 38)
                .background(notice.tint.opacity(0.14), in: Circle())

            Text(notice.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(notice.tint.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: notice.tint.opacity(0.18), radius: 14, y: 6)
    }
}

private struct EmployeeManagementBanner: View {
    let employeeCount: Int
    let activeCount: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(.systemIndigo),
                    Color(.systemCyan)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 128, height: 128)
                .offset(x: 36, y: -42)

            HStack(spacing: 14) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("enterprise.employee.management_title"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text(L10n.tr("enterprise.employee.management_subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        EmployeeBannerPill(text: L10n.format("enterprise.employee.total_format", employeeCount))
                        EmployeeBannerPill(text: L10n.format("enterprise.employee.active_format", activeCount))
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .frame(minHeight: 132)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(.systemIndigo).opacity(colorScheme == .dark ? 0.18 : 0.26), radius: 16, y: 8)
        .padding(.vertical, 6)
    }
}

private struct EmployeeBannerPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.16), in: Capsule())
    }
}

struct EmployeesScreen: View {
    @ObservedObject var viewModel: MyEnterpriseViewModel
    @State private var showsAddEmployee = false
    @State private var employeeToDelete: Employee?

    private var canManageEmployees: Bool {
        UserSessionManager.shared.currentRole == .owner
    }

    var body: some View {
        List {
            ForEach(viewModel.employees) { employee in
                EmployeeRow(employee: employee)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if canManageEmployees {
                            Button(role: .destructive) {
                                employeeToDelete = employee
                            } label: {
                                Label(L10n.tr("common.delete"), systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .navigationTitle(L10n.tr("enterprise.employees"))
        .toolbar {
            if canManageEmployees {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsAddEmployee = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .refreshable {
            viewModel.load()
        }
        .sheet(isPresented: $showsAddEmployee) {
            AddEmployeeScreen(viewModel: viewModel)
        }
        .confirmationDialog(
            L10n.tr("enterprise.employee.delete_title"),
            isPresented: Binding(
                get: { employeeToDelete != nil },
                set: { if !$0 { employeeToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.tr("common.delete"), role: .destructive) {
                if let employeeToDelete {
                    viewModel.deleteEmployee(employeeToDelete)
                }
                employeeToDelete = nil
            }
            Button(L10n.tr("common.cancel"), role: .cancel) {
                employeeToDelete = nil
            }
        } message: {
            Text(employeeToDelete?.fullName ?? "")
        }
        .safeAreaInset(edge: .top) {
            if let notice = viewModel.notice {
                EnterpriseNoticeBanner(notice: notice)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.notice)
        .appLocalized()
    }
}

private struct EmployeeRow: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(employee.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: employee.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                        .foregroundStyle(employee.isActive ? .green : .gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.fullName)
                    .font(.headline)
                Text(localizedRole(employee.role))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(employee.phone)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func localizedRole(_ role: String) -> String {
        switch role.lowercased() {
        case "owner":
            return L10n.tr("enterprise.employee.owner")
        case "admin":
            return L10n.tr("enterprise.employee.admin")
        case "manager":
            return L10n.tr("enterprise.employee.manager")
        case "cashier":
            return L10n.tr("enterprise.employee.cashier")
        case "staff", "employee":
            return L10n.tr("enterprise.employee.staff")
        default:
            return role
        }
    }
}

private struct AddEmployeeScreen: View {
    @ObservedObject var viewModel: MyEnterpriseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = "+7"
    @State private var password = ""
    @State private var role: EmployeeRoleOption = .cashier
    @State private var isPasswordVisible = false

    private var canSave: Bool {
        let compactPhone = MyEnterpriseViewModel.compactKazakhstanPhone(phone)
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || compactPhone.count == 12) &&
        password.count >= 6
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.tr("enterprise.employee.personal_data")) {
                    TextField(L10n.tr("enterprise.employee.first_name"), text: $firstName)
                        .textInputAutocapitalization(.words)
                    TextField(L10n.tr("enterprise.employee.last_name"), text: $lastName)
                        .textInputAutocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(L10n.tr("Телефон"), text: $phone)
                        .keyboardType(.phonePad)
                        .onChange(of: phone) { _, newValue in
                            let normalized = formattedKazakhstanPhone(newValue)
                            if normalized != newValue {
                                phone = normalized
                            }
                        }
                }

                Section {
                    Picker(L10n.tr("enterprise.employee.role"), selection: $role) {
                        ForEach(EmployeeRoleOption.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField(L10n.tr("enterprise.employee.temp_password"), text: $password)
                            } else {
                                SecureField(L10n.tr("enterprise.employee.temp_password"), text: $password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.tr(isPasswordVisible ? "auth.password_hide" : "auth.password_show"))
                    }
                } header: {
                    Text(L10n.tr("enterprise.employee.access"))
                } footer: {
                    Text(L10n.tr("enterprise.employee.password_hint"))
                }
            }
            .navigationTitle(L10n.tr("enterprise.employee.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.save")) {
                        viewModel.createEmployee(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            phone: phone,
                            role: role,
                            password: password
                        ) { didCreate in
                            if didCreate {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave || viewModel.isLoading)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let notice = viewModel.notice {
                EnterpriseNoticeBanner(notice: notice)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.notice)
        .appLocalized()
    }

    private func formattedKazakhstanPhone(_ value: String) -> String {
        var digits = value.filter(\.isNumber)
        if digits.hasPrefix("7") || digits.hasPrefix("8") {
            digits.removeFirst()
        }

        let suffix = String(digits.prefix(10))
        guard !suffix.isEmpty else { return "+7" }

        return "+7" + suffix
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}
