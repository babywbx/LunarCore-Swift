// Heavenly Stems (天干)

public enum TianGan: Int, CaseIterable, Sendable, Equatable, Hashable {
    case jia = 0, yi, bing, ding, wu, ji, geng, xin, ren, gui

    public var chinese: String {
        switch self {
        case .jia: "甲"
        case .yi: "乙"
        case .bing: "丙"
        case .ding: "丁"
        case .wu: "戊"
        case .ji: "己"
        case .geng: "庚"
        case .xin: "辛"
        case .ren: "壬"
        case .gui: "癸"
        }
    }

    public var pinyin: String {
        switch self {
        case .jia: "jiǎ"
        case .yi: "yǐ"
        case .bing: "bǐng"
        case .ding: "dīng"
        case .wu: "wù"
        case .ji: "jǐ"
        case .geng: "gēng"
        case .xin: "xīn"
        case .ren: "rén"
        case .gui: "guǐ"
        }
    }
}
