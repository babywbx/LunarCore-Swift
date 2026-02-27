import Testing
import Foundation

@testable import LunarCore

@Suite("HKO Validation")
struct HKOValidationTests {

    let cal = LunarCalendar.shared

    // MARK: - Types

    struct HKORow: Sendable, CustomStringConvertible {
        let solarYear: Int
        let solarMonth: Int
        let solarDay: Int
        let ganZhi: String
        let lunarMonth: Int
        let lunarDay: Int
        let isLeapMonth: Bool

        var description: String {
            "\(solarYear)-\(String(format: "%02d", solarMonth))-\(String(format: "%02d", solarDay))"
        }
    }

    // MARK: - Fixtures directory

    static let fixturesDir: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")

    // MARK: - CSV auto-download

    static func ensureFixtures() {
        let fm = FileManager.default
        try? fm.createDirectory(at: fixturesDir, withIntermediateDirectories: true)

        let currentYear = Calendar.current.component(.year, from: Date())
        for year in 2020...(currentYear + 2) {
            let filename = "nongli_calendar_\(year).csv"
            let dest = fixturesDir.appendingPathComponent(filename)
            if fm.fileExists(atPath: dest.path) { continue }

            guard let url = URL(
                string: "https://data.weather.gov.hk/weatherAPI/hko_data/calendar/nongli_calendar_\(year).csv"
            ) else { continue }

            let semaphore = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var result: Data?
            let task = URLSession.shared.dataTask(with: url) { data, response, _ in
                defer { semaphore.signal() }
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data, !data.isEmpty else { return }
                result = data
            }
            task.resume()
            semaphore.wait()

            if let data = result {
                try? data.write(to: dest)
            }
        }
    }

    // MARK: - CSV loading & parsing

    static let entries: [HKORow] = {
        ensureFixtures()
        return loadAllCSVs()
    }()

    private static func loadAllCSVs() -> [HKORow] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: fixturesDir.path) else { return [] }
        return files.filter { $0.hasSuffix(".csv") }.sorted()
            .flatMap { loadCSV(fixturesDir.appendingPathComponent($0)) }
    }

    private static func loadCSV(_ url: URL) -> [HKORow] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return content.components(separatedBy: "\n").dropFirst().compactMap(parseCSVLine)
    }

    private static let monthAbbrevMap: [String: Int] = [
        "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
        "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
    ]

    private static let lunarMonthMap: [(String, Int)] = [
        ("十一月", 11), ("十二月", 12),
        ("正月", 1), ("二月", 2), ("三月", 3), ("四月", 4),
        ("五月", 5), ("六月", 6), ("七月", 7), ("八月", 8),
        ("九月", 9), ("十月", 10),
    ]

    private static func parseCSVLine(_ line: String) -> HKORow? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let cols = trimmed.split(separator: ",", omittingEmptySubsequences: false)
        guard cols.count >= 5 else { return nil }

        // Gregorian date: "D-Mon-YY"
        let dateParts = cols[0].split(separator: "-")
        guard dateParts.count == 3,
              let day = Int(dateParts[0]),
              let month = monthAbbrevMap[String(dateParts[1])],
              let yy = Int(dateParts[2])
        else { return nil }
        let year = 2000 + yy

        // GanZhi: strip trailing "年"
        var ganZhi = String(cols[1])
        if ganZhi.hasSuffix("年") { ganZhi = String(ganZhi.dropLast()) }

        // Lunar month: check for leap prefix
        var lunarMonthStr = cols[3].trimmingCharacters(in: .whitespaces)
        let isLeap = lunarMonthStr.hasPrefix("閏") || lunarMonthStr.hasPrefix("闰")
        if isLeap { lunarMonthStr = String(lunarMonthStr.dropFirst()) }

        var lunarMonth: Int?
        for (name, num) in lunarMonthMap where lunarMonthStr == name {
            lunarMonth = num
            break
        }
        guard let lm = lunarMonth else { return nil }

        // Lunar day
        let lunarDayStr = cols[4].trimmingCharacters(in: .whitespaces)
        guard let ld = parseDay(lunarDayStr) else { return nil }

        return HKORow(
            solarYear: year, solarMonth: month, solarDay: day,
            ganZhi: ganZhi,
            lunarMonth: lm, lunarDay: ld, isLeapMonth: isLeap
        )
    }

    private static func parseDay(_ text: String) -> Int? {
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

    // MARK: - Tests

    @Test("HKO fixture files present")
    func fixtureExists() {
        #expect(!Self.entries.isEmpty, "No CSV fixtures found — check network or Fixtures directory")
        #expect(Self.entries.count >= 365, "Only \(Self.entries.count) entries, expected at least 1 year")
    }

    @Test("HKO daily match", arguments: HKOValidationTests.entries)
    func dailyMatch(entry: HKORow) {
        guard let solar = SolarDate(year: entry.solarYear, month: entry.solarMonth, day: entry.solarDay) else {
            Issue.record("Invalid solar date: \(entry)")
            return
        }

        guard let ourLunar = cal.lunarDate(from: solar) else {
            Issue.record("solarToLunar returned nil for \(entry)")
            return
        }

        #expect(ourLunar.month == entry.lunarMonth,
                "\(entry): month \(ourLunar.month) != HKO \(entry.lunarMonth)")
        #expect(ourLunar.day == entry.lunarDay,
                "\(entry): day \(ourLunar.day) != HKO \(entry.lunarDay)")
        #expect(ourLunar.isLeapMonth == entry.isLeapMonth,
                "\(entry): isLeap \(ourLunar.isLeapMonth) != HKO \(entry.isLeapMonth)")

        let ourGanZhi = cal.yearGanZhi(for: ourLunar.year).chinese
        #expect(ourGanZhi == entry.ganZhi,
                "\(entry): ganZhi \(ourGanZhi) != HKO \(entry.ganZhi)")
    }


}
