/// The twelve Chinese Zodiac animals (生肖).
///
/// Ordered: Rat, Ox, Tiger, Rabbit, Dragon, Snake,
/// Horse, Goat, Monkey, Rooster, Dog, Pig.
public enum ChineseZodiac: Int, CaseIterable, Sendable, Equatable, Hashable {
    case rat = 0, ox, tiger, rabbit, dragon, snake,
         horse, goat, monkey, rooster, dog, pig

    /// Chinese character (e.g. "鼠").
    public var chinese: String {
        switch self {
        case .rat: "鼠"
        case .ox: "牛"
        case .tiger: "虎"
        case .rabbit: "兔"
        case .dragon: "龙"
        case .snake: "蛇"
        case .horse: "马"
        case .goat: "羊"
        case .monkey: "猴"
        case .rooster: "鸡"
        case .dog: "狗"
        case .pig: "猪"
        }
    }

    /// English name (e.g. "Rat").
    public var english: String {
        switch self {
        case .rat: "Rat"
        case .ox: "Ox"
        case .tiger: "Tiger"
        case .rabbit: "Rabbit"
        case .dragon: "Dragon"
        case .snake: "Snake"
        case .horse: "Horse"
        case .goat: "Goat"
        case .monkey: "Monkey"
        case .rooster: "Rooster"
        case .dog: "Dog"
        case .pig: "Pig"
        }
    }

    /// Emoji representation (e.g. "🐀").
    public var emoji: String {
        switch self {
        case .rat: "🐀"
        case .ox: "🐂"
        case .tiger: "🐅"
        case .rabbit: "🐇"
        case .dragon: "🐉"
        case .snake: "🐍"
        case .horse: "🐎"
        case .goat: "🐐"
        case .monkey: "🐒"
        case .rooster: "🐓"
        case .dog: "🐕"
        case .pig: "🐖"
        }
    }

    /// Returns the zodiac for a lunar year. Boundary: 正月初一.
    public static func fromYear(_ lunarYear: Int) -> ChineseZodiac {
        let index = ((lunarYear - 4) % 12 + 12) % 12
        return ChineseZodiac.allCases[index]
    }
}
