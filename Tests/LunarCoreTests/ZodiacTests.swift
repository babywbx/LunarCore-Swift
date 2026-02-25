import Testing
@testable import LunarCore

@Suite("ChineseZodiac")
struct ZodiacTests {
    @Test func caseCount() {
        #expect(ChineseZodiac.allCases.count == 12)
    }

    @Test func year2025Snake() {
        let z = ChineseZodiac.fromYear(2025)
        #expect(z == .snake)
        #expect(z.chinese == "蛇")
        #expect(z.english == "Snake")
        #expect(z.emoji == "🐍")
    }

    @Test func year2024Dragon() {
        let z = ChineseZodiac.fromYear(2024)
        #expect(z == .dragon)
        #expect(z.emoji == "🐉")
    }

    @Test func year2000Dragon() {
        #expect(ChineseZodiac.fromYear(2000) == .dragon)
    }

    @Test func year1900Rat() {
        #expect(ChineseZodiac.fromYear(1900) == .rat)
    }

    @Test func year1984Rat() {
        #expect(ChineseZodiac.fromYear(1984) == .rat)
    }

    @Test func fullCycle() {
        // 12-year cycle from 2020
        let expected: [ChineseZodiac] = [
            .rat, .ox, .tiger, .rabbit, .dragon, .snake,
            .horse, .goat, .monkey, .rooster, .dog, .pig,
        ]
        for (i, zodiac) in expected.enumerated() {
            #expect(ChineseZodiac.fromYear(2020 + i) == zodiac)
        }
    }

    @Test func emojiList() {
        let emojis = ["🐀", "🐂", "🐅", "🐇", "🐉", "🐍", "🐎", "🐐", "🐒", "🐓", "🐕", "🐖"]
        for (i, emoji) in emojis.enumerated() {
            #expect(ChineseZodiac(rawValue: i)?.emoji == emoji)
        }
    }

    @Test func chineseNames() {
        let names = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
        for (i, name) in names.enumerated() {
            #expect(ChineseZodiac(rawValue: i)?.chinese == name)
        }
    }
}
