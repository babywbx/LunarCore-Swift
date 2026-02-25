import Testing
@testable import LunarCore

@Suite("LunarFormatter - Chinese")
struct FormatterChineseTests {
    let fmt = LunarFormatter(locale: .chinese)

    // MARK: - Month names

    @Test func monthNames() {
        #expect(fmt.monthName(1) == "正月")
        #expect(fmt.monthName(2) == "二月")
        #expect(fmt.monthName(6) == "六月")
        #expect(fmt.monthName(10) == "十月")
        #expect(fmt.monthName(11) == "十一月")
        #expect(fmt.monthName(12) == "腊月")
    }

    @Test func leapMonthNames() {
        #expect(fmt.monthName(6, isLeap: true) == "闰六月")
        #expect(fmt.monthName(4, isLeap: true) == "闰四月")
        #expect(fmt.monthName(1, isLeap: true) == "闰正月")
    }

    // MARK: - Day names

    @Test func dayNames_chu() {
        #expect(fmt.dayName(1) == "初一")
        #expect(fmt.dayName(2) == "初二")
        #expect(fmt.dayName(9) == "初九")
        #expect(fmt.dayName(10) == "初十")
    }

    @Test func dayNames_shi() {
        #expect(fmt.dayName(11) == "十一")
        #expect(fmt.dayName(15) == "十五")
        #expect(fmt.dayName(19) == "十九")
    }

    @Test func dayNames_ershi() {
        #expect(fmt.dayName(20) == "二十")
    }

    @Test func dayNames_nian() {
        #expect(fmt.dayName(21) == "廿一")
        #expect(fmt.dayName(23) == "廿三")
        #expect(fmt.dayName(29) == "廿九")
    }

    @Test func dayNames_sanshi() {
        #expect(fmt.dayName(30) == "三十")
    }

    // MARK: - Chinese year

    @Test func chineseYear() {
        #expect(fmt.chineseYear(2025) == "二〇二五")
        #expect(fmt.chineseYear(1900) == "一九〇〇")
        #expect(fmt.chineseYear(2000) == "二〇〇〇")
        #expect(fmt.chineseYear(2100) == "二一〇〇")
    }

    // MARK: - Full string

    @Test func fullString() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 1, day: 15))
        #expect(fmt.string(from: lunar) == "二〇二五年正月十五")
    }

    @Test func fullStringGanZhi() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 1, day: 15))
        #expect(fmt.string(from: lunar, useGanZhi: true) == "乙巳年正月十五")
    }

    @Test func fullStringLeapMonth() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 6, day: 1, isLeapMonth: true))
        #expect(fmt.string(from: lunar) == "二〇二五年闰六月初一")
    }

    // MARK: - Short string

    @Test func shortString() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 8, day: 15))
        #expect(fmt.shortString(from: lunar) == "八月十五")
    }

    @Test func shortStringLeap() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 4, day: 1, isLeapMonth: true))
        #expect(fmt.shortString(from: lunar) == "闰四月初一")
    }
}

@Suite("LunarFormatter - English")
struct FormatterEnglishTests {
    let fmt = LunarFormatter(locale: .english)

    @Test func monthNames() {
        #expect(fmt.monthName(1) == "1st Month")
        #expect(fmt.monthName(2) == "2nd Month")
        #expect(fmt.monthName(3) == "3rd Month")
        #expect(fmt.monthName(4) == "4th Month")
        #expect(fmt.monthName(12) == "12th Month")
        #expect(fmt.monthName(21) == "21st Month")
        #expect(fmt.monthName(22) == "22nd Month")
        #expect(fmt.monthName(23) == "23rd Month")
        #expect(fmt.monthName(11) == "11th Month")
        #expect(fmt.monthName(13) == "13th Month")
    }

    @Test func leapMonthName() {
        #expect(fmt.monthName(6, isLeap: true) == "Leap 6th Month")
    }

    @Test func dayNames() {
        #expect(fmt.dayName(1) == "Day 1")
        #expect(fmt.dayName(15) == "Day 15")
        #expect(fmt.dayName(30) == "Day 30")
    }

    @Test func shortString() throws {
        let lunar = try #require(LunarDate(year: 2025, month: 8, day: 15))
        #expect(fmt.shortString(from: lunar) == "8th Month Day 15")
    }
}
