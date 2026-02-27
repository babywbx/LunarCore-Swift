import Testing
import Foundation

@testable import LunarCore

@Suite("Performance")
struct PerformanceTests {

    let cal = LunarCalendar.shared

    @Test("10000 solar→lunar conversions < 100ms")
    func solarToLunarBulk() {
        // Pre-generate dates to exclude generation time from measurement.
        var rng = RandomNumberGenerator_LCG(seed: 42)
        let dates = (0..<10_000).compactMap { _ -> SolarDate? in
            let year = Int.random(in: 1900...2100, using: &rng)
            let month = Int.random(in: 1...12, using: &rng)
            let day = Int.random(in: 1...28, using: &rng)
            return SolarDate(year: year, month: month, day: day)
        }

        var sink = 0
        let start = CFAbsoluteTimeGetCurrent()
        for date in dates {
            if let lunar = cal.lunarDate(from: date) {
                sink &+= lunar.hashValue
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 100ms in release; 200ms budget for debug/CI.
        #expect(sink != 0)
        #expect(elapsed < 0.2, "10000 solar→lunar took \(elapsed)s, expected < 0.2s")
    }

    @Test("10000 lunar→solar conversions < 100ms")
    func lunarToSolarBulk() {
        var rng = RandomNumberGenerator_LCG(seed: 99)
        let dates = (0..<10_000).compactMap { _ -> LunarDate? in
            let year = Int.random(in: 1900...2100, using: &rng)
            let month = Int.random(in: 1...12, using: &rng)
            let day = Int.random(in: 1...29, using: &rng)
            return LunarDate(year: year, month: month, day: day)
        }

        var sink = 0
        let start = CFAbsoluteTimeGetCurrent()
        for date in dates {
            if let solar = cal.solarDate(from: date) {
                sink &+= solar.hashValue
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 100ms in release; 200ms budget for debug/CI.
        #expect(sink != 0)
        #expect(elapsed < 0.2, "10000 lunar→solar took \(elapsed)s, expected < 0.2s")
    }

    @Test("24 solar terms × 201 years < 200ms")
    func solarTermBulk() {
        var sink = 0
        let start = CFAbsoluteTimeGetCurrent()
        for year in 1900...2100 {
            for item in cal.solarTerms(in: year) {
                sink &+= item.date.hashValue
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // Solar terms are computed + cached. First run computes all, should still be fast.
        #expect(sink != 0)
        #expect(elapsed < 0.2, "Solar terms for 201 years took \(elapsed)s, expected < 0.2s")
    }

    @Test("mixed workload: 5000 conversions + 50 years terms < 200ms")
    func mixedWorkload() {
        var rng = RandomNumberGenerator_LCG(seed: 7)
        let solarDates = (0..<2500).compactMap { _ -> SolarDate? in
            SolarDate(
                year: Int.random(in: 1900...2100, using: &rng),
                month: Int.random(in: 1...12, using: &rng),
                day: Int.random(in: 1...28, using: &rng))
        }
        let lunarDates = (0..<2500).compactMap { _ -> LunarDate? in
            LunarDate(
                year: Int.random(in: 1900...2100, using: &rng),
                month: Int.random(in: 1...12, using: &rng),
                day: Int.random(in: 1...29, using: &rng))
        }

        var sink = 0
        let start = CFAbsoluteTimeGetCurrent()
        for d in solarDates {
            if let lunar = cal.lunarDate(from: d) {
                sink &+= lunar.hashValue
            }
        }
        for d in lunarDates {
            if let solar = cal.solarDate(from: d) {
                sink &+= solar.hashValue
            }
        }
        for year in 2000...2049 {
            for item in cal.solarTerms(in: year) {
                sink &+= item.date.hashValue
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        #expect(sink != 0)
        #expect(elapsed < 0.2, "Mixed workload took \(elapsed)s, expected < 0.2s")
    }
}

// Deterministic PRNG for reproducible test data.
private struct RandomNumberGenerator_LCG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
