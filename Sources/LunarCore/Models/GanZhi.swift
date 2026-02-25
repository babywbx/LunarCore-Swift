// Sexagenary Cycle (干支) — Stem-Branch combination
// Valid pairs require same parity: gan.rawValue and zhi.rawValue both even or both odd.

public struct GanZhi: Equatable, Hashable, Sendable {
    public let gan: TianGan
    public let zhi: DiZhi

    // 60-cycle index (0 = 甲子, 59 = 癸亥)
    public var index: Int {
        ((6 * gan.rawValue - 5 * zhi.rawValue) % 60 + 60) % 60
    }

    public var chinese: String {
        "\(gan.chinese)\(zhi.chinese)"
    }

    // Failable: rejects invalid combinations (mismatched parity)
    public init?(gan: TianGan, zhi: DiZhi) {
        guard gan.rawValue % 2 == zhi.rawValue % 2 else { return nil }
        self.gan = gan
        self.zhi = zhi
    }

    // Create from 60-cycle index (0-59), always valid
    public init(index: Int) {
        let i = ((index % 60) + 60) % 60
        self.gan = TianGan.allCases[i % TianGan.allCases.count]
        self.zhi = DiZhi.allCases[i % DiZhi.allCases.count]
    }

    // MARK: - Pure math calculations

    // Year GanZhi from lunar year number
    // Boundary: traditionally 立春, handled by caller
    public static func year(_ lunarYear: Int) -> GanZhi {
        GanZhi(index: ((lunarYear - 4) % 60 + 60) % 60)
    }

    // Month GanZhi from year's TianGan and month number (1-12)
    // Boundary: each 节 (Jie) solar term, handled by caller
    // Rule: 五虎遁元 — base = (yearGan % 5) * 2 + 2, diZhi starts at 寅 for month 1
    public static func month(yearGan: TianGan, month: Int) -> GanZhi? {
        guard (1...12).contains(month) else { return nil }
        let ganIndex = ((yearGan.rawValue % 5) * 2 + 2 + month - 1) % 10
        let zhiIndex = (month + 1) % 12
        // Derive 60-cycle index from gan/zhi indices
        return GanZhi(index: ((6 * ganIndex - 5 * zhiIndex) % 60 + 60) % 60)
    }

    // Day GanZhi from solar date
    // Reference: 2000-01-07 = 甲子日 (index 0)
    // Uses JulianDay for day difference calculation
    public static func day(for date: SolarDate) -> GanZhi {
        // JD at midnight of 2000-01-07
        let referenceJD = 2_451_550.5
        let jd = JulianDay.fromGregorian(
            year: date.year, month: date.month, day: Double(date.day))
        let diff = Int((jd - referenceJD).rounded())
        return GanZhi(index: ((diff % 60) + 60) % 60)
    }
}
