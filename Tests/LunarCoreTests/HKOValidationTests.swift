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

    struct HKOOnlineRow: Sendable, CustomStringConvertible {
        let solarYear: Int
        let solarMonth: Int
        let solarDay: Int
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

    static let onlineFixturesDir: URL = fixturesDir.appendingPathComponent("HKOOnline")
    static let onlineRegressionYears = [1933, 1954, 1978, 2057]
    static let recentFullYearEnd = Calendar.current.component(.year, from: Date()) - 1
    static let recentFullYearStart = recentFullYearEnd - 99
    static let recentFullYearRange = recentFullYearStart...recentFullYearEnd

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
            _ = semaphore.wait(timeout: .now() + 15)

            if let data = result {
                try? data.write(to: dest)
            }
        }
    }

    static func ensureOnlineFixtures() {
        let fm = FileManager.default
        try? fm.createDirectory(at: onlineFixturesDir, withIntermediateDirectories: true)

        let years = Set(onlineRegressionYears).union(recentFullYearRange)
        for year in years.sorted() {
            let filename = "T\(year)e.txt"
            let dest = onlineFixturesDir.appendingPathComponent(filename)
            if fm.fileExists(atPath: dest.path) { continue }

            guard let url = URL(
                string: "https://www.weather.gov.hk/en/gts/time/calendar/text/files/\(filename)"
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
            _ = semaphore.wait(timeout: .now() + 15)

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

    static let onlineEntries: [HKOOnlineRow] = {
        ensureOnlineFixtures()
        return onlineRegressionYears.flatMap(loadOnlineYearTable)
    }()

    static let recent100YearEntries: [HKOOnlineRow] = {
        ensureOnlineFixtures()
        return recentFullYearRange.flatMap(loadOnlineYearTable)
    }()

    private static func loadAllCSVs() -> [HKORow] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: fixturesDir.path) else { return [] }
        return files.filter { $0.hasSuffix(".csv") }.sorted()
            .flatMap { loadCSV(fixturesDir.appendingPathComponent($0)) }
    }

    private static func loadCSV(_ url: URL) -> [HKORow] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let dataLines = content.components(separatedBy: "\n").dropFirst()
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let rows = dataLines.compactMap(parseCSVLine)
        assert(rows.count == dataLines.count,
               "\(url.lastPathComponent): parsed \(rows.count)/\(dataLines.count) lines")
        return rows
    }

    private static func loadOnlineYearTable(_ year: Int) -> [HKOOnlineRow] {
        let url = onlineFixturesDir.appendingPathComponent("T\(year)e.txt")
        guard let content = try? String(contentsOf: url, encoding: .isoLatin1) else {
            return []
        }

        var rows: [HKOOnlineRow] = []
        var currentMonth: Int?
        var currentIsLeap = false

        for line in content.components(separatedBy: .newlines) {
            guard let (datePart, lunarPart) = parseOnlineColumns(line) else { continue }
            guard let solar = parseOnlineDate(datePart) else { continue }

            if let month = parseOnlineMonthStart(lunarPart) {
                currentIsLeap = (currentMonth == month)
                currentMonth = month
                rows.append(
                    HKOOnlineRow(
                        solarYear: solar.year,
                        solarMonth: solar.month,
                        solarDay: solar.day,
                        lunarMonth: month,
                        lunarDay: 1,
                        isLeapMonth: currentIsLeap
                    )
                )
                continue
            }

            guard
                let lunarDay = Int(lunarPart),
                let currentMonth
            else {
                continue
            }
            rows.append(
                HKOOnlineRow(
                    solarYear: solar.year,
                    solarMonth: solar.month,
                    solarDay: solar.day,
                    lunarMonth: currentMonth,
                    lunarDay: lunarDay,
                    isLeapMonth: currentIsLeap
                )
            )
        }

        return rows
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

    private static func parseOnlineColumns(_ line: String) -> (date: String, lunar: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.first?.isNumber == true else { return nil }

        let normalizedTabs = trimmed.replacingOccurrences(of: "\t", with: " ")
        let pattern = #"\s{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(normalizedTabs.startIndex..<normalizedTabs.endIndex, in: normalizedTabs)
        let collapsed = regex.stringByReplacingMatches(in: normalizedTabs, options: [], range: range, withTemplate: "|")
        let cols = collapsed.split(separator: "|", omittingEmptySubsequences: true).map {
            String($0).trimmingCharacters(in: .whitespaces)
        }
        guard cols.count >= 2 else { return nil }
        return (cols[0], cols[1])
    }

    private static func parseOnlineDate(_ text: String) -> (year: Int, month: Int, day: Int)? {
        let parts = text.split(separator: "/")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        return (year, month, day)
    }

    private static func parseOnlineMonthStart(_ text: String) -> Int? {
        guard text.contains("Lunar month") else { return nil }
        let parts = text.split(separator: " ")
        guard let ordinal = parts.first else { return nil }
        let digits = ordinal.prefix { $0.isNumber }
        return Int(digits)
    }

    // MARK: - Tests

    @Test("HKO fixture files present")
    func fixtureExists() {
        #expect(!Self.entries.isEmpty, "No CSV fixtures found — check network or Fixtures directory")
        let fm = FileManager.default
        let csvCount = (try? fm.contentsOfDirectory(atPath: Self.fixturesDir.path))?
            .filter { $0.hasSuffix(".csv") }.count ?? 0
        #expect(Self.entries.count >= csvCount * 365,
                "Only \(Self.entries.count) entries for \(csvCount) CSV files — some rows may have been lost")
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

    @Test("HKO online regression year tables present")
    func onlineFixturesExist() {
        #expect(!Self.onlineEntries.isEmpty, "No HKO online year-table fixtures found — check network or HKOOnline directory")
        let fm = FileManager.default
        let txtCount = (try? fm.contentsOfDirectory(atPath: Self.onlineFixturesDir.path))?
            .filter { $0.hasSuffix(".txt") }.count ?? 0
        let expectedCount = Set(Self.onlineRegressionYears).union(Self.recentFullYearRange).count
        #expect(txtCount >= expectedCount,
                "Only \(txtCount) online year tables found for \(expectedCount) required years")
    }

    @Test("HKO online regression daily match", arguments: HKOValidationTests.onlineEntries)
    func onlineRegressionDailyMatch(entry: HKOOnlineRow) {
        guard let solar = SolarDate(year: entry.solarYear, month: entry.solarMonth, day: entry.solarDay) else {
            Issue.record("Invalid solar date: \(entry)")
            return
        }

        guard let ourLunar = cal.lunarDate(from: solar) else {
            Issue.record("solarToLunar returned nil for \(entry)")
            return
        }

        #expect(ourLunar.month == entry.lunarMonth,
                "\(entry): month \(ourLunar.month) != HKO online \(entry.lunarMonth)")
        #expect(ourLunar.day == entry.lunarDay,
                "\(entry): day \(ourLunar.day) != HKO online \(entry.lunarDay)")
        #expect(ourLunar.isLeapMonth == entry.isLeapMonth,
                "\(entry): isLeap \(ourLunar.isLeapMonth) != HKO online \(entry.isLeapMonth)")
    }

    @Test("HKO online last 100 full Gregorian years match")
    func recent100YearOnlineMatch() {
        #expect(!Self.recent100YearEntries.isEmpty,
                "No recent 100-year HKO online entries found — check network or HKOOnline directory")

        for entry in Self.recent100YearEntries {
            guard let solar = SolarDate(year: entry.solarYear, month: entry.solarMonth, day: entry.solarDay) else {
                Issue.record("Invalid solar date: \(entry)")
                continue
            }

            guard let ourLunar = cal.lunarDate(from: solar) else {
                Issue.record("solarToLunar returned nil for \(entry)")
                continue
            }

            #expect(ourLunar.month == entry.lunarMonth,
                    "\(entry): month \(ourLunar.month) != HKO 100y \(entry.lunarMonth)")
            #expect(ourLunar.day == entry.lunarDay,
                    "\(entry): day \(ourLunar.day) != HKO 100y \(entry.lunarDay)")
            #expect(ourLunar.isLeapMonth == entry.isLeapMonth,
                    "\(entry): isLeap \(ourLunar.isLeapMonth) != HKO 100y \(entry.isLeapMonth)")
        }
    }

}
