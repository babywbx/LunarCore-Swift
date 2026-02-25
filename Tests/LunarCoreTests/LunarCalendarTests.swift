import Testing
import Foundation

@testable import LunarCore

// MARK: - Conversion

@Suite("LunarCalendar - Conversion")
struct CalendarConversionTests {

    let cal = LunarCalendar.shared

    @Test("solar → lunar: 2025 CNY")
    func solarToLunarCNY() {
        let solar = SolarDate(year: 2025, month: 1, day: 29)!
        let lunar = cal.lunarDate(from: solar)
        #expect(lunar == LunarDate(year: 2025, month: 1, day: 1))
    }

    @Test("lunar → solar: 2025 Mid-Autumn")
    func lunarToSolarMidAutumn() {
        let lunar = LunarDate(year: 2025, month: 8, day: 15)!
        let solar = cal.solarDate(from: lunar)
        #expect(solar == SolarDate(year: 2025, month: 10, day: 6))
    }

    @Test("Date convenience method")
    func dateConvenience() {
        let tz = TimeZone(identifier: "Asia/Shanghai")!
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = tz
        let date = gregorian.date(from: DateComponents(year: 2025, month: 1, day: 29))!
        let lunar = cal.lunarDate(from: date, in: tz)
        #expect(lunar == LunarDate(year: 2025, month: 1, day: 1))
    }

    @Test("out-of-range returns nil")
    func outOfRange() {
        let solar = SolarDate(year: 1800, month: 1, day: 1)!
        #expect(cal.lunarDate(from: solar) == nil)
    }
}

// MARK: - Year Info

@Suite("LunarCalendar - Year Info")
struct CalendarYearInfoTests {

    let cal = LunarCalendar.shared

    @Test("leap month 2025 = 6")
    func leapMonth2025() {
        #expect(cal.leapMonth(in: 2025) == 6)
    }

    @Test("leap month 2024 = nil")
    func noLeapMonth2024() {
        #expect(cal.leapMonth(in: 2024) == nil)
    }

    @Test("leap month 2033 = 11")
    func leapMonth2033() {
        #expect(cal.leapMonth(in: 2033) == 11)
    }

    @Test("daysInMonth returns 29 or 30")
    func daysInMonth() {
        let days = cal.daysInMonth(1, isLeap: false, year: 2025)
        #expect(days == 29 || days == 30)
    }

    @Test("daysInMonth for leap month")
    func daysInLeapMonth() {
        let days = cal.daysInMonth(6, isLeap: true, year: 2025)
        #expect(days == 29 || days == 30)
    }

    @Test("daysInMonth for non-existent leap returns nil")
    func daysInNonExistentLeap() {
        #expect(cal.daysInMonth(3, isLeap: true, year: 2025) == nil)
    }

    @Test("daysInYear non-leap")
    func daysInYearNonLeap() {
        let days = cal.daysInYear(2024)!
        #expect((353...355).contains(days))
    }

    @Test("daysInYear leap")
    func daysInYearLeap() {
        let days = cal.daysInYear(2025)!
        #expect((383...385).contains(days))
    }

    @Test("lunarNewYear 2025 = Jan 29")
    func lunarNewYear2025() {
        #expect(cal.lunarNewYear(in: 2025) == SolarDate(year: 2025, month: 1, day: 29))
    }

    @Test("lunarNewYear 2024 = Feb 10")
    func lunarNewYear2024() {
        #expect(cal.lunarNewYear(in: 2024) == SolarDate(year: 2024, month: 2, day: 10))
    }

    @Test("supportedYearRange")
    func yearRange() {
        #expect(cal.supportedYearRange == 1900...2100)
    }
}

// MARK: - Solar Terms

@Suite("LunarCalendar - Solar Terms")
struct CalendarSolarTermTests {

    let cal = LunarCalendar.shared

    @Test("solarTerms returns 24 entries")
    func allTermsCount() {
        let terms = cal.solarTerms(in: 2025)
        #expect(terms.count == 24)
    }

    @Test("Qing Ming 2025 = Apr 4")
    func qingMing2025() {
        let date = cal.solarTermDate(.qingMing, in: 2025)
        #expect(date == SolarDate(year: 2025, month: 4, day: 4))
    }

    @Test("solarTerm(on:) finds match")
    func solarTermOnDate() {
        let date = cal.solarTermDate(.chunFen, in: 2025)!
        let term = cal.solarTerm(on: date)
        #expect(term == .chunFen)
    }

    @Test("solarTerm(on:) returns nil for non-term date")
    func solarTermOnNonTermDate() {
        let date = SolarDate(year: 2025, month: 3, day: 15)!
        #expect(cal.solarTerm(on: date) == nil)
    }

    @Test("caching: second call returns same results")
    func cachingConsistency() {
        let first = cal.solarTerms(in: 2000)
        let second = cal.solarTerms(in: 2000)
        #expect(first.count == second.count)
        for (a, b) in zip(first, second) {
            #expect(a.term == b.term)
            #expect(a.date == b.date)
        }
    }
}

// MARK: - GanZhi

@Suite("LunarCalendar - GanZhi")
struct CalendarGanZhiTests {

    let cal = LunarCalendar.shared

    @Test("yearGanZhi 2025 = 乙巳")
    func yearGanZhi2025() {
        let gz = cal.yearGanZhi(for: 2025)
        #expect(gz.chinese == "乙巳")
    }

    @Test("dayGanZhi reference: 2000-01-07 = 甲子")
    func dayGanZhiReference() {
        let gz = cal.dayGanZhi(for: SolarDate(year: 2000, month: 1, day: 7)!)
        #expect(gz.chinese == "甲子")
    }

    @Test("monthGanZhi: 2025-03-15 (after 惊蛰, month 2)")
    func monthGanZhiMarch() {
        // 2025 惊蛰 is around Mar 5. Mar 15 is in month 2 (卯月).
        // Year 2025 = 乙(1). Base = (1%5)*2+2 = 4. Month 2 = ganIndex (4+1)%10=5=己
        // zhiIndex = (2+1)%12 = 3 = 卯
        let gz = cal.monthGanZhi(for: SolarDate(year: 2025, month: 3, day: 15)!)
        #expect(gz.zhi == .mao) // 卯月
    }

    @Test("monthGanZhi: before 立春 belongs to previous year cycle")
    func monthGanZhiBeforeLiChun() {
        // 2025 立春 is around Feb 3. Jan 20 is before it → month 12 (丑月) of year 2024 cycle
        let gz = cal.monthGanZhi(for: SolarDate(year: 2025, month: 1, day: 20)!)
        #expect(gz.zhi == .chou) // 丑月 (month 12)
    }

    @Test("monthGanZhi: after 立春 belongs to new year cycle")
    func monthGanZhiAfterLiChun() {
        // 2025 立春 is around Feb 3. Feb 10 is after it → month 1 (寅月) of year 2025 cycle
        let gz = cal.monthGanZhi(for: SolarDate(year: 2025, month: 2, day: 10)!)
        #expect(gz.zhi == .yin) // 寅月 (month 1)
    }
}

// MARK: - Zodiac

@Suite("LunarCalendar - Zodiac")
struct CalendarZodiacTests {

    let cal = LunarCalendar.shared

    @Test("2025 = Snake")
    func zodiac2025() {
        #expect(cal.zodiac(for: 2025) == .snake)
        #expect(cal.zodiac(for: 2025).emoji == "🐍")
    }

    @Test("2024 = Dragon")
    func zodiac2024() {
        #expect(cal.zodiac(for: 2024) == .dragon)
    }
}

// MARK: - Birthday

@Suite("LunarCalendar - Birthday")
struct CalendarBirthdayTests {

    let cal = LunarCalendar.shared

    @Test("nextLunarBirthday: 8/15 after 2025-01-01")
    func nextBirthdayMidAutumn() {
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        let next = cal.nextLunarBirthday(month: 8, day: 15, after: after)
        #expect(next == SolarDate(year: 2025, month: 10, day: 6))
    }

    @Test("nextLunarBirthday: pre-CNY should not skip tail month of current lunar year")
    func preCNYTailMonth() {
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        // 2025-01-01 is still lunar year 2024. Lunar 12/15 occurs on 2025-01-14.
        let next = cal.nextLunarBirthday(month: 12, day: 15, after: after)
        #expect(next == SolarDate(year: 2025, month: 1, day: 14))
    }

    @Test("nextLunarBirthday: leap month fallback")
    func leapMonthFallback() {
        // Leap 4 birthday, but 2025 has no leap 4 → falls back to regular month 4
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        let next = cal.nextLunarBirthday(month: 4, day: 15, isLeapMonth: true, after: after)
        #expect(next != nil)
        // Should be regular month 4 day 15 of 2025
        let lunar = cal.lunarDate(from: next!)
        #expect(lunar?.month == 4)
        #expect(lunar?.day == 15)
        #expect(lunar?.isLeapMonth == false)
    }

    @Test("nextLunarBirthday: leap month exists → uses leap month")
    func leapMonthExists() {
        // 2025 has leap 6. Birthday is leap 6/15 → should get leap 6/15 in 2025
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        let next = cal.nextLunarBirthday(month: 6, day: 15, isLeapMonth: true, after: after)
        #expect(next != nil)
        let lunar = cal.lunarDate(from: next!)
        #expect(lunar?.month == 6)
        #expect(lunar?.isLeapMonth == true)
    }

    @Test("nextLunarBirthday: day 30 in small month → downgrade to 29")
    func smallMonthDowngrade() {
        // Find a year where month 1 is 29 days (small month)
        // Birthday: month 1 day 30 → should downgrade to day 29
        let after = SolarDate(year: 2024, month: 1, day: 1)!
        var found = false
        for year in 2024...2100 {
            if let days = cal.daysInMonth(1, isLeap: false, year: year), days == 29 {
                let next = cal.nextLunarBirthday(month: 1, day: 30, after: SolarDate(year: year - 1, month: 12, day: 31)!)
                if let next, let lunar = cal.lunarDate(from: next), lunar.year == year {
                    #expect(lunar.day == 29)
                    found = true
                    break
                }
            }
        }
        #expect(found, "Should find a year with small month 1 for day downgrade test")
        _ = after
    }

    @Test("lunarBirthdays returns correct count")
    func birthdaysList() {
        let after = SolarDate(year: 2020, month: 1, day: 1)!
        let birthdays = cal.lunarBirthdays(month: 8, day: 15, from: after, years: 5)
        #expect(birthdays.count == 5)
    }

    @Test("lunarBirthdays: pre-CNY first result should be current Gregorian year")
    func birthdaysPreCNY() {
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        let birthdays = cal.lunarBirthdays(month: 12, day: 15, from: after, years: 2)
        #expect(birthdays.count == 2)
        #expect(birthdays.first == SolarDate(year: 2025, month: 1, day: 14))
    }

    @Test("lunarBirthdays are in ascending order")
    func birthdaysOrdered() {
        let after = SolarDate(year: 2020, month: 1, day: 1)!
        let birthdays = cal.lunarBirthdays(month: 1, day: 1, from: after, years: 10)
        for i in 1..<birthdays.count {
            #expect(birthdays[i] > birthdays[i - 1])
        }
    }

    @Test("birthday APIs reject invalid month/day safely")
    func invalidBirthdayInput() {
        let after = SolarDate(year: 2025, month: 1, day: 1)!
        #expect(cal.nextLunarBirthday(month: 0, day: 15, after: after) == nil)
        #expect(cal.nextLunarBirthday(month: 13, day: 15, after: after) == nil)
        #expect(cal.nextLunarBirthday(month: 8, day: 0, after: after) == nil)
        #expect(cal.nextLunarBirthday(month: 8, day: 31, after: after) == nil)

        #expect(cal.lunarBirthdays(month: 0, day: 15, from: after, years: 3).isEmpty)
        #expect(cal.lunarBirthdays(month: 13, day: 15, from: after, years: 3).isEmpty)
        #expect(cal.lunarBirthdays(month: 8, day: 0, from: after, years: 3).isEmpty)
        #expect(cal.lunarBirthdays(month: 8, day: 31, from: after, years: 3).isEmpty)
    }
}

// MARK: - Version & Metadata

@Suite("LunarCalendar - Metadata")
struct CalendarMetadataTests {

    @Test("version is set")
    func version() {
        #expect(LunarCalendar.version == "1.0.0")
    }

    @Test("shared is same instance")
    func singleton() {
        #expect(LunarCalendar.shared === LunarCalendar.shared)
    }
}
