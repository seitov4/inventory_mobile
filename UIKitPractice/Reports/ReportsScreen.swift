//
//  ReportsScreen.swift
//  UIKitPractice
//

import Charts
import Observation
import SwiftUI
import UIKit

enum ReportDateRange: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return L10n.tr("reports.date.today")
        case .week: return L10n.tr("reports.date.week")
        case .month: return L10n.tr("reports.date.month")
        case .custom: return L10n.tr("reports.date.custom")
        }
    }
}

enum ReportOperationType: String, CaseIterable, Identifiable {
    case all
    case sale
    case productReturn
    case writeOff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return L10n.tr("reports.all")
        case .sale: return L10n.tr("reports.operation.sales")
        case .productReturn: return L10n.tr("reports.operation.returns")
        case .writeOff: return L10n.tr("reports.operation.write_offs")
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .sale: return "cart.fill"
        case .productReturn: return "arrow.uturn.backward.circle.fill"
        case .writeOff: return "minus.circle.fill"
        }
    }

    var apiValue: String? {
        switch self {
        case .all: return nil
        case .sale: return "SALE"
        case .productReturn: return "RETURN"
        case .writeOff: return "WRITE_OFF"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "SALE":
            self = .sale
        case "RETURN":
            self = .productReturn
        case "WRITE_OFF":
            self = .writeOff
        default:
            return nil
        }
    }
}

enum ReportMode: String, CaseIterable, Identifiable {
    case sales
    case revenue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sales: return L10n.tr("reports.mode.sales")
        case .revenue: return L10n.tr("reports.mode.revenue")
        }
    }
}

struct ReportTransaction: Identifiable, Equatable {
    let id: String
    let productName: String
    let category: String
    let quantity: Int
    let totalAmount: Double
    let date: Date
    let employeeName: String
    let operationType: ReportOperationType

    var totalAmountFormatted: String {
        AppCurrency.string(from: totalAmount)
    }
}

struct ReportDayRevenue: Identifiable, Equatable {
    let id: String
    let label: String
    let amount: Double
}

private struct ReportShareItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

enum ReportExportFormat: String, CaseIterable, Identifiable {
    case pdf
    case csv
    case json
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pdf: return L10n.tr("reports.export.format.pdf")
        case .csv: return L10n.tr("reports.export.format.csv")
        case .json: return L10n.tr("reports.export.format.json")
        case .text: return L10n.tr("reports.export.format.txt")
        }
    }

    var systemImage: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .text: return "doc.plaintext"
        }
    }
}

@Observable
final class ReportsViewModel {
    var dateRange: ReportDateRange = .week { didSet { reloadReports() } }
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() { didSet { reloadReports() } }
    var customEndDate: Date = Date() { didSet { reloadReports() } }
    var selectedProductOrCategory: String = "all" { didSet { reloadReports() } }
    var selectedEmployee: String = "all" { didSet { reloadReports() } }
    var selectedOperationType: ReportOperationType = .all { didSet { reloadReports() } }
    var reportMode: ReportMode = .sales

    private(set) var transactions: [ReportTransaction] = []
    private(set) var revenueBreakdown: [ReportDayRevenue] = []
    private(set) var revenueSummary: RevenueSummary = .empty
    private(set) var productOrCategoryOptions: [ReportsFilterOption] = [
        .init(id: "all", title: L10n.tr("reports.all"), kind: .all)
    ]
    private(set) var employeeOptions: [ReportsFilterOption] = [
        .init(id: "all", title: L10n.tr("reports.all"), kind: .all)
    ]
    private(set) var operationOptions: [ReportsOperationOption] = [
        .init(id: "all", type: .all, title: L10n.tr("reports.all"), isSupported: true)
    ]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: ReportsService

    init(service: ReportsService = .shared) {
        self.service = service
        loadReports()
    }

    var isOwner: Bool {
        UserSessionManager.shared.currentRole == .owner
    }

    var totalRevenue: Double {
        revenueSummary.totalRevenue
    }

    var totalRevenueFormatted: String {
        AppCurrency.string(from: totalRevenue)
    }

    var totalQuantity: Int {
        revenueSummary.itemsSold
    }

    var averageTransactionFormatted: String {
        AppCurrency.string(from: revenueSummary.averageOrderValue)
    }

    func loadReports() {
        loadFilterOptions()
        reloadReports()
    }

    func exportReport(format: ReportExportFormat) -> URL? {
        switch format {
        case .pdf:
            return exportPDF()
        case .csv:
            return exportTextFile(extension: "csv", contents: csvContents)
        case .json:
            return exportTextFile(extension: "json", contents: jsonContents)
        case .text:
            return exportTextFile(extension: "txt", contents: plainTextContents)
        }
    }

    private func exportPDF() -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("InventiX-Reports-\(Int(Date().timeIntervalSince1970)).pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let pageRect = CGRect(x: 36, y: 36, width: 523, height: 770)
                let title = NSMutableAttributedString(string: "InventiX\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 26, weight: .bold),
                    .foregroundColor: UIColor.label
                ])
                title.append(NSAttributedString(string: "\(L10n.tr("reports.title"))\n\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor.secondaryLabel
                ]))
                title.append(NSAttributedString(string: "\(L10n.tr("reports.revenue")): \(totalRevenueFormatted)\n", attributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]))
                title.append(NSAttributedString(string: "\(L10n.tr("reports.operations_count")): \(transactions.count) · \(totalQuantity) \(L10n.tr("reports.pieces_short"))\n\n", attributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel
                ]))

                let rows = transactions.prefix(18).map {
                    "\($0.productName) · \($0.quantity) \(L10n.tr("reports.pieces_short")) · \($0.totalAmountFormatted) · \($0.employeeName)"
                }.joined(separator: "\n")
                title.append(NSAttributedString(string: rows, attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: UIColor.label
                ]))
                title.draw(in: pageRect)
            }
            return url
        } catch {
            return nil
        }
    }

    private func exportTextFile(extension fileExtension: String, contents: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("InventiX-Reports-\(Int(Date().timeIntervalSince1970)).\(fileExtension)")

        do {
            try contents.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private var csvContents: String {
        let header = [
            L10n.tr("reports.column.date"),
            L10n.tr("reports.column.product"),
            L10n.tr("reports.column.category"),
            L10n.tr("reports.column.quantity"),
            L10n.tr("reports.column.amount"),
            L10n.tr("reports.column.employee"),
            L10n.tr("reports.column.operation_type")
        ].map(csvValue).joined(separator: ",")

        let rows = transactions.map { transaction in
            [
                exportDateFormatter.string(from: transaction.date),
                transaction.productName,
                transaction.category,
                "\(transaction.quantity)",
                "\(transaction.totalAmount)",
                transaction.employeeName,
                transaction.operationType.title
            ].map(csvValue).joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private var jsonContents: String {
        let rows = transactions.map { transaction in
            """
            {
              "date": "\(jsonValue(exportDateFormatter.string(from: transaction.date)))",
              "product_name": "\(jsonValue(transaction.productName))",
              "category": "\(jsonValue(transaction.category))",
              "quantity": \(transaction.quantity),
              "total_amount": \(transaction.totalAmount),
              "employee_name": "\(jsonValue(transaction.employeeName))",
              "operation_type": "\(transaction.operationType.apiValue ?? "ALL")"
            }
            """
        }.joined(separator: ",\n")

        return """
        {
          "report": "\(jsonValue(L10n.tr("reports.title")))",
          "total_revenue": \(totalRevenue),
          "orders_count": \(revenueSummary.ordersCount),
          "items_sold": \(revenueSummary.itemsSold),
          "average_order_value": \(revenueSummary.averageOrderValue),
          "transactions": [
        \(rows)
          ]
        }
        """
    }

    private var plainTextContents: String {
        var lines = [
            "InventiX",
            L10n.tr("reports.title"),
            "\(L10n.tr("reports.revenue")): \(totalRevenueFormatted)",
            "\(L10n.tr("reports.operations_count")): \(transactions.count)",
            "\(L10n.tr("reports.pieces")): \(totalQuantity)",
            ""
        ]

        lines += transactions.map {
            "\($0.productName) · \($0.quantity) \(L10n.tr("reports.pieces_short")) · \($0.totalAmountFormatted) · \($0.employeeName) · \(exportDateFormatter.string(from: $0.date))"
        }

        return lines.joined(separator: "\n")
    }

    private func csvValue(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func jsonValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private var exportDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }

    func optionTitle(for id: String, in options: [ReportsFilterOption]) -> String {
        options.first { $0.id == id }?.title ?? L10n.tr("reports.all")
    }

    func operationTitle(for type: ReportOperationType) -> String {
        operationOptions.first { $0.type == type }?.title ?? type.title
    }

    func isOperationSupported(_ type: ReportOperationType) -> Bool {
        operationOptions.first { $0.type == type }?.isSupported ?? true
    }

    private func loadFilterOptions() {
        service.fetchFilters { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let filters):
                productOrCategoryOptions = filters.productOrCategoryOptions
                employeeOptions = filters.employeeOptions
                operationOptions = filters.operationOptions

                if !self.productOrCategoryOptions.contains(where: { $0.id == self.selectedProductOrCategory }) {
                    self.selectedProductOrCategory = "all"
                }

                if !self.employeeOptions.contains(where: { $0.id == self.selectedEmployee }) {
                    self.selectedEmployee = "all"
                }

            case .failure(let error):
                errorMessage = AppError.map(error).localizedDescription
            }
        }
    }

    private func reloadReports() {
        let query = makeQuery()
        isLoading = true
        errorMessage = nil

        service.fetchTransactions(query: query) { [weak self] transactionsResult in
            guard let self else { return }
            switch transactionsResult {
            case .success(let transactions):
                self.transactions = transactions

            case .failure(let error):
                self.transactions = []
                self.errorMessage = AppError.map(error).localizedDescription
            }

            self.service.fetchRevenueDaily(query: query) { [weak self] revenueResult in
                guard let self else { return }
                self.isLoading = false

                switch revenueResult {
                case .success(let revenue):
                    self.revenueSummary = revenue.summary
                    self.revenueBreakdown = revenue.series

                case .failure(let error):
                    self.revenueSummary = .empty
                    self.revenueBreakdown = []
                    if self.errorMessage == nil {
                        self.errorMessage = AppError.map(error).localizedDescription
                    }
                }
            }
        }
    }

    private func makeQuery() -> ReportsQuery {
        let interval = selectedDateInterval
        let productOrCategory = productOrCategoryOptions.first { $0.id == selectedProductOrCategory }
        let employee = employeeOptions.first { $0.id == selectedEmployee }

        var productID: Int?
        var category: String?
        var employeeID: Int?

        if case .product(let value) = productOrCategory?.kind {
            productID = value
        }

        if case .category(let value) = productOrCategory?.kind {
            category = value
        }

        if case .employee(let value) = employee?.kind {
            employeeID = value
        }

        return ReportsQuery(
            from: interval.start,
            to: interval.end,
            productID: productID,
            category: category,
            employeeID: employeeID,
            operationType: selectedOperationType == .all ? nil : selectedOperationType,
            limit: 100,
            offset: 0
        )
    }

    private var selectedDateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch dateRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            return DateInterval(start: start, end: now)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return DateInterval(start: start, end: now)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? calendar.startOfDay(for: now)
            return DateInterval(start: start, end: now)
        case .custom:
            let start = min(customStartDate, customEndDate)
            let end = max(customStartDate, customEndDate)
            return DateInterval(start: calendar.startOfDay(for: start), end: calendar.startOfDay(for: end))
        }
    }
}

struct ReportsScreen: View {
    @State private var viewModel = ReportsViewModel()
    @State private var shareItem: ReportShareItem?
    @State private var showsExportOptions = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if viewModel.isOwner {
                content
            } else {
                lockedView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.tr("reports.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsExportOptions = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(!viewModel.isOwner || viewModel.transactions.isEmpty)
            }
        }
        .confirmationDialog(
            L10n.tr("reports.export.choose_format"),
            isPresented: $showsExportOptions,
            titleVisibility: .visible
        ) {
            ForEach(ReportExportFormat.allCases) { format in
                Button {
                    if let url = viewModel.exportReport(format: format) {
                        shareItem = ReportShareItem(url: url)
                    }
                } label: {
                    Label(format.title, systemImage: format.systemImage)
                }
            }

            Button(L10n.tr("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.tr("reports.export.format_message"))
        }
        .sheet(item: $shareItem) { item in
            ReportsActivityView(items: [item.url])
        }
        .onAppear {
            AppAnalytics.shared.trackScreen("reports")
        }
        .appLocalized()
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                filtersCard
                reportModePicker
                statusSection

                if viewModel.reportMode == .sales {
                    salesReportSection
                } else {
                    revenueReportSection
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 52, height: 52)
                .background(Color(.systemBlue).opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr("reports.owner_title"))
                    .font(.headline)
                Text(L10n.tr("reports.owner_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 10, y: 4)
    }

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("reports.filters"))
                .font(.headline)

            Picker(L10n.tr("reports.period"), selection: $viewModel.dateRange) {
                ForEach(ReportDateRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.dateRange == .custom {
                HStack(spacing: 12) {
                    DatePicker(L10n.tr("reports.from"), selection: $viewModel.customStartDate, displayedComponents: .date)
                    DatePicker(L10n.tr("reports.to"), selection: $viewModel.customEndDate, displayedComponents: .date)
                }
                .font(.caption)
            }

            filterPicker(
                title: L10n.tr("reports.filter.product_or_category"),
                systemImage: "shippingbox.fill",
                selection: $viewModel.selectedProductOrCategory,
                options: viewModel.productOrCategoryOptions
            )

            filterPicker(
                title: L10n.tr("reports.filter.employee"),
                systemImage: "person.crop.circle.fill",
                selection: $viewModel.selectedEmployee,
                options: viewModel.employeeOptions
            )

            Picker(L10n.tr("reports.filter.operation_type"), selection: $viewModel.selectedOperationType) {
                ForEach(viewModel.operationOptions) { option in
                    Label(
                        option.isSupported ? option.title : "\(option.title) · \(L10n.tr("reports.unsupported"))",
                        systemImage: option.type.systemImage
                    )
                    .tag(option.type)
                    .disabled(!option.isSupported)
                }
            }
            .pickerStyle(.menu)
            .reportFilterRowStyle(icon: "arrow.left.arrow.right.circle.fill")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 10, y: 4)
    }

    private func filterPicker(
        title: String,
        systemImage: String,
        selection: Binding<String>,
        options: [ReportsFilterOption]
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.id)
            }
        }
        .pickerStyle(.menu)
        .reportFilterRowStyle(icon: systemImage)
    }

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.isLoading {
            HStack(spacing: 10) {
                ProgressView()
                Text(L10n.tr("reports.loading"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let errorMessage = viewModel.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(.systemOrange))
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var reportModePicker: some View {
        Picker(L10n.tr("reports.report_type"), selection: $viewModel.reportMode) {
            ForEach(ReportMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var salesReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("reports.sales_report"))
                    .font(.headline)
                Spacer()
                Text("\(viewModel.transactions.count)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if viewModel.transactions.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.transactions) { transaction in
                    transactionRow(transaction)
                }
            }
        }
    }

    private var revenueReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                summaryCard(L10n.tr("reports.revenue"), viewModel.totalRevenueFormatted, "chart.line.uptrend.xyaxis")
                summaryCard(L10n.tr("reports.average_order"), viewModel.averageTransactionFormatted, "creditcard.fill")
                summaryCard(L10n.tr("reports.operations_count"), "\(viewModel.transactions.count)", "list.bullet.rectangle")
                summaryCard(L10n.tr("reports.pieces"), "\(viewModel.totalQuantity)", "number")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.tr("reports.revenue_report"))
                    .font(.headline)
                Text(L10n.tr("reports.revenue_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Chart(viewModel.revenueBreakdown) { item in
                    BarMark(
                        x: .value(L10n.tr("reports.column.date"), item.label),
                        y: .value(L10n.tr("reports.revenue"), item.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(.systemBlue), Color(.systemTeal).opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(shortCurrency(amount))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 10, y: 4)
        }
    }

    private func transactionRow(_ transaction: ReportTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.operationType.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(operationTint(transaction.operationType))
                .frame(width: 42, height: 42)
                .background(operationTint(transaction.operationType).opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(transaction.productName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(transaction.employeeName) · \(dateText(transaction.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                Text(transaction.totalAmountFormatted)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                Text("\(transaction.quantity) \(L10n.tr("reports.pieces_short"))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme).opacity(0.75), radius: 7, y: 2)
    }

    private func summaryCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color(.systemBlue))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme).opacity(0.65), radius: 7, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 58, height: 58)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(L10n.tr("reports.empty_title"))
                .font(.subheadline.weight(.semibold))
            Text(L10n.tr("reports.empty_subtitle"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var lockedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color(.systemBlue))
            Text(L10n.tr("reports.owner_only_title"))
                .font(.headline)
            Text(L10n.tr("reports.owner_only_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func operationTint(_ type: ReportOperationType) -> Color {
        switch type {
        case .all: return Color(.systemBlue)
        case .sale: return Color(.systemGreen)
        case .productReturn: return Color(.systemOrange)
        case .writeOff: return Color(.systemRed)
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}

private struct ReportsActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ReportFilterRowStyle: ViewModifier {
    let icon: String

    func body(content: Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 32, height: 32)
                .background(Color(.systemBlue).opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension View {
    func reportFilterRowStyle(icon: String) -> some View {
        modifier(ReportFilterRowStyle(icon: icon))
    }
}
