import WidgetKit
import SwiftUI

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
}

struct BuddhaWidgetProvider: TimelineProvider {
    let appGroupIds = ["group.com.yichung.lee.count4", "group.app.CountApp"]

    func placeholder(in context: Context) -> BuddhaWidgetEntry {
        BuddhaWidgetEntry(
            date: Date(),
            todayCount: 108,
            targetCount: 108,
            weeklyCount: 1080,
            monthlyCount: 3000,
            streakDays: 3,
            streakText: "🔥 連續 3 天",
            targetText: "今日功課",
            dateDisplay: "今日"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BuddhaWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BuddhaWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> BuddhaWidgetEntry {
        var prefs: UserDefaults? = nil
        for groupId in appGroupIds {
            if let userDefaults = UserDefaults(suiteName: groupId) {
                if userDefaults.object(forKey: "today_count") != nil {
                    prefs = userDefaults
                    break
                }
                if prefs == nil {
                    prefs = userDefaults
                }
            }
        }
        let activePrefs = prefs ?? UserDefaults.standard

        let todayCount = activePrefs.integer(forKey: "today_count")
        let targetCount = activePrefs.integer(forKey: "target_count")
        let weeklyCount = activePrefs.integer(forKey: "weekly_count")
        let monthlyCount = activePrefs.integer(forKey: "monthly_count")
        let streakDays = activePrefs.integer(forKey: "streak_days")
        let streakText = activePrefs.string(forKey: "streak_text") ?? (streakDays > 0 ? "🔥 連續 \(streakDays) 天" : "今日精進念佛")
        let targetText = activePrefs.string(forKey: "target_text") ?? "今日功課"
        let dateDisplay = activePrefs.string(forKey: "date_display") ?? ""

        return BuddhaWidgetEntry(
            date: Date(),
            todayCount: todayCount,
            targetCount: targetCount > 0 ? targetCount : 108,
            weeklyCount: weeklyCount,
            monthlyCount: monthlyCount,
            streakDays: streakDays,
            streakText: streakText,
            targetText: targetText,
            dateDisplay: dateDisplay
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
                Text("念佛計數器")
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
                Text("本週: \(entry.weeklyCount)聲")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.65))
                Spacer()
                Text("本月: \(entry.monthlyCount)聲")
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
        .configurationDisplayName("念佛計數器")
        .description("即時顯示今日念佛功課進度與連續精進天數。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

