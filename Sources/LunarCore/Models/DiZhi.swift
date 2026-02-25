// Earthly Branches (地支)

public enum DiZhi: Int, CaseIterable, Sendable, Equatable, Hashable {
    case zi = 0, chou, yin, mao, chen, si, wu, wei, shen, you, xu, hai

    public var chinese: String {
        switch self {
        case .zi: "子"
        case .chou: "丑"
        case .yin: "寅"
        case .mao: "卯"
        case .chen: "辰"
        case .si: "巳"
        case .wu: "午"
        case .wei: "未"
        case .shen: "申"
        case .you: "酉"
        case .xu: "戌"
        case .hai: "亥"
        }
    }

    public var pinyin: String {
        switch self {
        case .zi: "zǐ"
        case .chou: "chǒu"
        case .yin: "yín"
        case .mao: "mǎo"
        case .chen: "chén"
        case .si: "sì"
        case .wu: "wǔ"
        case .wei: "wèi"
        case .shen: "shēn"
        case .you: "yǒu"
        case .xu: "xū"
        case .hai: "hài"
        }
    }
}
