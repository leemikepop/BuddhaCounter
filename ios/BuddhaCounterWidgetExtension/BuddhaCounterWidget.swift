import WidgetKit
import SwiftUI

/// 小工具內建文字 (App 尚未同步資料、小工具選單說明時使用)。
/// 有同步資料時一律優先顯示 App 依使用者語言推送的文字。
/// 依系統語言：繁中 (Hant / TW / HK / MO)、簡中 (其他 zh)、其餘英文 —— 與 App 端 resolveAppLocale 規則一致。
enum WidgetStrings {
    enum Key {
        case title, description, streakPlaceholder, streakNone, targetPlaceholder
        case today, notConnected
    }

    private static let zhHant: [Key: String] = [
        .title: "念佛計數器",
        .description: "即時顯示今日念佛功課進度與連續精進天數。",
        .streakPlaceholder: "🔥 連續 3 天",
        .streakNone: "今日精進念佛",
        .targetPlaceholder: "今日功課",
        .today: "今日",
        .notConnected: "未連線 (無共享數據)",
    ]

    private static let zhHans: [Key: String] = [
        .title: "念佛计数器",
        .description: "实时显示今日念佛功课进度与连续精进天数。",
        .streakPlaceholder: "🔥 连续 3 天",
        .streakNone: "今日精进念佛",
        .targetPlaceholder: "今日功课",
        .today: "今日",
        .notConnected: "未连接 (无共享数据)",
    ]

    private static let en: [Key: String] = [
        .title: "Buddha Counter",
        .description: "Today's practice progress and streak at a glance.",
        .streakPlaceholder: "🔥 3-day streak",
        .streakNone: "Practice today",
        .targetPlaceholder: "Today's practice",
        .today: "Today",
        .notConnected: "Not connected (no shared data)",
    ]

    private enum Lang {
        case hant, hans, en
    }

    /// 依手機語言偏好清單順序取第一個支援的語言
    private static var lang: Lang {
        for preferred in Locale.preferredLanguages {
            let id = preferred.lowercased()
            if id.hasPrefix("zh") {
                if id.contains("hant") || id.hasSuffix("-tw") || id.hasSuffix("-hk") || id.hasSuffix("-mo") {
                    return .hant
                }
                return .hans
            }
            if id.hasPrefix("en") {
                return .en
            }
        }
        return .en
    }

    static func t(_ key: Key) -> String {
        let table: [Key: String]
        switch lang {
        case .hant: table = zhHant
        case .hans: table = zhHans
        case .en: table = en
        }
        return table[key] ?? ""
    }

    /// 尚未同步時的本週 / 本月文字
    static func weekly(_ count: Int) -> String {
        switch lang {
        case .hant: return "本週: \(count)聲"
        case .hans: return "本周: \(count)声"
        case .en: return "Week: \(count)"
        }
    }

    static func monthly(_ count: Int) -> String {
        switch lang {
        case .hant: return "本月: \(count)聲"
        case .hans: return "本月: \(count)声"
        case .en: return "Month: \(count)"
        }
    }
}

struct BuddhaWidgetEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let targetCount: Int
    let weeklyCount: Int
    let monthlyCount: Int
    let streakDays: Int
    let streakText: String
    let targetText: String
    let dateDisplay: String
    let widgetTitle: String
    let weeklyText: String
    let monthlyText: String
}

struct BuddhaWidgetProvider: TimelineProvider {
    /// 動態推導所有可能存在的候選 App Group ID（相容 Sideloadly、AltStore、TrollStore、原生開發與 TestFlight）
    private var candidateGroupIds: [String] {
        var groups = [
            "group.com.yichung.lee.count4",
            "group.app.CountApp"
        ]

        if let extBundleId = Bundle.main.bundleIdentifier {
            // 例: "app.CountApp.M4LWC77CK3.BuddhaCounterWidgetExtension"
            let cleanMainId = extBundleId
                .replacingOccurrences(of: ".BuddhaCounterWidgetExtension", with: "")
                .replacingOccurrences(of: ".WidgetExtension", with: "")

            groups.append("group.\(cleanMainId)")
            groups.append("group.\(extBundleId)")

            let parts = cleanMainId.split(separator: ".")
            if parts.count >= 2 {
                groups.append("group.\(parts[0]).\(parts[1])")
            }
        }

        // 去除重複值
        var uniqueGroups: [String] = []
        for g in groups {
            if !uniqueGroups.contains(g) && !g.isEmpty {
                uniqueGroups.append(g)
            }
        }
        return uniqueGroups
    }

    func placeholder(in context: Context) -> BuddhaWidgetEntry {
        BuddhaWidgetEntry(
            date: Date(),
            todayCount: 108,
            targetCount: 108,
            weeklyCount: 1080,
            monthlyCount: 3000,
            streakDays: 3,
            streakText: WidgetStrings.t(.streakPlaceholder),
            targetText: WidgetStrings.t(.targetPlaceholder),
            dateDisplay: WidgetStrings.t(.today),
            widgetTitle: WidgetStrings.t(.title),
            weeklyText: WidgetStrings.weekly(1080),
            monthlyText: WidgetStrings.monthly(3000)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BuddhaWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BuddhaWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // 縮短排程更新頻率至 15 分鐘，確保跨時段與背景同步
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> BuddhaWidgetEntry {
        var selectedPrefs: UserDefaults? = nil
        var bestTimestamp: Double = -1
        var fallbackPrefsWithData: UserDefaults? = nil

        for groupId in candidateGroupIds {
            // 驗證系統層級是否已為此 App Group 配發共享容器
            let hasSharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) != nil

            guard let prefs = UserDefaults(suiteName: groupId) else { continue }
            // 強制從磁碟同步最新數據，防範跨進程 CFPreferences 記憶體快取延遲
            prefs.synchronize()

            let hasTodayCount = prefs.object(forKey: "today_count") != nil
            let timestamp = prefs.double(forKey: "widget_update_timestamp")

            if hasSharedContainer && hasTodayCount && timestamp > bestTimestamp {
                bestTimestamp = timestamp
                selectedPrefs = prefs
            } else if fallbackPrefsWithData == nil && hasTodayCount {
                fallbackPrefsWithData = prefs
            }
        }

        let isConnected = (selectedPrefs != nil || fallbackPrefsWithData != nil)
        let activePrefs = selectedPrefs ?? fallbackPrefsWithData ?? UserDefaults.standard
        activePrefs.synchronize()

        let todayCount = activePrefs.integer(forKey: "today_count")
        let targetCount = activePrefs.integer(forKey: "target_count")
        let weeklyCount = activePrefs.integer(forKey: "weekly_count")
        let monthlyCount = activePrefs.integer(forKey: "monthly_count")
        let streakDays = activePrefs.integer(forKey: "streak_days")
        let streakText = activePrefs.string(forKey: "streak_text")
            ?? (streakDays > 0 ? WidgetStrings.t(.streakPlaceholder) : WidgetStrings.t(.streakNone))
        let targetText = isConnected
            ? (activePrefs.string(forKey: "target_text") ?? WidgetStrings.t(.targetPlaceholder))
            : WidgetStrings.t(.notConnected)
        let dateDisplay = activePrefs.string(forKey: "date_display") ?? ""
        let widgetTitle = activePrefs.string(forKey: "widget_title") ?? WidgetStrings.t(.title)
        let weeklyText = activePrefs.string(forKey: "weekly_text") ?? WidgetStrings.weekly(weeklyCount)
        let monthlyText = activePrefs.string(forKey: "monthly_text") ?? WidgetStrings.monthly(monthlyCount)

        return BuddhaWidgetEntry(
            date: Date(),
            todayCount: todayCount,
            targetCount: targetCount > 0 ? targetCount : 108,
            weeklyCount: weeklyCount,
            monthlyCount: monthlyCount,
            streakDays: streakDays,
            streakText: streakText,
            targetText: targetText,
            dateDisplay: dateDisplay,
            widgetTitle: widgetTitle,
            weeklyText: weeklyText,
            monthlyText: monthlyText
        )
    }
}

struct BuddhaCounterWidgetEntryView: View {
    var entry: BuddhaWidgetProvider.Entry

    var body: some View {
        contentView
            .applyWidgetBackground()
    }

    var contentView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.widgetTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                Spacer()
                Text(entry.streakText)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.todayCount)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text(entry.targetText)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.75))
            }

            Spacer()

            HStack {
                Text(entry.weeklyText)
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.65))
                Spacer()
                Text(entry.monthlyText)
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.65))
            }
        }
        .padding(14)
    }
}

extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.16, green: 0.14, blue: 0.11),
                Color(red: 0.09, green: 0.08, blue: 0.07)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                gradient
            }
        } else {
            self.background(gradient)
        }
    }
}

@main
struct BuddhaCounterWidget: Widget {
    let kind: String = "BuddhaCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BuddhaWidgetProvider()) { entry in
            BuddhaCounterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetStrings.t(.title))
        .description(WidgetStrings.t(.description))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
