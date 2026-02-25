import Testing
import Foundation

@testable import LunarCore

// MARK: - Boundary Cases (SPEC Section 12)

@Suite("Boundary Cases")
struct BoundaryTests {

    let cal = LunarCalendar.shared

    // BC1: 2033 leap month 11 — extremely rare, many libraries get this wrong.
    @Test("BC1: 2033 leap month 11")
    func leapMonth11In2033() {
        #expect(cal.leapMonth(in: 2033) == 11)

        let regular11 = LunarDate(year: 2033, month: 11, day: 1)!
        let leap11 = LunarDate(year: 2033, month: 11, day: 1, isLeapMonth: true)!
        let regularSolar = cal.solarDate(from: regular11)
        let leapSolar = cal.solarDate(from: leap11)
        #expect(regularSolar != nil)
        #expect(leapSolar != nil)
        #expect(leapSolar! > regularSolar!)

        // Round-trip
        #expect(cal.lunarDate(from: regularSolar!) == regular11)
        #expect(cal.lunarDate(from: leapSolar!) == leap11)
    }

    // BC2: 1979 大寒 — solar term moment ~6 seconds from midnight.
    @Test("BC2: 1979 大寒 near midnight")
    func daHan1979() {
        let date = cal.solarTermDate(.daHan, in: 1979)
        #expect(date != nil)
        #expect(date!.year == 1979)
        #expect(date!.month == 1)
        // The exact day depends on which side of midnight the 6-second offset falls.
        #expect(date!.day == 20 || date!.day == 21)
    }

    // BC3: 2057 Mid-Autumn — boundary year with disputed month 9.
    @Test("BC3: 2057 Mid-Autumn")
    func midAutumn2057() {
        let lunar = LunarDate(year: 2057, month: 8, day: 15)!
        let solar = cal.solarDate(from: lunar)
        #expect(solar != nil)
        // Round-trip
        #expect(cal.lunarDate(from: solar!) == lunar)
    }

    // BC4: 1900 first day — lower bound of supported range.
    @Test("BC4: 1900-01-31 (CNY 1900)")
    func lowerBound1900() {
        let cny = cal.lunarNewYear(in: 1900)
        #expect(cny != nil)
        #expect(cny!.year == 1900)

        let solar = SolarDate(year: 1900, month: cny!.month, day: cny!.day)!
        let lunar = cal.lunarDate(from: solar)
        #expect(lunar == LunarDate(year: 1900, month: 1, day: 1))
    }

    // BC5: 2100 last day — upper bound of supported range.
    @Test("BC5: 2100 upper bound")
    func upperBound2100() {
        let cny = cal.lunarNewYear(in: 2100)
        #expect(cny != nil)

        // The last day of lunar year 2100 should convert successfully.
        let info = LunarTableLookup.decode(year: 2100)!
        let lastMonth = info.leapMonth > 0 ? 13 : 12
        _ = lastMonth // just verify decode works

        // Verify a date near end of 2100
        let solar = SolarDate(year: 2100, month: 12, day: 31)!
        let lunar = cal.lunarDate(from: solar)
        // This might be lunar year 2100 month 11 or 12
        #expect(lunar != nil)
    }

    // BC6: 腊月29 vs 30 — some years have 29-day month 12.
    @Test("BC6: 腊月 small month (29 days)")
    func laYueSmallMonth() {
        var found29 = false
        var found30 = false
        for year in 1900...2100 {
            if let days = cal.daysInMonth(12, isLeap: false, year: year) {
                if days == 29 { found29 = true }
                if days == 30 { found30 = true }
            }
            if found29 && found30 { break }
        }
        #expect(found29, "Should find a year with 29-day 腊月")
        #expect(found30, "Should find a year with 30-day 腊月")

        // Verify conversion for a 29-day 腊月
        for year in 1900...2100 {
            if cal.daysInMonth(12, isLeap: false, year: year) == 29 {
                // Day 29 should convert
                let lunar29 = LunarDate(year: year, month: 12, day: 29)!
                #expect(cal.solarDate(from: lunar29) != nil)
                // Day 30 should fail
                let lunar30 = LunarDate(year: year, month: 12, day: 30)!
                #expect(cal.solarDate(from: lunar30) == nil,
                        "Year \(year) 腊月 is 29 days but day 30 conversion succeeded")
                break
            }
        }
    }

    // BC7: 2023 leap month 2
    @Test("BC7: 2023 leap 2")
    func leapMonth2In2023() {
        #expect(cal.leapMonth(in: 2023) == 2)

        let regular = LunarDate(year: 2023, month: 2, day: 15)!
        let leap = LunarDate(year: 2023, month: 2, day: 15, isLeapMonth: true)!
        let regularSolar = cal.solarDate(from: regular)
        let leapSolar = cal.solarDate(from: leap)
        #expect(regularSolar != nil)
        #expect(leapSolar != nil)
        #expect(leapSolar! > regularSolar!)

        // Round-trip
        #expect(cal.lunarDate(from: regularSolar!) == regular)
        #expect(cal.lunarDate(from: leapSolar!) == leap)
    }

    // BC8: 2025 leap month 6
    @Test("BC8: 2025 leap 6")
    func leapMonth6In2025() {
        #expect(cal.leapMonth(in: 2025) == 6)

        let regular = LunarDate(year: 2025, month: 6, day: 1)!
        let leap = LunarDate(year: 2025, month: 6, day: 1, isLeapMonth: true)!
        let regularSolar = cal.solarDate(from: regular)
        let leapSolar = cal.solarDate(from: leap)
        #expect(regularSolar != nil)
        #expect(leapSolar != nil)
        #expect(leapSolar! > regularSolar!)
    }

    // BC9: 2020 leap month 4
    @Test("BC9: 2020 leap 4")
    func leapMonth4In2020() {
        #expect(cal.leapMonth(in: 2020) == 4)

        let regular = LunarDate(year: 2020, month: 4, day: 10)!
        let leap = LunarDate(year: 2020, month: 4, day: 10, isLeapMonth: true)!
        let regularSolar = cal.solarDate(from: regular)
        let leapSolar = cal.solarDate(from: leap)
        #expect(regularSolar != nil)
        #expect(leapSolar != nil)
        #expect(leapSolar! > regularSolar!)
    }

    // BC10: Historical CNY dates (1914, 1916, 1920) — time standard differences.
    @Test("BC10: historical CNY 1914")
    func cny1914() {
        let cny = cal.lunarNewYear(in: 1914)
        #expect(cny != nil)
        #expect(cny!.month == 1 || cny!.month == 2)
        let lunar = cal.lunarDate(from: cny!)
        #expect(lunar == LunarDate(year: 1914, month: 1, day: 1))
    }

    @Test("BC10: historical CNY 1916")
    func cny1916() {
        let cny = cal.lunarNewYear(in: 1916)
        #expect(cny != nil)
        let lunar = cal.lunarDate(from: cny!)
        #expect(lunar == LunarDate(year: 1916, month: 1, day: 1))
    }

    @Test("BC10: historical CNY 1920")
    func cny1920() {
        let cny = cal.lunarNewYear(in: 1920)
        #expect(cny != nil)
        let lunar = cal.lunarDate(from: cny!)
        #expect(lunar == LunarDate(year: 1920, month: 1, day: 1))
    }

    // BC11: Consecutive small months (two 29-day months in a row).
    @Test("BC11: consecutive small months")
    func consecutiveSmallMonths() {
        var found = false
        for year in 1900...2100 {
            guard let info = LunarTableLookup.decode(year: year) else { continue }
            for i in 0..<11 {
                if info.monthDays[i] == 29 && info.monthDays[i + 1] == 29 {
                    // Verify conversions around the boundary
                    let m1Last = LunarDate(year: year, month: i + 1, day: 29)!
                    let m2First = LunarDate(year: year, month: i + 2, day: 1)!
                    let s1 = cal.solarDate(from: m1Last)
                    let s2 = cal.solarDate(from: m2First)
                    #expect(s1 != nil)
                    #expect(s2 != nil)
                    // s2 should be exactly 1 day after s1
                    let jd1 = JulianDay.fromGregorian(
                        year: s1!.year, month: s1!.month, day: Double(s1!.day))
                    let jd2 = JulianDay.fromGregorian(
                        year: s2!.year, month: s2!.month, day: Double(s2!.day))
                    #expect(Int((jd2 - jd1).rounded()) == 1)
                    found = true
                    break
                }
            }
            if found { break }
        }
        #expect(found, "Should find consecutive small months in 1900-2100")
    }

    // BC12: Consecutive large months (two 30-day months in a row).
    @Test("BC12: consecutive large months")
    func consecutiveLargeMonths() {
        var found = false
        for year in 1900...2100 {
            guard let info = LunarTableLookup.decode(year: year) else { continue }
            for i in 0..<11 {
                if info.monthDays[i] == 30 && info.monthDays[i + 1] == 30 {
                    let m1Last = LunarDate(year: year, month: i + 1, day: 30)!
                    let m2First = LunarDate(year: year, month: i + 2, day: 1)!
                    let s1 = cal.solarDate(from: m1Last)
                    let s2 = cal.solarDate(from: m2First)
                    #expect(s1 != nil)
                    #expect(s2 != nil)
                    let jd1 = JulianDay.fromGregorian(
                        year: s1!.year, month: s1!.month, day: Double(s1!.day))
                    let jd2 = JulianDay.fromGregorian(
                        year: s2!.year, month: s2!.month, day: Double(s2!.day))
                    #expect(Int((jd2 - jd1).rounded()) == 1)
                    found = true
                    break
                }
            }
            if found { break }
        }
        #expect(found, "Should find consecutive large months in 1900-2100")
    }

    // BC13: CNY in January vs February.
    @Test("BC13: CNY in January")
    func cnyInJanuary() {
        var foundJan = false
        for year in 1900...2100 {
            if let cny = cal.lunarNewYear(in: year), cny.month == 1 {
                #expect((21...31).contains(cny.day))
                let lunar = cal.lunarDate(from: cny)
                #expect(lunar == LunarDate(year: year, month: 1, day: 1))
                foundJan = true
                break
            }
        }
        #expect(foundJan, "Should find CNY in January")
    }

    @Test("BC13: CNY in February")
    func cnyInFebruary() {
        var foundFeb = false
        for year in 1900...2100 {
            if let cny = cal.lunarNewYear(in: year), cny.month == 2 {
                #expect((1...20).contains(cny.day))
                let lunar = cal.lunarDate(from: cny)
                #expect(lunar == LunarDate(year: year, month: 1, day: 1))
                foundFeb = true
                break
            }
        }
        #expect(foundFeb, "Should find CNY in February")
    }

    // BC14: Month numbering after leap month — leap 4 → next month is 5, not 6.
    @Test("BC14: month numbering after leap month")
    func monthNumberingAfterLeap() {
        // 2020 has leap 4.
        let leap4Last = LunarDate(year: 2020, month: 4, day: 29, isLeapMonth: true)!
        let solarLeap4Last = cal.solarDate(from: leap4Last)!
        // Day after leap 4/29 should be month 5 day 1
        let jd = JulianDay.fromGregorian(
            year: solarLeap4Last.year, month: solarLeap4Last.month,
            day: Double(solarLeap4Last.day))
        let nextJD = jd + 1
        let (ny, nm, nd) = JulianDay.toGregorian(jd: nextJD)
        let nextSolar = SolarDate(year: ny, month: nm, day: Int(nd))!
        let nextLunar = cal.lunarDate(from: nextSolar)
        #expect(nextLunar?.month == 5)
        #expect(nextLunar?.day == 1)
        #expect(nextLunar?.isLeapMonth == false)
    }

    // BC15: Year day counts — non-leap: 353/354/355, leap: 383/384/385.
    @Test("BC15: year day counts cover all valid values")
    func yearDayCounts() {
        var nonLeapCounts: Set<Int> = []
        var leapCounts: Set<Int> = []
        for year in 1900...2100 {
            guard let info = LunarTableLookup.decode(year: year) else { continue }
            let total = LunarTableLookup.yearDayCount(info: info)
            if info.leapMonth > 0 {
                #expect((383...385).contains(total), "leap year \(year) = \(total) days")
                leapCounts.insert(total)
            } else {
                #expect((353...355).contains(total), "year \(year) = \(total) days")
                nonLeapCounts.insert(total)
            }
        }
        // All three values should appear
        #expect(nonLeapCounts.contains(353), "Should find 353-day year")
        #expect(nonLeapCounts.contains(354), "Should find 354-day year")
        #expect(nonLeapCounts.contains(355), "Should find 355-day year")
        #expect(leapCounts.contains(383), "Should find 383-day leap year")
        #expect(leapCounts.contains(384), "Should find 384-day leap year")
        #expect(leapCounts.contains(385), "Should find 385-day leap year")
    }
}
