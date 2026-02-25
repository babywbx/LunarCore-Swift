import Testing
@testable import LunarCore

@Suite("GanZhi")
struct GanZhiTests {

    // MARK: - Index calculation

    @Test func indexJiaZi() throws {
        let gz = try #require(GanZhi(gan: .jia, zhi: .zi))
        #expect(gz.index == 0)
        #expect(gz.chinese == "甲子")
    }

    @Test func indexGuiHai() throws {
        let gz = try #require(GanZhi(gan: .gui, zhi: .hai))
        #expect(gz.index == 59)
        #expect(gz.chinese == "癸亥")
    }

    @Test func indexFromInit() {
        // Verify round-trip: init(index:) → index property
        for i in 0..<60 {
            let gz = GanZhi(index: i)
            #expect(gz.index == i)
        }
    }

    @Test func indexSpecificValues() throws {
        // 甲戌 = index 10
        #expect(try #require(GanZhi(gan: .jia, zhi: .xu)).index == 10)
        // 丙子 = index 12
        #expect(try #require(GanZhi(gan: .bing, zhi: .zi)).index == 12)
        // 壬申 = index 8
        #expect(try #require(GanZhi(gan: .ren, zhi: .shen)).index == 8)
    }

    @Test func invalidCombinationRejected() {
        // Mismatched parity: 甲(0, even) + 丑(1, odd) is not a valid pair
        #expect(GanZhi(gan: .jia, zhi: .chou) == nil)
        #expect(GanZhi(gan: .yi, zhi: .zi) == nil)
        // Same parity should succeed
        #expect(GanZhi(gan: .jia, zhi: .zi) != nil)
        #expect(GanZhi(gan: .yi, zhi: .chou) != nil)
    }

    // MARK: - Year GanZhi

    @Test func yearGanZhi2025() {
        let gz = GanZhi.year(2025)
        #expect(gz.gan == .yi)
        #expect(gz.zhi == .si)
        #expect(gz.chinese == "乙巳")
    }

    @Test func yearGanZhi2024() {
        let gz = GanZhi.year(2024)
        #expect(gz.gan == .jia)
        #expect(gz.zhi == .chen)
        #expect(gz.chinese == "甲辰")
    }

    @Test func yearGanZhi2000() {
        let gz = GanZhi.year(2000)
        #expect(gz.gan == .geng)
        #expect(gz.zhi == .chen)
        #expect(gz.chinese == "庚辰")
    }

    @Test func yearGanZhi1984() {
        // 1984 = 甲子年
        let gz = GanZhi.year(1984)
        #expect(gz.gan == .jia)
        #expect(gz.zhi == .zi)
        #expect(gz.chinese == "甲子")
    }

    @Test func yearGanZhi1900() {
        // 1900 = 庚子年
        let gz = GanZhi.year(1900)
        #expect(gz.gan == .geng)
        #expect(gz.zhi == .zi)
        #expect(gz.chinese == "庚子")
    }

    // MARK: - Month GanZhi

    @Test func monthGanZhi_jiaYear() throws {
        // 甲年: 正月 = 丙寅
        let gz = try #require(GanZhi.month(yearGan: .jia, month: 1))
        #expect(gz.gan == .bing)
        #expect(gz.zhi == .yin)
    }

    @Test func monthGanZhi_yiYear() throws {
        // 乙年 (e.g. 2025): 正月 = 戊寅
        let gz = try #require(GanZhi.month(yearGan: .yi, month: 1))
        #expect(gz.gan == .wu)
        #expect(gz.zhi == .yin)
    }

    @Test func monthGanZhi_allMonths() throws {
        // Verify DiZhi cycle: month 1 = 寅, month 12 = 丑
        for m in 1...12 {
            let gz = try #require(GanZhi.month(yearGan: .jia, month: m))
            let expectedZhi = DiZhi.allCases[(m + 1) % DiZhi.allCases.count]
            #expect(gz.zhi == expectedZhi)
        }
    }

    @Test func monthGanZhi_fiveRules() throws {
        // 五虎遁元: 甲己→丙, 乙庚→戊, 丙辛→庚, 丁壬→壬, 戊癸→甲
        let expected: [(TianGan, TianGan)] = [
            (.jia, .bing), (.ji, .bing),
            (.yi, .wu), (.geng, .wu),
            (.bing, .geng), (.xin, .geng),
            (.ding, .ren), (.ren, .ren),
            (.wu, .jia), (.gui, .jia),
        ]
        for (yearGan, expectedMonthGan) in expected {
            let gz = try #require(GanZhi.month(yearGan: yearGan, month: 1))
            #expect(gz.gan == expectedMonthGan,
                    "Year \(yearGan.chinese): expected \(expectedMonthGan.chinese), got \(gz.gan.chinese)")
        }
    }

    @Test func monthGanZhi_invalidMonthRejected() {
        #expect(GanZhi.month(yearGan: .jia, month: 0) == nil)
        #expect(GanZhi.month(yearGan: .jia, month: 13) == nil)
        #expect(GanZhi.month(yearGan: .jia, month: -1) == nil)
    }

    // MARK: - Day GanZhi

    @Test func dayGanZhi_reference() throws {
        // 2000-01-07 = 甲子日 (index 0)
        let date = try #require(SolarDate(year: 2000, month: 1, day: 7))
        let gz = GanZhi.day(for: date)
        #expect(gz.index == 0)
        #expect(gz.chinese == "甲子")
    }

    @Test func dayGanZhi_nextDay() throws {
        // 2000-01-08 = 乙丑日 (index 1)
        let date = try #require(SolarDate(year: 2000, month: 1, day: 8))
        let gz = GanZhi.day(for: date)
        #expect(gz.index == 1)
        #expect(gz.chinese == "乙丑")
    }

    @Test func dayGanZhi_cycle() throws {
        // After 60 days, should return to 甲子
        let date = try #require(SolarDate(year: 2000, month: 3, day: 7))
        let gz = GanZhi.day(for: date)
        #expect(gz.index == 0)
        #expect(gz.chinese == "甲子")
    }

    @Test func dayGanZhi_knownDate() throws {
        // 2025-01-01: verify a known date
        // Days from 2000-01-07 to 2025-01-01 = 9126 days
        // 9126 % 60 = 6 → 庚午
        let date = try #require(SolarDate(year: 2025, month: 1, day: 1))
        let gz = GanZhi.day(for: date)
        #expect(gz.index == 6)
        #expect(gz.chinese == "庚午")
    }

    @Test func dayGanZhi_beforeReference() throws {
        // 2000-01-06 = index 59 = 癸亥
        let date = try #require(SolarDate(year: 2000, month: 1, day: 6))
        let gz = GanZhi.day(for: date)
        #expect(gz.index == 59)
        #expect(gz.chinese == "癸亥")
    }
}
