/// The twelve Earthly Branches (地支).
///
/// Ordered: 子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥 (raw values 0–11).
public enum DiZhi: Int, CaseIterable, Sendable, Equatable, Hashable {
    case zi = 0, chou, yin, mao, chen, si, wu, wei, shen, you, xu, hai

    /// Chinese character representation (e.g. "子").
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

    /// Pinyin with tone marks (e.g. "zǐ").
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
