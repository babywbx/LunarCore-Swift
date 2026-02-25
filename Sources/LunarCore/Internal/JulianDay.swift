// Julian Day Number conversion (Meeus Chapter 7)
// Bridge between calendar dates and continuous day count.
// All astronomical calculations use JD as the time basis.

enum JulianDay: Sendable, Equatable, Hashable {

    // Gregorian calendar date → Julian Day Number
    // day parameter can be fractional (e.g. 7.5 = noon of the 7th)
    // Meeus, Chapter 7, valid for dates after the Gregorian reform (Oct 15, 1582)
    static func fromGregorian(year: Int, month: Int, day: Double) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = y / 100
        let b = 2 - a + a / 4 // Gregorian correction
        return Double(Int(365.25 * Double(y + 4716)))
             + Double(Int(30.6001 * Double(m + 1)))
             + day + Double(b) - 1524.5
    }

    // Julian Day Number → Gregorian calendar date
    // Returns (year, month, day) where day can be fractional
    // Meeus, Chapter 7
    static func toGregorian(jd: Double) -> (year: Int, month: Int, day: Double) {
        let jd05 = jd + 0.5
        let z = Int(jd05)
        let f = jd05 - Double(z)

        let a: Int
        if z < 2_299_161 {
            a = z
        } else {
            let alpha = Int((Double(z) - 1_867_216.25) / 36524.25)
            a = z + 1 + alpha - alpha / 4
        }

        let b = a + 1524
        let c = Int((Double(b) - 122.1) / 365.25)
        let d = Int(365.25 * Double(c))
        let e = Int(Double(b - d) / 30.6001)

        let day = Double(b - d - Int(30.6001 * Double(e))) + f
        let month = e < 14 ? e - 1 : e - 13
        let year = month > 2 ? c - 4716 : c - 4715

        return (year, month, day)
    }
}
