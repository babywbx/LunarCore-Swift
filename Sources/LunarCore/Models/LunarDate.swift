/// A Chinese lunar calendar date (农历日期).
///
/// The `year` uses Gregorian numbering (e.g. 2025).
/// Leap months are indicated by ``isLeapMonth``.
public struct LunarDate: Equatable, Hashable, Comparable, Sendable, Codable {
    /// Lunar year in Gregorian numbering (e.g. 2025).
    public let year: Int
    /// Lunar month (1–12).
    public let month: Int
    /// Lunar day (1–30).
    public let day: Int
    /// Whether this is a leap (intercalary) month.
    public let isLeapMonth: Bool

    /// Creates a lunar date, returning `nil` if month/day are out of range.
    public init?(year: Int, month: Int, day: Int, isLeapMonth: Bool = false) {
        guard LunarDate.isValid(month: month, day: day) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }

    // Internal fast path for already-validated lunar dates.
    package init(uncheckedYear year: Int, month: Int, day: Int, isLeapMonth: Bool = false) {
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

    /// Returns whether month (1–12) and day (1–30) are in valid range.
    public static func isValid(month: Int, day: Int) -> Bool {
        (1...12).contains(month) && (1...30).contains(day)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case year, month, day, isLeapMonth
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let y = try c.decode(Int.self, forKey: .year)
        let m = try c.decode(Int.self, forKey: .month)
        let d = try c.decode(Int.self, forKey: .day)
        let leap = try c.decodeIfPresent(Bool.self, forKey: .isLeapMonth) ?? false
        guard LunarDate.isValid(month: m, day: d) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: c.codingPath,
                debugDescription: "Invalid lunar date: month=\(m), day=\(d)"))
        }
        self.year = y
        self.month = m
        self.day = d
        self.isLeapMonth = leap
    }
}
