//
//  InventiXAnalyticsControl.swift
//  InventiXAnalyticsControlExtension
//

import AppIntents
import Foundation
import SwiftUI
import WidgetKit

@main
struct InventiXAnalyticsBundle: WidgetBundle {
    var body: some Widget {
        InventiXAnalyticsWidget()
        InventiXAnalyticsControl()
    }
}

struct InventiXAnalyticsControl: ControlWidget {
    static let kind = "com.inventix.controls.analytics"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenAnalyticsIntent()) {
                Label("Аналитика", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .displayName("Аналитика")
        .description("Открыть аналитику InventiX")
    }
}

struct OpenAnalyticsIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть аналитику"
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Экран")
    var target: InventiXControlScreen

    init() {
        self.target = .analytics
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        ControlShortcutRouteWriter.save("com.inventix.shortcut.analytics")
        return .result(opensIntent: OpenURLIntent(URL(string: "inventix://analytics")!))
    }
}

extension OpenAnalyticsIntent: OpenIntent {
    typealias Value = InventiXControlScreen
}

enum InventiXControlScreen: String, AppEnum {
    case analytics = "analytics"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "InventiX screen")
    static let caseDisplayRepresentations: [InventiXControlScreen: DisplayRepresentation] = [
        .analytics: DisplayRepresentation(title: "Аналитика")
    ]
}

private enum ControlShortcutRouteWriter {
    static func save(_ route: String) {
        let defaults = UserDefaults(suiteName: "group.Nurseit.UIKitPractice")
        defaults?.set(route, forKey: "inventix.pendingShortcutRoute")
        defaults?.synchronize()
    }
}

struct InventiXAnalyticsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.inventix.widgets.analytics", provider: AnalyticsWidgetProvider()) { _ in
            AnalyticsWidgetView()
                .widgetURL(URL(string: "inventix://analytics"))
        }
        .configurationDisplayName("Аналитика")
        .description("Открыть аналитику InventiX")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

private struct AnalyticsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalyticsWidgetEntry { AnalyticsWidgetEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (AnalyticsWidgetEntry) -> Void) { completion(AnalyticsWidgetEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalyticsWidgetEntry>) -> Void) {
        completion(Timeline(entries: [AnalyticsWidgetEntry(date: Date())], policy: .never))
    }
}

private struct AnalyticsWidgetEntry: TimelineEntry {
    let date: Date
}

private struct AnalyticsWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .accessoryCircular {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .widgetLabel("Аналитика")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2.weight(.semibold))
                Text("Аналитика")
                    .font(.headline)
                Text("Открыть отчеты")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
