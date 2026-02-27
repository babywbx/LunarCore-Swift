import Foundation

/// Chinese lunar calendar engine.
///
/// Thread-safe singleton providing bidirectional solar/lunar conversion,
/// 24 solar terms, GanZhi (stems-branches), zodiac, and lunar birthday calculation.
/// Supported range: 1900–2100.
///
/// ```swift
/// let cal = LunarCalendar.shared
/// let lunar = cal.lunarDate(from: SolarDate(year: 2025, month: 1, day: 29)!)
/// ```
public final class LunarCalendar: Sendable {

    /// Shared singleton instance.
    public static let shared = LunarCalendar()

    /// Library version string.
    public static let version = "1.0.0"

    /// The range of lunar years supported by this library.
    public var supportedYearRange: ClosedRange<Int> { 1900...2100 }

    private let solarTermCache = SolarTermCache()

    /// Creates a new `LunarCalendar` instance.
    public init() {}

    // MARK: - Conversion

    /// Converts a solar (Gregorian) date to a lunar date. Returns `nil` if out of range.
    public func lunarDate(from solar: SolarDate) -> LunarDate? {
        LunarTableLookup.solarToLunar(solar)
    }

    /// Converts a lunar date to a solar (Gregorian) date. Returns `nil` if out of range.
    public func solarDate(from lunar: LunarDate) -> SolarDate? {
        LunarTableLookup.lunarToSolar(lunar)
    }

    /// Converts a `Foundation.Date` to a lunar date. Defaults to Asia/Shanghai timezone.
    public func lunarDate(
        from date: Date,
        in timeZone: TimeZone = TimeZone(identifier: "Asia/Shanghai")!
    ) -> LunarDate? {
        guard let solar = SolarDate.from(date, in: timeZone) else { return nil }
        return lunarDate(from: solar)
    }

    // MARK: - Lunar year info

    /// Returns the leap month number (1–12) for the given lunar year, or `nil` if no leap month.
    public func leapMonth(in year: Int) -> Int? {
        guard let info = LunarTableLookup.decode(year: year) else { return nil }
        return info.leapMonth > 0 ? info.leapMonth : nil
    }

    /// Returns the number of days (29 or 30) in a lunar month.
    public func daysInMonth(_ month: Int, isLeap: Bool, year: Int) -> Int? {
        guard let info = LunarTableLookup.decode(year: year) else { return nil }
        return LunarTableLookup.monthDayCount(info: info, month: month, isLeap: isLeap)
    }

    /// Returns the total number of days in a lunar year (353–385).
    public func daysInYear(_ year: Int) -> Int? {
        guard let info = LunarTableLookup.decode(year: year) else { return nil }
        return LunarTableLookup.yearDayCount(info: info)
    }

    /// Returns the Gregorian date of Chinese New Year (正月初一) for the given year.
    public func lunarNewYear(in year: Int) -> SolarDate? {
        guard let info = LunarTableLookup.decode(year: year) else { return nil }
        return SolarDate(uncheckedYear: year, month: info.cnyMonth, day: info.cnyDay)
    }

    // MARK: - Solar terms

    /// Returns all 24 solar terms for the given year, in chronological order.
    public func solarTerms(in year: Int) -> [(term: SolarTerm, date: SolarDate)] {
        solarTermCache.allTerms(in: year)
    }

    /// Returns the Gregorian date of a specific solar term in the given year.
    public func solarTermDate(_ term: SolarTerm, in year: Int) -> SolarDate? {
        solarTermCache.date(for: term, in: year)
    }

    /// Returns the solar term that falls on the given date, or `nil`.
    public func solarTerm(on date: SolarDate) -> SolarTerm? {
        let terms = solarTermCache.allTerms(in: date.year)
        return terms.first(where: { $0.date == date })?.term
    }

    // MARK: - GanZhi

    /// Returns the year GanZhi (干支) for the given lunar year.
    public func yearGanZhi(for lunarYear: Int) -> GanZhi {
        GanZhi.year(lunarYear)
    }

    /// Returns the month GanZhi for the given solar date.
    ///
    /// Month GanZhi changes at 节 (Jie) solar terms, not lunar month boundaries.
    /// Month 1 (寅月) starts at 立春, month 2 at 惊蛰, etc.
    public func monthGanZhi(for solar: SolarDate) -> GanZhi {
        // Jie terms in calendar order within a year:
        // 小寒(Jan, month 12) → 立春(Feb, month 1) → ... → 大雪(Dec, month 11)
        let jieTerms: [(term: SolarTerm, month: Int)] = [
            (.xiaoHan, 12), (.liChun, 1), (.jingZhe, 2), (.qingMing, 3),
            (.liXia, 4), (.mangZhong, 5), (.xiaoShu, 6), (.liQiu, 7),
            (.baiLu, 8), (.hanLu, 9), (.liDong, 10), (.daXue, 11),
        ]

        // Collect jie dates from current year; also need previous year's 大雪
        let currentTerms = solarTermCache.allTerms(in: solar.year)
        let prevTerms = solarTermCache.allTerms(in: solar.year - 1)

        // Build (date, month, ganZhiYear) pairs in calendar order
        var boundaries: [(date: SolarDate, month: Int, ganZhiYear: Int)] = []

        // Previous year's 大雪 (month 11, year = solar.year - 1)
        if let daXue = prevTerms.first(where: { $0.term == .daXue })?.date {
            boundaries.append((daXue, 11, solar.year - 1))
        }

        for (jie, month) in jieTerms {
            if let jieDate = currentTerms.first(where: { $0.term == jie })?.date {
                // 小寒/大雪 (month 11, 12) belong to previous GanZhi year
                let year = month >= 11 ? solar.year - 1 : solar.year
                boundaries.append((jieDate, month, year))
            }
        }

        // Find the latest boundary on or before the date
        var ganZhiMonth = 11
        var ganZhiYear = solar.year - 1
        for b in boundaries {
            if solar >= b.date {
                ganZhiMonth = b.month
                ganZhiYear = b.ganZhiYear
            }
        }

        let yearGan = GanZhi.year(ganZhiYear).gan
        return GanZhi.month(yearGan: yearGan, month: ganZhiMonth)!
    }

    /// Returns the day GanZhi for the given solar date.
    public func dayGanZhi(for solar: SolarDate) -> GanZhi {
        GanZhi.day(for: solar)
    }

    // MARK: - Zodiac

    /// Returns the Chinese zodiac animal for the given lunar year.
    public func zodiac(for lunarYear: Int) -> ChineseZodiac {
        ChineseZodiac.fromYear(lunarYear)
    }

    // MARK: - Birthday

    /// Finds the next occurrence of a lunar birthday after the given date.
    ///
    /// Fallback behavior:
    /// 1. If `isLeapMonth` is `true` but the year has no such leap month, falls back to the regular month.
    /// 2. If the month has fewer days than `day`, uses the last day of that month.
    ///
    /// - Parameters:
    ///   - month: Lunar month (1–12).
    ///   - day: Lunar day (1–30).
    ///   - isLeapMonth: Whether the birthday is in a leap month.
    ///   - after: Reference date (defaults to today in Asia/Shanghai).
    /// - Returns: The next solar date of the birthday, or `nil` if out of range.
    public func nextLunarBirthday(
        month: Int, day: Int,
        isLeapMonth: Bool = false,
        after: SolarDate? = nil
    ) -> SolarDate? {
        guard (1...12).contains(month), (1...30).contains(day) else {
            return nil
        }
        let reference = after ?? todayInBeijing()
        guard let reference else { return nil }
        guard let startLunarYear = startingLunarYear(for: reference) else {
            return nil
        }

        for lunarYear in startLunarYear...supportedYearRange.upperBound {
            if let result = resolveBirthday(
                lunarYear: lunarYear, month: month, day: day,
                isLeapMonth: isLeapMonth
            ) {
                if result > reference {
                    return result
                }
            }
        }
        return nil
    }

    /// Returns the solar dates of the next `years` occurrences of a lunar birthday.
    ///
    /// - Parameters:
    ///   - month: Lunar month (1–12).
    ///   - day: Lunar day (1–30).
    ///   - isLeapMonth: Whether the birthday is in a leap month.
    ///   - from: Reference date (defaults to today in Asia/Shanghai).
    ///   - years: Number of occurrences to return (default: 10).
    public func lunarBirthdays(
        month: Int, day: Int,
        isLeapMonth: Bool = false,
        from: SolarDate? = nil,
        years: Int = 10
    ) -> [SolarDate] {
        guard years > 0, (1...12).contains(month), (1...30).contains(day) else {
            return []
        }
        let reference = from ?? todayInBeijing()
        guard let reference else { return [] }
        guard let startLunarYear = startingLunarYear(for: reference) else {
            return []
        }

        var results: [SolarDate] = []
        var count = 0

        for lunarYear in startLunarYear...supportedYearRange.upperBound {
            guard count < years else { break }
            if let result = resolveBirthday(
                lunarYear: lunarYear, month: month, day: day,
                isLeapMonth: isLeapMonth
            ) {
                if result > reference {
                    results.append(result)
                    count += 1
                }
            }
        }
        return results
    }

    // MARK: - Private helpers

    // Resolve a birthday for a specific lunar year with fallback logic.
    private func resolveBirthday(
        lunarYear: Int, month: Int, day: Int, isLeapMonth: Bool
    ) -> SolarDate? {
        guard
            (1...12).contains(month),
            (1...30).contains(day),
            let info = LunarTableLookup.decode(year: lunarYear)
        else {
            return nil
        }

        // Try leap month first if requested
        if isLeapMonth && info.leapMonth == month {
            let actualDay = min(day, info.leapMonthDays)
            if let lunar = LunarDate(year: lunarYear, month: month, day: actualDay, isLeapMonth: true) {
                return LunarTableLookup.lunarToSolar(lunar)
            }
        }

        // Fall back to regular month (or regular month was requested)
        let regularDays = info.monthDays[month - 1]
        let actualDay = min(day, regularDays)
        guard let lunar = LunarDate(year: lunarYear, month: month, day: actualDay) else {
            return nil
        }
        return LunarTableLookup.lunarToSolar(lunar)
    }

    private func todayInBeijing() -> SolarDate? {
        SolarDate.from(Date(), in: TimeZone(identifier: "Asia/Shanghai")!)
    }

    // Lunar-year loop must start from reference's lunar year instead of Gregorian year.
    // Otherwise, dates before CNY can skip the tail months of the current lunar year.
    private func startingLunarYear(for reference: SolarDate) -> Int? {
        if let refLunar = lunarDate(from: reference) {
            return max(refLunar.year, supportedYearRange.lowerBound)
        }
        return (supportedYearRange.contains(reference.year) ? reference.year : nil)
    }
}

// MARK: - Solar term cache (thread-safe)

private final class SolarTermCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cache: [Int: [(term: SolarTerm, date: SolarDate)]] = [:]

    func allTerms(in year: Int) -> [(term: SolarTerm, date: SolarDate)] {
        lock.lock()
        if let cached = cache[year] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let terms = Self.computeAllTerms(in: year)

        lock.lock()
        cache[year] = terms
        lock.unlock()
        return terms
    }

    func date(for term: SolarTerm, in year: Int) -> SolarDate? {
        allTerms(in: year).first(where: { $0.term == term })?.date
    }

    private static func computeAllTerms(in year: Int) -> [(term: SolarTerm, date: SolarDate)] {
        SolarTerm.allCases.compactMap { term in
            guard let date = SolarTermCalc.solarTermDate(term: term, year: year) else {
                return nil
            }
            return (term: term, date: date)
        }
    }
}
