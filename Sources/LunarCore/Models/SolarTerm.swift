// 24 Solar Terms (二十四节气)
// Ordered starting from 小寒, matching the traditional calendar year cycle.
// Solar longitude formula: (285 + rawValue * 15) % 360

public enum SolarTerm: Int, CaseIterable, Sendable, Equatable, Hashable {
    case xiaoHan = 0       // 小寒 285°
    case daHan             // 大寒 300°
    case liChun            // 立春 315°
    case yuShui            // 雨水 330°
    case jingZhe           // 惊蛰 345°
    case chunFen           // 春分 0°
    case qingMing          // 清明 15°
    case guYu              // 谷雨 30°
    case liXia             // 立夏 45°
    case xiaoMan           // 小满 60°
    case mangZhong         // 芒种 75°
    case xiaZhi            // 夏至 90°
    case xiaoShu           // 小暑 105°
    case daShu             // 大暑 120°
    case liQiu             // 立秋 135°
    case chuShu            // 处暑 150°
    case baiLu             // 白露 165°
    case qiuFen            // 秋分 180°
    case hanLu             // 寒露 195°
    case shuangJiang       // 霜降 210°
    case liDong            // 立冬 225°
    case xiaoXue           // 小雪 240°
    case daXue             // 大雪 255°
    case dongZhi           // 冬至 270°

    // Solar longitude in degrees
    public var solarLongitude: Double {
        Double((285 + rawValue * 15) % 360)
    }

    // 中气 (Zhong Qi) are at odd indices; 节 (Jie) are at even indices
    public var isZhongQi: Bool {
        rawValue % 2 == 1
    }

    public var chineseName: String {
        switch self {
        case .xiaoHan: "小寒"
        case .daHan: "大寒"
        case .liChun: "立春"
        case .yuShui: "雨水"
        case .jingZhe: "惊蛰"
        case .chunFen: "春分"
        case .qingMing: "清明"
        case .guYu: "谷雨"
        case .liXia: "立夏"
        case .xiaoMan: "小满"
        case .mangZhong: "芒种"
        case .xiaZhi: "夏至"
        case .xiaoShu: "小暑"
        case .daShu: "大暑"
        case .liQiu: "立秋"
        case .chuShu: "处暑"
        case .baiLu: "白露"
        case .qiuFen: "秋分"
        case .hanLu: "寒露"
        case .shuangJiang: "霜降"
        case .liDong: "立冬"
        case .xiaoXue: "小雪"
        case .daXue: "大雪"
        case .dongZhi: "冬至"
        }
    }

    public var englishName: String {
        switch self {
        case .xiaoHan: "Minor Cold"
        case .daHan: "Major Cold"
        case .liChun: "Start of Spring"
        case .yuShui: "Rain Water"
        case .jingZhe: "Awakening of Insects"
        case .chunFen: "Spring Equinox"
        case .qingMing: "Clear and Bright"
        case .guYu: "Grain Rain"
        case .liXia: "Start of Summer"
        case .xiaoMan: "Grain Buds"
        case .mangZhong: "Grain in Ear"
        case .xiaZhi: "Summer Solstice"
        case .xiaoShu: "Minor Heat"
        case .daShu: "Major Heat"
        case .liQiu: "Start of Autumn"
        case .chuShu: "End of Heat"
        case .baiLu: "White Dew"
        case .qiuFen: "Autumn Equinox"
        case .hanLu: "Cold Dew"
        case .shuangJiang: "Frost's Descent"
        case .liDong: "Start of Winter"
        case .xiaoXue: "Minor Snow"
        case .daXue: "Major Snow"
        case .dongZhi: "Winter Solstice"
        }
    }
}
