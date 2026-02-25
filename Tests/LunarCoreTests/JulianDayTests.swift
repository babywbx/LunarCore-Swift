import Testing
@testable import LunarCore

@Suite("JulianDay")
struct JulianDayTests {

    // MARK: - Known JD values

    @Test func j2000() {
        // J2000.0 epoch: 2000-01-01 12:00 UT = JD 2451545.0
        let jd = JulianDay.fromGregorian(year: 2000, month: 1, day: 1.5)
        #expect(jd == 2_451_545.0)
    }

    @Test func unixEpoch() {
        // 1970-01-01 0h UT = JD 2440587.5
        let jd = JulianDay.fromGregorian(year: 1970, month: 1, day: 1.0)
        #expect(jd == 2_440_587.5)
    }

    @Test func gregorianReform() {
        // 1582-10-15 0h UT = JD 2299160.5
        let jd = JulianDay.fromGregorian(year: 1582, month: 10, day: 15.0)
        #expect(jd == 2_299_160.5)
    }

    @Test func year1900() {
        // 1900-01-01 0h UT = JD 2415020.5
        let jd = JulianDay.fromGregorian(year: 1900, month: 1, day: 1.0)
        #expect(abs(jd - 2_415_020.5) < 0.0001)
    }

    @Test func meeusExample() {
        // Meeus example: 1957 Oct 4.81 = JD 2436116.31
        let jd = JulianDay.fromGregorian(year: 1957, month: 10, day: 4.81)
        #expect(abs(jd - 2_436_116.31) < 0.001)
    }

    // MARK: - Inverse conversion

    @Test func inverseJ2000() {
        let (y, m, d) = JulianDay.toGregorian(jd: 2_451_545.0)
        #expect(y == 2000)
        #expect(m == 1)
        #expect(abs(d - 1.5) < 0.0001)
    }

    @Test func inverseUnixEpoch() {
        let (y, m, d) = JulianDay.toGregorian(jd: 2_440_587.5)
        #expect(y == 1970)
        #expect(m == 1)
        #expect(abs(d - 1.0) < 0.0001)
    }

    // MARK: - Round-trip

    @Test func roundTrip() {
        let dates: [(Int, Int, Double)] = [
            (2025, 6, 15.0),
            (1900, 1, 1.0),
            (2100, 12, 31.0),
            (2000, 2, 29.0),  // leap year
            (1999, 3, 1.0),
        ]
        for (year, month, day) in dates {
            let jd = JulianDay.fromGregorian(year: year, month: month, day: day)
            let (y, m, d) = JulianDay.toGregorian(jd: jd)
            #expect(y == year, "Year mismatch for \(year)-\(month)-\(day)")
            #expect(m == month, "Month mismatch for \(year)-\(month)-\(day)")
            #expect(abs(d - day) < 0.0001, "Day mismatch for \(year)-\(month)-\(day)")
        }
    }

    @Test func consecutiveDays() {
        // JD increases by 1 for each day
        let jd1 = JulianDay.fromGregorian(year: 2025, month: 1, day: 1.0)
        let jd2 = JulianDay.fromGregorian(year: 2025, month: 1, day: 2.0)
        #expect(abs(jd2 - jd1 - 1.0) < 0.0001)
    }

    @Test func yearBoundary() {
        // Dec 31 → Jan 1 next year
        let jd1 = JulianDay.fromGregorian(year: 2024, month: 12, day: 31.0)
        let jd2 = JulianDay.fromGregorian(year: 2025, month: 1, day: 1.0)
        #expect(abs(jd2 - jd1 - 1.0) < 0.0001)
    }

    @Test func leapYearFeb29() {
        // 2000 is a leap year
        let jd1 = JulianDay.fromGregorian(year: 2000, month: 2, day: 28.0)
        let jd2 = JulianDay.fromGregorian(year: 2000, month: 2, day: 29.0)
        let jd3 = JulianDay.fromGregorian(year: 2000, month: 3, day: 1.0)
        #expect(abs(jd2 - jd1 - 1.0) < 0.0001)
        #expect(abs(jd3 - jd2 - 1.0) < 0.0001)
    }
}
