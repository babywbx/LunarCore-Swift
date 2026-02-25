import Testing
import Foundation

@testable import LunarCore

// Comprehensive conversion + consistency tests across the full 1900-2100 range.
// Each test validates a specific year to maximize test case count.

// MARK: - Solar→Lunar→Solar Round-Trip (every 5th year, sampled dates)

@Suite("Comprehensive Round-Trip")
struct ComprehensiveRoundTripTests {

    let cal = LunarCalendar.shared
    private let supportedSolarStart = SolarDate(year: 1900, month: 1, day: 31)!
    private let supportedSolarEnd = SolarDate(year: 2100, month: 12, day: 31)!

    // Sample dates per year: Jan 1, CNY, Feb 15, Mar 21, Jun 15, Sep 22, Oct 1, Dec 31
    private func sampleSolarDates(year: Int) -> [SolarDate] {
        let candidates = [
            (1, 1), (1, 15), (2, 10), (2, 15), (3, 1), (3, 21),
            (4, 5), (5, 1), (6, 15), (7, 7), (8, 1), (8, 15),
            (9, 9), (9, 22), (10, 1), (10, 15), (11, 11), (12, 22), (12, 31),
        ]
        return candidates.compactMap { SolarDate(year: year, month: $0.0, day: $0.1) }
    }

    private func assertRoundTrip(year: Int) {
        for solar in sampleSolarDates(year: year) {
            let lunar = cal.lunarDate(from: solar)
            if solar < supportedSolarStart || solar > supportedSolarEnd {
                #expect(lunar == nil, "expected nil outside supported solar range: \(solar)")
                continue
            }
            #expect(lunar != nil, "solar->lunar returned nil for \(solar)")
            guard let lunar else { continue }
            let back = cal.solarDate(from: lunar)
            #expect(back == solar, "\(solar) → \(lunar) → \(String(describing: back))")
        }
    }

    @Test("round-trip 1900-1919", arguments: Array(1900...1919))
    func roundTrip1900s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 1920-1939", arguments: Array(1920...1939))
    func roundTrip1920s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 1940-1959", arguments: Array(1940...1959))
    func roundTrip1940s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 1960-1979", arguments: Array(1960...1979))
    func roundTrip1960s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 1980-1999", arguments: Array(1980...1999))
    func roundTrip1980s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 2000-2019", arguments: Array(2000...2019))
    func roundTrip2000s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 2020-2039", arguments: Array(2020...2039))
    func roundTrip2020s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 2040-2059", arguments: Array(2040...2059))
    func roundTrip2040s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 2060-2079", arguments: Array(2060...2079))
    func roundTrip2060s(year: Int) {
        assertRoundTrip(year: year)
    }

    @Test("round-trip 2080-2100", arguments: Array(2080...2100))
    func roundTrip2080s(year: Int) {
        assertRoundTrip(year: year)
    }
}

// MARK: - Solar Term Consistency (per year)

@Suite("Comprehensive Solar Terms")
struct ComprehensiveSolarTermTests {

    let cal = LunarCalendar.shared

    @Test("24 terms per year 1900-1949", arguments: Array(1900...1949))
    func terms1900s(year: Int) {
        let terms = cal.solarTerms(in: year)
        #expect(terms.count == 24, "Year \(year) has \(terms.count) terms")
        // Verify chronological order
        for i in 1..<terms.count {
            #expect(terms[i].date > terms[i - 1].date,
                    "Year \(year): \(terms[i].term) not after \(terms[i - 1].term)")
        }
    }

    @Test("24 terms per year 1950-1999", arguments: Array(1950...1999))
    func terms1950s(year: Int) {
        let terms = cal.solarTerms(in: year)
        #expect(terms.count == 24, "Year \(year) has \(terms.count) terms")
        for i in 1..<terms.count {
            #expect(terms[i].date > terms[i - 1].date)
        }
    }

    @Test("24 terms per year 2000-2049", arguments: Array(2000...2049))
    func terms2000s(year: Int) {
        let terms = cal.solarTerms(in: year)
        #expect(terms.count == 24, "Year \(year) has \(terms.count) terms")
        for i in 1..<terms.count {
            #expect(terms[i].date > terms[i - 1].date)
        }
    }

    @Test("24 terms per year 2050-2100", arguments: Array(2050...2100))
    func terms2050s(year: Int) {
        let terms = cal.solarTerms(in: year)
        #expect(terms.count == 24, "Year \(year) has \(terms.count) terms")
        for i in 1..<terms.count {
            #expect(terms[i].date > terms[i - 1].date)
        }
    }
}

// MARK: - GanZhi Consistency

@Suite("Comprehensive GanZhi")
struct ComprehensiveGanZhiTests {

    let cal = LunarCalendar.shared

    @Test("year GanZhi 60-year cycle", arguments: Array(1900...2100))
    func yearCycle(year: Int) {
        let gz = cal.yearGanZhi(for: year)
        // GanZhi should repeat every 60 years.
        if year + 60 <= 2100 {
            let gz60 = cal.yearGanZhi(for: year + 60)
            #expect(gz.chinese == gz60.chinese,
                    "Year \(year): \(gz.chinese) != year \(year+60): \(gz60.chinese)")
        }
    }

    @Test("day GanZhi consecutive days increment", arguments: Array(stride(from: 2000, through: 2025, by: 1)))
    func dayConsecutive(year: Int) {
        // Check that Jan 1 and Jan 2 differ by one GanZhi step
        let d1 = SolarDate(year: year, month: 1, day: 1)!
        let d2 = SolarDate(year: year, month: 1, day: 2)!
        let gz1 = cal.dayGanZhi(for: d1)
        let gz2 = cal.dayGanZhi(for: d2)
        let expected = GanZhi(index: (gz1.index + 1) % 60)
        #expect(gz2.chinese == expected.chinese)
    }
}

// MARK: - Leap Month Census

@Suite("Comprehensive Leap Months")
struct ComprehensiveLeapMonthTests {

    let cal = LunarCalendar.shared

    @Test("leap month census 1900-1950", arguments: Array(1900...1950))
    func leapCensus1900(year: Int) {
        let leap = cal.leapMonth(in: year)
        if let leap {
            #expect((1...12).contains(leap), "Year \(year) leap month \(leap) out of range")
            // Leap month should have 29 or 30 days
            let days = cal.daysInMonth(leap, isLeap: true, year: year)
            #expect(days == 29 || days == 30, "Year \(year) leap month \(leap) has \(String(describing: days)) days")
        }
        // Non-leap months should still work
        for m in 1...12 {
            let days = cal.daysInMonth(m, isLeap: false, year: year)
            #expect(days == 29 || days == 30, "Year \(year) month \(m) has \(String(describing: days)) days")
        }
    }

    @Test("leap month census 1951-2000", arguments: Array(1951...2000))
    func leapCensus1951(year: Int) {
        let leap = cal.leapMonth(in: year)
        if let leap {
            #expect((1...12).contains(leap))
            let days = cal.daysInMonth(leap, isLeap: true, year: year)
            #expect(days == 29 || days == 30)
        }
        for m in 1...12 {
            let days = cal.daysInMonth(m, isLeap: false, year: year)
            #expect(days == 29 || days == 30)
        }
    }

    @Test("leap month census 2001-2050", arguments: Array(2001...2050))
    func leapCensus2001(year: Int) {
        let leap = cal.leapMonth(in: year)
        if let leap {
            #expect((1...12).contains(leap))
            let days = cal.daysInMonth(leap, isLeap: true, year: year)
            #expect(days == 29 || days == 30)
        }
        for m in 1...12 {
            let days = cal.daysInMonth(m, isLeap: false, year: year)
            #expect(days == 29 || days == 30)
        }
    }

    @Test("leap month census 2051-2100", arguments: Array(2051...2100))
    func leapCensus2051(year: Int) {
        let leap = cal.leapMonth(in: year)
        if let leap {
            #expect((1...12).contains(leap))
            let days = cal.daysInMonth(leap, isLeap: true, year: year)
            #expect(days == 29 || days == 30)
        }
        for m in 1...12 {
            let days = cal.daysInMonth(m, isLeap: false, year: year)
            #expect(days == 29 || days == 30)
        }
    }
}

// MARK: - CNY Consistency

@Suite("Comprehensive CNY")
struct ComprehensiveCNYTests {

    let cal = LunarCalendar.shared

    @Test("CNY in Jan/Feb window", arguments: Array(1900...2100))
    func cnyWindow(year: Int) {
        let cny = cal.lunarNewYear(in: year)
        #expect(cny != nil, "CNY nil for year \(year)")
        guard let cny else { return }
        #expect(cny.year == year)
        if cny.month == 1 {
            #expect((21...31).contains(cny.day), "Year \(year) CNY Jan \(cny.day)")
        } else {
            #expect(cny.month == 2)
            #expect((1...20).contains(cny.day), "Year \(year) CNY Feb \(cny.day)")
        }
        // CNY should be lunar 1/1
        let lunar = cal.lunarDate(from: cny)
        #expect(lunar == LunarDate(year: year, month: 1, day: 1))
    }
}
