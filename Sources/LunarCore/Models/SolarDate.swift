import Foundation

public struct SolarDate: Equatable, Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int  // 1-12
    public let day: Int    // 1-31

    public init?(year: Int, month: Int, day: Int) {
        guard SolarDate.isValid(year: year, month: month, day: day) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: SolarDate, rhs: SolarDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    // MARK: - Foundation.Date interop

    public func toDate(in timeZone: TimeZone) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.date(from: DateComponents(year: year, month: month, day: day))
    }

    public static func from(_ date: Date, in timeZone: TimeZone) -> SolarDate? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else {
            return nil
        }
        return SolarDate(year: year, month: month, day: day)
    }

    public static func isValid(year: Int, month: Int, day: Int) -> Bool {
        guard (1...12).contains(month), (1...31).contains(day) else {
            return false
        }

        guard let utc = TimeZone(secondsFromGMT: 0) else {
            return false
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        let components = DateComponents(calendar: cal, year: year, month: month, day: day)
        guard let date = cal.date(from: components) else {
            return false
        }

        let verified = cal.dateComponents([.year, .month, .day], from: date)
        return verified.year == year && verified.month == month && verified.day == day
    }
}
