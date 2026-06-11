//
//  InventiXProductsControl.swift
//  InventiXProductsControlExtension
//

import AppIntents
import Foundation
import SwiftUI
import WidgetKit

@main
struct InventiXProductsBundle: WidgetBundle {
    var body: some Widget {
        InventiXProductsWidget()
        InventiXProductsControl()
    }
}

struct InventiXProductsControl: ControlWidget {
    static let kind = "com.inventix.controls.products"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenProductsIntent()) {
                Label("Товары", systemImage: "shippingbox.fill")
            }
        }
        .displayName("Товары")
        .description("Открыть каталог товаров InventiX")
    }
}

struct OpenProductsIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть товары"
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Экран")
    var target: InventiXControlScreen

    init() {
        self.target = .products
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        ControlShortcutRouteWriter.save("com.inventix.shortcut.products")
        return .result(opensIntent: OpenURLIntent(URL(string: "inventix://products")!))
    }
}

extension OpenProductsIntent: OpenIntent {
    typealias Value = InventiXControlScreen
}

enum InventiXControlScreen: String, AppEnum {
    case products = "products"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "InventiX screen")
    static let caseDisplayRepresentations: [InventiXControlScreen: DisplayRepresentation] = [
        .products: DisplayRepresentation(title: "Товары")
    ]
}

private enum ControlShortcutRouteWriter {
    static func save(_ route: String) {
        let defaults = UserDefaults(suiteName: "group.Nurseit.UIKitPractice")
        defaults?.set(route, forKey: "inventix.pendingShortcutRoute")
        defaults?.synchronize()
    }
}

struct InventiXProductsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.inventix.widgets.products", provider: ProductsWidgetProvider()) { _ in
            ProductsWidgetView()
                .widgetURL(URL(string: "inventix://products"))
        }
        .configurationDisplayName("Товары")
        .description("Открыть каталог товаров InventiX")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

private struct ProductsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProductsWidgetEntry { ProductsWidgetEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (ProductsWidgetEntry) -> Void) { completion(ProductsWidgetEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProductsWidgetEntry>) -> Void) {
        completion(Timeline(entries: [ProductsWidgetEntry(date: Date())], policy: .never))
    }
}

private struct ProductsWidgetEntry: TimelineEntry {
    let date: Date
}

private struct ProductsWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularLayout
        case .accessoryRectangular:
            rectangularLayout
        default:
            systemSmallLayout
        }
    }

    private var circularLayout: some View {
        Image(systemName: "shippingbox.fill")
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .widgetAccentable()
            .widgetLabel("Товары")
            .containerBackground(Color.clear, for: .widget)
    }

    private var rectangularLayout: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "shippingbox.fill")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 1) {
                Text("Товары")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .widgetAccentable()
                    .lineLimit(1)
                Text("Открыть каталог")
                    .font(.system(.caption2, design: .rounded))
                    .lineLimit(1)
            }
        }
        .containerBackground(Color.clear, for: .widget)
    }

    private var systemSmallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .font(.title2.weight(.semibold))
            Text("Товары")
                .font(.headline)
            Text("Открыть каталог")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
