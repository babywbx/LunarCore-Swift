/// Formats ``LunarDate`` values into human-readable strings.
///
/// Supports Chinese (default) and English locales.
///
/// ```swift
/// let fmt = LunarFormatter(locale: .chinese)
/// fmt.string(from: lunar)            // "二〇二五年正月初一"
/// fmt.string(from: lunar, useGanZhi: true) // "乙巳年正月初一"
/// ```
public struct LunarFormatter: Sendable, Equatable, Hashable {

    /// Output locale for formatting.
    public enum Locale: Sendable, Equatable, Hashable {
        case chinese, english
    }

    /// The locale used for formatting.
    public var locale: Locale

    /// Creates a formatter with the given locale (default: `.chinese`).
    public init(locale: Locale = .chinese) {
        self.locale = locale
    }

    // MARK: - Month name

    /// Returns the month name (e.g. "正月", "闰六月" / "1st Month", "Leap 6th Month").
    public func monthName(_ month: Int, isLeap: Bool = false) -> String {
        switch locale {
        case .chinese:
            let name = chineseMonthName(month)
            return isLeap ? "闰\(name)" : name
        case .english:
            let name = "\(ordinal(month)) Month"
            return isLeap ? "Leap \(name)" : name
        }
    }

    // MARK: - Day name

    /// Returns the day name (e.g. "初一", "廿三" / "Day 1", "Day 23").
    public func dayName(_ day: Int) -> String {
        switch locale {
        case .chinese:
            return chineseDayName(day)
        case .english:
            return "Day \(day)"
        }
    }

    // MARK: - Full string

    /// Full date string (e.g. "二〇二五年正月十五" or "乙巳年正月十五").
    ///
    /// - Parameter useGanZhi: Use GanZhi year instead of numeric year.
    public func string(from lunar: LunarDate, useGanZhi: Bool = false) -> String {
        switch locale {
        case .chinese:
            let yearStr: String
            if useGanZhi {
                yearStr = GanZhi.year(lunar.year).chinese
            } else {
                yearStr = chineseYear(lunar.year)
            }
            let monthStr = monthName(lunar.month, isLeap: lunar.isLeapMonth)
            let dayStr = dayName(lunar.day)
            return "\(yearStr)年\(monthStr)\(dayStr)"
        case .english:
            let yearStr: String
            if useGanZhi {
                let gz = GanZhi.year(lunar.year)
                yearStr = "\(gz.gan.pinyin)-\(gz.zhi.pinyin)"
            } else {
                yearStr = "\(lunar.year)"
            }
            let monthStr = monthName(lunar.month, isLeap: lunar.isLeapMonth)
            let dayStr = dayName(lunar.day)
            return "\(yearStr), \(monthStr) \(dayStr)"
        }
    }

    // MARK: - Short string

    /// Short date string without year (e.g. "正月十五").
    public func shortString(from lunar: LunarDate) -> String {
        let monthStr = monthName(lunar.month, isLeap: lunar.isLeapMonth)
        let dayStr = dayName(lunar.day)
        switch locale {
        case .chinese:
            return "\(monthStr)\(dayStr)"
        case .english:
            return "\(monthStr) \(dayStr)"
        }
    }

    // MARK: - Chinese year digits

    /// Converts a numeric year to Chinese digits (e.g. 2025 → "二〇二五").
    public func chineseYear(_ year: Int) -> String {
        let digits = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        return String(year).compactMap { c in
            guard let d = c.wholeNumberValue else { return nil as String? }
            return digits[d]
        }.joined()
    }

    // MARK: - Private helpers

    private func chineseMonthName(_ month: Int) -> String {
        switch month {
        case 1: "正月"
        case 2: "二月"
        case 3: "三月"
        case 4: "四月"
        case 5: "五月"
        case 6: "六月"
        case 7: "七月"
        case 8: "八月"
        case 9: "九月"
        case 10: "十月"
        case 11: "十一月"
        case 12: "腊月"
        default: "\(month)月"
        }
    }

    private func chineseDayName(_ day: Int) -> String {
        let ones = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch day {
        case 1...10:
            return "初\(ones[day])"
        case 11...19:
            return "十\(ones[day - 10])"
        case 20:
            return "二十"
        case 21...29:
            return "廿\(ones[day - 20])"
        case 30:
            return "三十"
        default:
            return "\(day)"
        }
    }

    private func ordinal(_ n: Int) -> String {
        let absValue = abs(n)
        let mod100 = absValue % 100
        let suffix: String

        if mod100 == 11 || mod100 == 12 || mod100 == 13 {
            suffix = "th"
        } else {
            switch absValue % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }

        return "\(n)\(suffix)"
    }
}
