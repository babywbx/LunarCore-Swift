import Testing
import Foundation

@testable import LunarCore

// Cross-validation against Apple Foundation Calendar(.chinese).
// SPEC note: Apple's implementation has known bugs; differences are logged,
// and we assert a high match rate rather than 100% agreement.

@Suite("Cross-Validation: Foundation Calendar(.chinese)")
struct CrossValidationTests {

    let cal = LunarCalendar.shared

    static let chineseCal: Calendar = {
        var c = Calendar(identifier: .chinese)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return c
    }()

    static let gregorianCal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return c
    }()

    // Each year from 2000 to 2030, comparing every day.
    @Test("Foundation cross-validation by year", arguments: 2000...2030)
    func validateYear(year: Int) {
        var mismatches: [(solar: String, ours: String, apple: String)] = []
        var total = 0

        let greg = Self.gregorianCal
        let chinese = Self.chineseCal

        var date = greg.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = greg.date(from: DateComponents(year: year, month: 12, day: 31))!

        while date <= endDate {
            let comps = greg.dateComponents([.year, .month, .day], from: date)
            let solar = "\(comps.year!)-\(comps.month!)-\(comps.day!)"
            let appleComps = chinese.dateComponents([.month, .day, .isLeapMonth], from: date)
            let appleMonth = appleComps.month ?? -1
            let appleDay = appleComps.day ?? -1
            let appleLeap = appleComps.isLeapMonth ?? false
            let apple = "m\(appleMonth)d\(appleDay)\(appleLeap ? "L" : "")"

            guard let solarDate = SolarDate(year: comps.year!, month: comps.month!, day: comps.day!) else {
                mismatches.append((solar, "invalid-solar", apple))
                total += 1
                date = greg.date(byAdding: .day, value: 1, to: date)!
                continue
            }

            guard let ourLunar = cal.lunarDate(from: solarDate) else {
                mismatches.append((solar, "nil", apple))
                total += 1
                date = greg.date(byAdding: .day, value: 1, to: date)!
                continue
            }

            if ourLunar.month != appleMonth
                || ourLunar.day != appleDay
                || ourLunar.isLeapMonth != appleLeap
            {
                let ours = "m\(ourLunar.month)d\(ourLunar.day)\(ourLunar.isLeapMonth ? "L" : "")"
                mismatches.append((solar, ours, apple))
            }

            total += 1
            date = greg.date(byAdding: .day, value: 1, to: date)!
        }

        let matchRate = Double(total - mismatches.count) / Double(total)
        if !mismatches.isEmpty {
            let first5 = mismatches.prefix(5)
                .map { "\($0.solar): ours=\($0.ours) apple=\($0.apple)" }
                .joined(separator: "; ")
            let msg = "Year \(year): \(mismatches.count)/\(total) mismatches "
                + "(match rate: \(String(format: "%.2f%%", matchRate * 100))). "
                + "First 5: \(first5)"
            print(msg)
        }
        // Apple has known bugs; assert >= 99% match
        #expect(matchRate >= 0.99,
                "Year \(year) match rate \(matchRate) below 99%")
    }
}
