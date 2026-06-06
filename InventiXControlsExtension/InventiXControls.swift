//
//  InventiXControls.swift
//  InventiXControlsExtension
//

import AppIntents
import Foundation
import SwiftUI
import WidgetKit

@main
struct InventiXQuickSaleBundle: WidgetBundle {
    var body: some Widget {
        InventiXQuickSaleWidget()
        InventiXQuickSaleControl()
    }
}

struct InventiXQuickSaleControl: ControlWidget {
    static let kind = "com.inventix.controls.quickSale"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenQuickSaleIntent()) {
                Label("Продажа", systemImage: "barcode.viewfinder")
            }
        }
        .displayName("Продажа")
        .description("Открыть экран продажи InventiX")
    }
}

struct OpenQuickSaleIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть продажу"
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Экран")
    var target: InventiXControlScreen

    init() {
        self.target = .sales
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        ControlShortcutRouteWriter.save("com.inventix.shortcut.quickSale")
        return .result(opensIntent: OpenURLIntent(URL(string: "inventix://sales")!))
    }
}

extension OpenQuickSaleIntent: OpenIntent {
    typealias Value = InventiXControlScreen
}

enum InventiXControlScreen: String, AppEnum {
    case sales = "sales"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "InventiX screen")
    static let caseDisplayRepresentations: [InventiXControlScreen: DisplayRepresentation] = [
        .sales: DisplayRepresentation(title: "Продажа")
    ]
}

private enum ControlShortcutRouteWriter {
    static func save(_ route: String) {
        let defaults = UserDefaults(suiteName: "group.Nurseit.UIKitPractice")
        defaults?.set(route, forKey: "inventix.pendingShortcutRoute")
        defaults?.synchronize()
    }
}

struct InventiXQuickSaleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.inventix.widgets.quickSale", provider: QuickSaleWidgetProvider()) { _ in
            QuickSaleWidgetView()
                .widgetURL(URL(string: "inventix://sales"))
        }
        .configurationDisplayName("Продажа")
        .description("Открыть экран продажи InventiX")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

private struct QuickSaleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickSaleWidgetEntry {
        QuickSaleWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickSaleWidgetEntry) -> Void) {
        completion(QuickSaleWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickSaleWidgetEntry>) -> Void) {
        completion(Timeline(entries: [QuickSaleWidgetEntry(date: Date())], policy: .never))
    }
}

private struct QuickSaleWidgetEntry: TimelineEntry {
    let date: Date
}

private struct QuickSaleWidgetView: View {
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
        Image(systemName: "barcode.viewfinder")
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .widgetAccentable()
            .widgetLabel("Продажа")
    }

    private var rectangularLayout: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 1) {
                Text("Продажа")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .widgetAccentable()
                    .lineLimit(1)
                Text("Открыть сканер")
                    .font(.system(.caption2, design: .rounded))
                    .lineLimit(1)
            }
        }
    }

    private var systemSmallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "barcode.viewfinder")
                .font(.title2.weight(.semibold))
            Text("Продажа")
                .font(.headline)
            Text("Открыть сканер")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
