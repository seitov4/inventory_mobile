//
//  InventiXNotificationsControl.swift
//  InventiXNotificationsControlExtension
//

import AppIntents
import Foundation
import SwiftUI
import WidgetKit

@main
struct InventiXNotificationsBundle: WidgetBundle {
    var body: some Widget {
        InventiXNotificationsWidget()
        InventiXNotificationsControl()
    }
}

struct InventiXNotificationsControl: ControlWidget {
    static let kind = "com.inventix.controls.notifications"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenNotificationsIntent()) {
                Label("Уведомления", systemImage: "bell.badge.fill")
            }
        }
        .displayName("Уведомления")
        .description("Открыть уведомления InventiX")
    }
}

struct OpenNotificationsIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть уведомления"
    static let supportedModes: IntentModes = .foreground(.dynamic)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Экран")
    var target: InventiXControlScreen

    init() {
        self.target = .notifications
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        ControlShortcutRouteWriter.save("com.inventix.shortcut.notifications")
        return .result(opensIntent: OpenURLIntent(URL(string: "inventix://notifications")!))
    }
}

extension OpenNotificationsIntent: OpenIntent {
    typealias Value = InventiXControlScreen
}

enum InventiXControlScreen: String, AppEnum {
    case notifications = "notifications"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "InventiX screen")
    static let caseDisplayRepresentations: [InventiXControlScreen: DisplayRepresentation] = [
        .notifications: DisplayRepresentation(title: "Уведомления")
    ]
}

private enum ControlShortcutRouteWriter {
    static func save(_ route: String) {
        let defaults = UserDefaults(suiteName: "group.Nurseit.UIKitPractice")
        defaults?.set(route, forKey: "inventix.pendingShortcutRoute")
        defaults?.synchronize()
    }
}

struct InventiXNotificationsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.inventix.widgets.notifications", provider: NotificationsWidgetProvider()) { _ in
            NotificationsWidgetView()
                .widgetURL(URL(string: "inventix://notifications"))
        }
        .configurationDisplayName("Уведомления")
        .description("Открыть уведомления InventiX")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

private struct NotificationsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotificationsWidgetEntry { NotificationsWidgetEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (NotificationsWidgetEntry) -> Void) { completion(NotificationsWidgetEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NotificationsWidgetEntry>) -> Void) {
        completion(Timeline(entries: [NotificationsWidgetEntry(date: Date())], policy: .never))
    }
}

private struct NotificationsWidgetEntry: TimelineEntry {
    let date: Date
}

private struct NotificationsWidgetView: View {
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
        Image(systemName: "bell.badge.fill")
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .widgetAccentable()
            .widgetLabel("Уведомления")
            .containerBackground(Color.clear, for: .widget)
    }

    private var rectangularLayout: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "bell.badge.fill")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 1) {
                Text("Уведомления")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .widgetAccentable()
                    .lineLimit(1)
                Text("Открыть центр")
                    .font(.system(.caption2, design: .rounded))
                    .lineLimit(1)
            }
        }
        .containerBackground(Color.clear, for: .widget)
    }

    private var systemSmallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .font(.title2.weight(.semibold))
            Text("Уведомления")
                .font(.headline)
            Text("Открыть центр")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
