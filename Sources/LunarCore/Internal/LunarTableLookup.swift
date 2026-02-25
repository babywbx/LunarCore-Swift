// O(1) lunar calendar lookup from pre-computed UInt32 table.
// Decodes the compact bit layout (SPEC 4.3) and provides
// solar ↔ lunar date conversion.

enum LunarTableLookup: Sendable, Equatable, Hashable {

    // Decoded lunar year info from UInt32.
    struct YearInfo: Sendable, Equatable, Hashable {
        let year: Int
        let monthDays: [Int]       // 12 regular month day counts (29 or 30)
        let leapMonth: Int         // 0 = no leap, 1-12 = leap after that month
        let leapMonthDays: Int     // 29 or 30, 0 if no leap
        let cnyMonth: Int          // 1 or 2
        let cnyDay: Int            // 1-31
    }

    // Decode a UInt32 entry for the given year.
    static func decode(year: Int) -> YearInfo? {
        let idx = year - LunarYearData.startYear
        guard idx >= 0, idx < LunarYearData.table.count else {
            return nil
        }
        return decode(bits: LunarYearData.table[idx], year: year)
    }

    static func decode(bits: UInt32, year: Int) -> YearInfo {
        // [30-19]: 12 month sizes
        var monthDays: [Int] = []
        for i in 0..<12 {
            let bit = (bits >> UInt32(30 - i)) & 1
            monthDays.append(bit == 1 ? 30 : 29)
        }

        // [18-15]: leap month index
        let leapMonth = Int((bits >> 15) & 0xF)

        // [14]: leap month size
        let leapMonthDays: Int
        if leapMonth > 0 {
            leapMonthDays = ((bits >> 14) & 1) == 1 ? 30 : 29
        } else {
            leapMonthDays = 0
        }

        // [13-9]: CNY day
        let cnyDay = Int((bits >> 9) & 0x1F)

        // [8]: CNY month (0=Jan, 1=Feb)
        let cnyMonth = ((bits >> 8) & 1) == 1 ? 2 : 1

        return YearInfo(
            year: year,
            monthDays: monthDays,
            leapMonth: leapMonth,
            leapMonthDays: leapMonthDays,
            cnyMonth: cnyMonth,
            cnyDay: cnyDay
        )
    }

    // Total days in a lunar year.
    static func yearDayCount(info: YearInfo) -> Int {
        var total = info.monthDays.reduce(0, +)
        if info.leapMonth > 0 {
            total += info.leapMonthDays
        }
        return total
    }

    // Day count for a specific lunar month.
    static func monthDayCount(info: YearInfo, month: Int, isLeap: Bool) -> Int? {
        guard (1...12).contains(month) else { return nil }
        if isLeap {
            guard info.leapMonth == month else { return nil }
            return info.leapMonthDays
        }
        return info.monthDays[month - 1]
    }

    // MARK: - Solar → Lunar conversion

    static func solarToLunar(_ solar: SolarDate) -> LunarDate? {
        // Try the lunar year that starts in the same Gregorian year or the year before.
        // CNY is always in Jan or Feb, so for dates before CNY we need previous lunar year.
        for lunarYear in [solar.year, solar.year - 1] {
            guard let info = decode(year: lunarYear) else { continue }
            guard let cny = SolarDate(year: lunarYear, month: info.cnyMonth, day: info.cnyDay) else {
                continue
            }
            guard solar >= cny else { continue }

            let dayOffset = daysBetween(from: cny, to: solar)
            guard dayOffset >= 0 else { continue }

            if let result = lunarDateFromOffset(info: info, dayOffset: dayOffset) {
                return result
            }
        }
        return nil
    }

    // MARK: - Lunar → Solar conversion

    static func lunarToSolar(_ lunar: LunarDate) -> SolarDate? {
        guard let info = decode(year: lunar.year) else { return nil }
        guard let cny = SolarDate(year: lunar.year, month: info.cnyMonth, day: info.cnyDay) else {
            return nil
        }

        // Count days from CNY to the target lunar date.
        var dayOffset = 0

        // Iterate through months in calendar order.
        for m in 1...12 {
            // Regular month m
            if m == lunar.month && !lunar.isLeapMonth {
                guard lunar.day <= info.monthDays[m - 1] else {
                    return nil
                }
                dayOffset += lunar.day - 1
                return addDays(to: cny, days: dayOffset)
            }
            dayOffset += info.monthDays[m - 1]

            // Leap month after regular month m
            if info.leapMonth == m {
                if m == lunar.month && lunar.isLeapMonth {
                    guard lunar.day <= info.leapMonthDays else {
                        return nil
                    }
                    dayOffset += lunar.day - 1
                    return addDays(to: cny, days: dayOffset)
                }
                dayOffset += info.leapMonthDays
            }
        }
        return nil
    }

    // MARK: - Helpers

    // Convert day offset from CNY to a LunarDate.
    private static func lunarDateFromOffset(info: YearInfo, dayOffset: Int) -> LunarDate? {
        var remaining = dayOffset

        for m in 1...12 {
            // Regular month m
            let regularDays = info.monthDays[m - 1]
            if remaining < regularDays {
                return LunarDate(year: info.year, month: m, day: remaining + 1, isLeapMonth: false)
            }
            remaining -= regularDays

            // Leap month after regular month m
            if info.leapMonth == m {
                if remaining < info.leapMonthDays {
                    return LunarDate(year: info.year, month: m, day: remaining + 1, isLeapMonth: true)
                }
                remaining -= info.leapMonthDays
            }
        }
        return nil
    }

    // Days between two SolarDates using JD subtraction.
    private static func daysBetween(from a: SolarDate, to b: SolarDate) -> Int {
        let jdA = JulianDay.fromGregorian(year: a.year, month: a.month, day: Double(a.day))
        let jdB = JulianDay.fromGregorian(year: b.year, month: b.month, day: Double(b.day))
        return Int((jdB - jdA).rounded())
    }

    // Add days to a SolarDate using JD arithmetic.
    private static func addDays(to date: SolarDate, days: Int) -> SolarDate? {
        let jd = JulianDay.fromGregorian(year: date.year, month: date.month, day: Double(date.day))
        let (year, month, day) = JulianDay.toGregorian(jd: jd + Double(days))
        return SolarDate(year: year, month: month, day: Int(day))
    }
}
