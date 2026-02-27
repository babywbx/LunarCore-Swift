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

    // Decode once to avoid repeated bit unpacking and tiny array allocations in hot paths.
    private static let decodedTable: [YearInfo] = LunarYearData.table.enumerated().map { offset, bits in
        decode(bits: bits, year: LunarYearData.startYear + offset)
    }

    // Decode a UInt32 entry for the given year.
    static func decode(year: Int) -> YearInfo? {
        let idx = year - LunarYearData.startYear
        guard idx >= 0, idx < decodedTable.count else {
            return nil
        }
        return decodedTable[idx]
    }

    static func decode(bits: UInt32, year: Int) -> YearInfo {
        // [30-19]: 12 month sizes
        var monthDays: [Int] = []
        monthDays.reserveCapacity(12)
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
        // CNY is always in Jan/Feb, so only current Gregorian year and previous year can match.
        if let result = solarToLunar(solar, lunarYear: solar.year) {
            return result
        }
        return solarToLunar(solar, lunarYear: solar.year - 1)
    }

    // MARK: - Lunar → Solar conversion

    static func lunarToSolar(_ lunar: LunarDate) -> SolarDate? {
        guard let info = decode(year: lunar.year) else { return nil }
        let cny = SolarDate(uncheckedYear: lunar.year, month: info.cnyMonth, day: info.cnyDay)

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

    private static func solarToLunar(_ solar: SolarDate, lunarYear: Int) -> LunarDate? {
        guard let info = decode(year: lunarYear) else { return nil }
        let cny = SolarDate(uncheckedYear: lunarYear, month: info.cnyMonth, day: info.cnyDay)
        guard solar >= cny else { return nil }

        let dayOffset = daysBetween(from: cny, to: solar)
        guard dayOffset >= 0 else { return nil }

        return lunarDateFromOffset(info: info, dayOffset: dayOffset)
    }

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
        daysFromCivil(year: b.year, month: b.month, day: b.day)
        - daysFromCivil(year: a.year, month: a.month, day: a.day)
    }

    // Add days to a SolarDate using exact proleptic Gregorian arithmetic.
    private static func addDays(to date: SolarDate, days: Int) -> SolarDate? {
        let absolute = daysFromCivil(year: date.year, month: date.month, day: date.day) + days
        let (year, month, day) = civilFromDays(absolute)
        return SolarDate(uncheckedYear: year, month: month, day: day)
    }

    // Howard Hinnant's civil date conversion algorithms (exact integer Gregorian arithmetic).
    private static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let adjustedYear = year - (month <= 2 ? 1 : 0)
        let era = adjustedYear >= 0 ? adjustedYear / 400 : (adjustedYear - 399) / 400
        let yoe = adjustedYear - era * 400
        let mp = month + (month > 2 ? -3 : 9)
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    private static func civilFromDays(_ z: Int) -> (year: Int, month: Int, day: Int) {
        let shifted = z + 719_468
        let era = shifted >= 0 ? shifted / 146_097 : (shifted - 146_096) / 146_097
        let doe = shifted - era * 146_097
        let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let day = doy - (153 * mp + 2) / 5 + 1
        let month = mp + (mp < 10 ? 3 : -9)
        let year = y + (month <= 2 ? 1 : 0)
        return (year, month, day)
    }
}
