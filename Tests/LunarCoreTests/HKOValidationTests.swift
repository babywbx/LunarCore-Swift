import Testing
import Foundation

@testable import LunarCore

// Validates our conversion against Hong Kong Observatory public data.
// Fixture: Tests/LunarCoreTests/Fixtures/hko_data.json
// Generate with: swift Scripts/fetch_hko.swift

@Suite("HKO Validation")
struct HKOValidationTests {

    let cal = LunarCalendar.shared

    // MARK: - Test entry type

    struct HKOEntry: Codable, Sendable, CustomStringConvertible {
        let date: String      // "YYYY-MM-DD"
        let lunarYear: String // "乙巳年，蛇"
        let lunarDate: String // "正月初一" or "閏六月廿七"

        var description: String { date }
    }

    // MARK: - Fixture loading

    static let entries: [HKOEntry] = {
        let fixtureURL = Bundle.module.url(
            forResource: "hko_data",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) ?? Bundle.module.url(forResource: "hko_data", withExtension: "json")
            ?? URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("hko_data.json")
        guard
            let data = try? Data(contentsOf: fixtureURL),
            let entries = try? JSONDecoder().decode([HKOEntry].self, from: data)
        else {
            return []
        }
        return entries
    }()

    // MARK: - Tests

    @Test("HKO fixture file is present and non-trivial")
    func fixtureExists() {
        #expect(!Self.entries.isEmpty, "hko_data.json not found or empty. Run: swift Scripts/fetch_hko.swift")
        #expect(Self.entries.count >= 365, "HKO fixture has only \(Self.entries.count) entries, expected at least 1 year")
    }

    @Test("HKO daily match", arguments: HKOValidationTests.entries)
    func dailyMatch(entry: HKOEntry) {
        // Parse solar date
        let parts = entry.date.split(separator: "-")
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2]),
            let solar = SolarDate(year: year, month: month, day: day)
        else {
            Issue.record("Invalid date format: \(entry.date)")
            return
        }

        // Our conversion
        guard let ourLunar = cal.lunarDate(from: solar) else {
            Issue.record("solarToLunar returned nil for \(entry.date)")
            return
        }

        // Parse HKO lunar date
        guard let hko = parseLunarDate(entry.lunarDate) else {
            Issue.record("Failed to parse HKO lunar date: \(entry.lunarDate)")
            return
        }

        // Compare month, day, isLeapMonth
        #expect(ourLunar.month == hko.month,
                "\(entry.date): month \(ourLunar.month) != HKO \(hko.month)")
        #expect(ourLunar.day == hko.day,
                "\(entry.date): day \(ourLunar.day) != HKO \(hko.day)")
        #expect(ourLunar.isLeapMonth == hko.isLeap,
                "\(entry.date): isLeap \(ourLunar.isLeapMonth) != HKO \(hko.isLeap)")

        // Verify GanZhi year
        let hkoGanZhi = String(entry.lunarYear.prefix(2))
        let ourGanZhi = cal.yearGanZhi(for: ourLunar.year).chinese
        #expect(ourGanZhi == hkoGanZhi,
                "\(entry.date): ganZhi \(ourGanZhi) != HKO \(hkoGanZhi)")
    }

    // MARK: - HKO Chinese text parser

    struct ParsedLunarDate {
        let month: Int
        let day: Int
        let isLeap: Bool
    }

    func parseLunarDate(_ text: String) -> ParsedLunarDate? {
        var s = text
        // Check for leap month prefix (traditional Chinese 閏)
        let isLeap = s.hasPrefix("閏") || s.hasPrefix("闰")
        if isLeap {
            s = String(s.dropFirst())
        }

        // Parse month
        let monthMap: [(String, Int)] = [
            ("十一月", 11), ("十二月", 12),
            ("正月", 1), ("二月", 2), ("三月", 3), ("四月", 4),
            ("五月", 5), ("六月", 6), ("七月", 7), ("八月", 8),
            ("九月", 9), ("十月", 10),
        ]

        var month: Int?
        for (name, num) in monthMap {
            if s.hasPrefix(name) {
                month = num
                s = String(s.dropFirst(name.count))
                break
            }
        }
        guard let month else { return nil }

        // Parse day
        guard let day = parseDay(s) else { return nil }

        return ParsedLunarDate(month: month, day: day, isLeap: isLeap)
    }

    private func parseDay(_ text: String) -> Int? {
        let dayMap: [String: Int] = [
            "初一": 1, "初二": 2, "初三": 3, "初四": 4, "初五": 5,
            "初六": 6, "初七": 7, "初八": 8, "初九": 9, "初十": 10,
            "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15,
            "十六": 16, "十七": 17, "十八": 18, "十九": 19, "二十": 20,
            "廿一": 21, "廿二": 22, "廿三": 23, "廿四": 24, "廿五": 25,
            "廿六": 26, "廿七": 27, "廿八": 28, "廿九": 29, "三十": 30,
        ]
        return dayMap[text]
    }
}
