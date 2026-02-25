import Testing
import Foundation
@testable import LunarCore

@Suite("TianGan")
struct TianGanTests {
    @Test func caseCount() {
        #expect(TianGan.allCases.count == 10)
    }

    @Test func chineseNames() {
        let expected = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
        for (i, name) in expected.enumerated() {
            #expect(TianGan(rawValue: i)?.chinese == name)
        }
    }

    @Test func rawValues() {
        #expect(TianGan.jia.rawValue == 0)
        #expect(TianGan.gui.rawValue == 9)
    }

    @Test func pinyinNotEmpty() {
        for gan in TianGan.allCases {
            #expect(!gan.pinyin.isEmpty)
        }
    }
}

@Suite("DiZhi")
struct DiZhiTests {
    @Test func caseCount() {
        #expect(DiZhi.allCases.count == 12)
    }

    @Test func chineseNames() {
        let expected = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
        for (i, name) in expected.enumerated() {
            #expect(DiZhi(rawValue: i)?.chinese == name)
        }
    }

    @Test func rawValues() {
        #expect(DiZhi.zi.rawValue == 0)
        #expect(DiZhi.hai.rawValue == 11)
    }
}

@Suite("SolarDate")
struct SolarDateTests {
    @Test func comparable() throws {
        let a = try #require(SolarDate(year: 2025, month: 1, day: 1))
        let b = try #require(SolarDate(year: 2025, month: 1, day: 2))
        let c = try #require(SolarDate(year: 2025, month: 2, day: 1))
        let d = try #require(SolarDate(year: 2026, month: 1, day: 1))
        #expect(a < b)
        #expect(b < c)
        #expect(c < d)
        let sameAsA = try #require(SolarDate(year: 2025, month: 1, day: 1))
        #expect(a == sameAsA)
    }

    @Test func dateRoundTrip() throws {
        let tz = TimeZone(identifier: "Asia/Shanghai")!
        let solar = try #require(SolarDate(year: 2025, month: 6, day: 15))
        let date = try #require(solar.toDate(in: tz))
        let back = try #require(SolarDate.from(date, in: tz))
        #expect(back == solar)
    }

    @Test func dateRoundTripUTC() throws {
        let tz = TimeZone(identifier: "UTC")!
        let solar = try #require(SolarDate(year: 2000, month: 1, day: 1))
        let date = try #require(solar.toDate(in: tz))
        let back = try #require(SolarDate.from(date, in: tz))
        #expect(back == solar)
    }

    @Test func invalidMonthRejected() {
        #expect(SolarDate(year: 2025, month: 0, day: 1) == nil)
        #expect(SolarDate(year: 2025, month: 13, day: 1) == nil)
    }

    @Test func invalidDayRejected() {
        #expect(SolarDate(year: 2025, month: 1, day: 0) == nil)
        #expect(SolarDate(year: 2025, month: 1, day: 32) == nil)
        #expect(SolarDate(year: 2025, month: 2, day: 29) == nil)
        #expect(SolarDate(year: 2025, month: 2, day: 30) == nil)
    }

    @Test func leapDayAccepted() {
        #expect(SolarDate(year: 2024, month: 2, day: 29) != nil)
    }
}

@Suite("LunarDate")
struct LunarDateTests {
    @Test func comparable() throws {
        let a = try #require(LunarDate(year: 2025, month: 6, day: 1))
        let aLeap = try #require(LunarDate(year: 2025, month: 6, day: 1, isLeapMonth: true))
        let b = try #require(LunarDate(year: 2025, month: 7, day: 1))

        // Regular month comes before leap month of same number
        #expect(a < aLeap)
        // Leap month comes before next month
        #expect(aLeap < b)
    }

    @Test func defaultNotLeap() throws {
        let d = try #require(LunarDate(year: 2025, month: 1, day: 1))
        #expect(!d.isLeapMonth)
    }

    @Test func equality() throws {
        let a = try #require(LunarDate(year: 2025, month: 1, day: 1))
        let b = try #require(LunarDate(year: 2025, month: 1, day: 1, isLeapMonth: false))
        let c = try #require(LunarDate(year: 2025, month: 1, day: 1, isLeapMonth: true))
        #expect(a == b)
        #expect(a != c)
    }

    @Test func invalidMonthRejected() {
        #expect(LunarDate(year: 2025, month: 0, day: 1) == nil)
        #expect(LunarDate(year: 2025, month: 13, day: 1) == nil)
    }

    @Test func invalidDayRejected() {
        #expect(LunarDate(year: 2025, month: 1, day: 0) == nil)
        #expect(LunarDate(year: 2025, month: 1, day: 31) == nil)
    }
}

@Suite("SolarTerm")
struct SolarTermTests {
    @Test func caseCount() {
        #expect(SolarTerm.allCases.count == 24)
    }

    @Test func solarLongitudes() {
        #expect(SolarTerm.xiaoHan.solarLongitude == 285)
        #expect(SolarTerm.chunFen.solarLongitude == 0)
        #expect(SolarTerm.xiaZhi.solarLongitude == 90)
        #expect(SolarTerm.qiuFen.solarLongitude == 180)
        #expect(SolarTerm.dongZhi.solarLongitude == 270)
        #expect(SolarTerm.liChun.solarLongitude == 315)
        #expect(SolarTerm.daHan.solarLongitude == 300)
    }

    @Test func zhongQi() {
        // 节 (Jie) — even raw values
        #expect(!SolarTerm.xiaoHan.isZhongQi)   // 小寒 = 节
        #expect(!SolarTerm.liChun.isZhongQi)     // 立春 = 节
        #expect(!SolarTerm.jingZhe.isZhongQi)    // 惊蛰 = 节

        // 中气 (Zhong Qi) — odd raw values
        #expect(SolarTerm.daHan.isZhongQi)       // 大寒 = 中气
        #expect(SolarTerm.yuShui.isZhongQi)      // 雨水 = 中气
        #expect(SolarTerm.chunFen.isZhongQi)     // 春分 = 中气
        #expect(SolarTerm.dongZhi.isZhongQi)     // 冬至 = 中气
    }

    @Test func chineseNamesNotEmpty() {
        for term in SolarTerm.allCases {
            #expect(!term.chineseName.isEmpty)
        }
    }

    @Test func englishNamesNotEmpty() {
        for term in SolarTerm.allCases {
            #expect(!term.englishName.isEmpty)
        }
    }

    @Test func longitudesCover360() {
        let longitudes = Set(SolarTerm.allCases.map { $0.solarLongitude })
        #expect(longitudes.count == 24)
        // Each 15 degrees from 0 to 345
        for i in 0..<24 {
            #expect(longitudes.contains(Double(i * 15)))
        }
    }
}
