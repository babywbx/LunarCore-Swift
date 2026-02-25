// Chinese Lunar Calendar Date (农历日期)

public struct LunarDate: Equatable, Hashable, Comparable, Sendable {
    public let year: Int           // Lunar year (Gregorian numbering, e.g. 2025)
    public let month: Int          // Lunar month (1-12)
    public let day: Int            // Lunar day (1-30)
    public let isLeapMonth: Bool   // Whether this is a leap month

    public init?(year: Int, month: Int, day: Int, isLeapMonth: Bool = false) {
        guard LunarDate.isValid(month: month, day: day) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }

    // Leap month follows regular month of the same number
    public static func < (lhs: LunarDate, rhs: LunarDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        if lhs.isLeapMonth != rhs.isLeapMonth { return !lhs.isLeapMonth }
        return lhs.day < rhs.day
    }

    public static func isValid(month: Int, day: Int) -> Bool {
        (1...12).contains(month) && (1...30).contains(day)
    }
}
