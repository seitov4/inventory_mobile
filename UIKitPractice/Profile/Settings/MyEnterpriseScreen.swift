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

@MainActor
final class MyEnterpriseViewModel: ObservableObject {
    @Published var enterprise: EnterpriseInfo
    @Published var employees: [Employee]

    init(enterprise: EnterpriseInfo, employees: [Employee]) {
        self.enterprise = enterprise
        self.employees = employees
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
                .init(id: 1, fullName: "Aruzhan Sarsembayeva", role: "Owner", phone: "+7 701 000 11 22", isActive: true),
                .init(id: 2, fullName: "Dias Nurpeissov", role: "Cashier", phone: "+7 702 111 22 33", isActive: true),
                .init(id: 3, fullName: "Madina Orazova", role: "Cashier", phone: "+7 705 444 55 66", isActive: false),
                .init(id: 4, fullName: "Timur Abdrakhmanov", role: "Admin", phone: "+7 707 987 65 43", isActive: true)
            ]
        )
    }
}

struct MyEnterpriseScreen: View {
    @StateObject var viewModel: MyEnterpriseViewModel

    var body: some View {
        Form {
            Section("Общие данные") {
                InfoRow(title: "Название", value: viewModel.enterprise.name)
                InfoRow(title: "Адрес", value: viewModel.enterprise.address)
                InfoRow(title: "Телефон", value: viewModel.enterprise.phone)
                InfoRow(title: "Email", value: viewModel.enterprise.email)
                InfoRow(title: "ИИН/БИН", value: viewModel.enterprise.taxId)
            }

            Section("Команда") {
                NavigationLink {
                    EmployeesScreen(employees: viewModel.employees)
                } label: {
                    HStack {
                        Label("Сотрудники", systemImage: "person.3.fill")
                        Spacer()
                        Text("\(viewModel.employees.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Мое предприятие")
    }
}

struct EmployeesScreen: View {
    let employees: [Employee]

    var body: some View {
        List(employees) { employee in
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
                    Text(employee.role)
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
        .navigationTitle("Сотрудники")
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

