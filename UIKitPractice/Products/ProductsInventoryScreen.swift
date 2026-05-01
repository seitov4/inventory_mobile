import SwiftUI
import Combine

@MainActor
final class ProductsInventoryState: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedFilter: InventoryFilter = .all
    @Published var products: [Product] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

    private let viewModel: ProductsViewModel

    init(viewModel: ProductsViewModel) {
        self.viewModel = viewModel
        bind()
    }

    var filteredProducts: [Product] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return products.filter { product in
            let matchesName = query.isEmpty || product.name.lowercased().contains(query)
            return matchesName && selectedFilter.matches(product.quantity)
        }
    }

    var totalCount: Int { products.count }
    var lowStockCount: Int { products.filter { $0.quantity < 5 }.count }

    func load() {
        isLoading = true
        viewModel.loadProducts()
    }

    private func bind() {
        viewModel.onProductsLoaded = { [weak self] products, _ in
            guard let self else { return }
            self.products = products
        }
        viewModel.onLoadingStateChanged = { [weak self] loading in
            self?.isLoading = loading
        }
        viewModel.onError = { [weak self] message in
            self?.errorMessage = message
        }
    }
}

enum InventoryFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case normal = "Нормальный запас"
    case low = "Мало"
    case critical = "Критично мало"

    var id: String { rawValue }

    func matches(_ quantity: Int) -> Bool {
        switch self {
        case .all: return true
        case .normal: return quantity >= 5
        case .low: return (2...4).contains(quantity)
        case .critical: return quantity < 2
        }
    }
}

private enum InventoryStatus {
    case normal
    case low
    case critical

    init(quantity: Int) {
        if quantity < 2 {
            self = .critical
        } else if quantity < 5 {
            self = .low
        } else {
            self = .normal
        }
    }

    var title: String {
        switch self {
        case .normal: return "В наличии"
        case .low: return "Мало"
        case .critical: return "Критично"
        }
    }
}

struct ProductsInventoryScreen: View {
    @StateObject var state: ProductsInventoryState
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                statsGrid
                searchField
                filterTabs
                productsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 20)
        }
        .background(InventoryTokens.background.ignoresSafeArea())
        .onAppear {
            if state.products.isEmpty {
                state.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Товары")
                .font(.system(size: 30, weight: .bold, design: .default))
                .foregroundStyle(InventoryTokens.foreground)

            Text("Управление остатками товаров")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(InventoryTokens.mutedForeground)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(
                label: "ВСЕГО ТОВАРОВ",
                value: state.isLoading ? nil : "\(state.totalCount)",
                icon: "shippingbox.fill",
                iconColor: InventoryTokens.accentForeground,
                iconBg: InventoryTokens.accent
            )

            StatCard(
                label: "МАЛО НА СКЛАДЕ",
                value: state.isLoading ? nil : "\(state.lowStockCount)",
                icon: "exclamationmark.triangle.fill",
                iconColor: InventoryTokens.warning,
                iconBg: InventoryTokens.warning.opacity(0.1)
            )
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(InventoryTokens.mutedForeground)

            TextField("Поиск товара", text: $state.searchText)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InventoryTokens.muted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(searchFocused ? InventoryTokens.primary.opacity(0.6) : .clear, lineWidth: 1)
        )
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InventoryFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            state.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(state.selectedFilter == filter ? Color.white : InventoryTokens.foreground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(state.selectedFilter == filter ? InventoryTokens.primary : InventoryTokens.muted)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var productsCard: some View {
        VStack(spacing: 0) {
            if state.isLoading {
                ForEach(0..<6, id: \.self) { index in
                    SkeletonRow()
                    if index < 5 { divider }
                }
            } else if state.filteredProducts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(InventoryTokens.mutedForeground.opacity(0.5))
                    Text("Товары не найдены")
                        .font(.system(size: 14))
                        .foregroundStyle(InventoryTokens.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 56)
            } else {
                ForEach(Array(state.filteredProducts.enumerated()), id: \.element.id) { index, product in
                    ProductRow(product: product)
                    if index < state.filteredProducts.count - 1 { divider }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(InventoryTokens.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(InventoryTokens.border, lineWidth: 1)
        )
        .shadow(
            color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.06),
            radius: 4,
            x: 0,
            y: 2
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(InventoryTokens.border)
            .frame(height: 1)
    }
}

private struct StatCard: View {
    let label: String
    let value: String?
    let icon: String
    let iconColor: Color
    let iconBg: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(InventoryTokens.mutedForeground)
                Spacer()
                Circle()
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconColor)
                    )
            }

            if let value {
                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(InventoryTokens.foreground)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(InventoryTokens.muted)
                    .frame(width: 86, height: 32)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(InventoryTokens.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(InventoryTokens.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

private struct ProductRow: View {
    let product: Product

    private var status: InventoryStatus { .init(quantity: product.quantity) }
    private var statusColor: Color {
        switch status {
        case .normal: return InventoryTokens.success
        case .low: return InventoryTokens.warning
        case .critical: return InventoryTokens.destructive
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(product.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(InventoryTokens.foreground)
                .lineLimit(1)

            Spacer(minLength: 12)

            Text(status.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(statusColor.opacity(0.1))
                )

            Text("\(product.quantity)")
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(InventoryTokens.foreground)
                .frame(minWidth: 22, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(InventoryTokens.muted)
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(InventoryTokens.muted)
                .frame(width: 130, height: 14)

            Spacer()

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(InventoryTokens.muted)
                .frame(width: 72, height: 24)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(InventoryTokens.muted)
                .frame(width: 26, height: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private enum InventoryTokens {
    static let background = Color(.systemGroupedBackground)
    static let foreground = Color.primary
    static let card = Color(.systemBackground)
    static let primary = Color.accentColor
    static let muted = Color(.secondarySystemGroupedBackground)
    static let mutedForeground = Color.secondary
    static let accent = Color(.systemBlue).opacity(0.12)
    static let accentForeground = Color(.systemBlue)
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let destructive = Color(.systemRed)
    static let border = Color(.separator).opacity(0.35)
}

