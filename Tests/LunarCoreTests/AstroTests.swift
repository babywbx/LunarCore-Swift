import Testing
import Foundation
@testable import LunarCore

// MARK: - DeltaT

@Suite("DeltaT")
struct DeltaTTests {

    @Test func knownValue2000() {
        // ΔT(2000) ≈ 63.8s (observed: 63.83s)
        let dt = DeltaT.deltaT(year: 2000)
        #expect(abs(dt - 63.8) < 1.0)
    }

    @Test func knownValue1950() {
        // ΔT(1950) ≈ 29s (observed: 29.15s)
        let dt = DeltaT.deltaT(year: 1950)
        #expect(abs(dt - 29.0) < 1.0)
    }

    @Test func knownValue1900() {
        // ΔT(1900) ≈ -2.8s (observed: -2.72s)
        let dt = DeltaT.deltaT(year: 1900)
        #expect(abs(dt - (-2.8)) < 1.0)
    }

    @Test func monotonicallyIncreasingRecent() {
        // ΔT has been generally increasing since ~1902
        let dt1950 = DeltaT.deltaT(year: 1950)
        let dt1975 = DeltaT.deltaT(year: 1975)
        let dt2000 = DeltaT.deltaT(year: 2000)
        let dt2025 = DeltaT.deltaT(year: 2025)
        #expect(dt1950 < dt1975)
        #expect(dt1975 < dt2000)
        #expect(dt2000 < dt2025)
    }

    @Test func segmentBoundaryContinuity() {
        // Check continuity at segment boundaries
        let boundaries = [1920.0, 1941.0, 1961.0, 1986.0, 2005.0, 2050.0]
        for b in boundaries {
            let before = DeltaT.deltaT(year: b - 0.001)
            let after = DeltaT.deltaT(year: b + 0.001)
            // Should be continuous (< 1s gap at boundary)
            #expect(abs(before - after) < 1.0,
                    "Discontinuity at year \(b): \(before) vs \(after)")
        }
    }

    @Test func positiveAfter1902() {
        // ΔT crossed zero around 1902 and has been positive since
        for year in stride(from: 1910.0, through: 2100.0, by: 10.0) {
            let dt = DeltaT.deltaT(year: year)
            #expect(dt > 0, "ΔT(\(year)) = \(dt) should be positive")
        }
    }

    @Test func reasonableRange() {
        // ΔT should be in a reasonable range for 1900-2100
        for year in stride(from: 1900.0, through: 2100.0, by: 1.0) {
            let dt = DeltaT.deltaT(year: year)
            #expect(dt > -10 && dt < 300,
                    "ΔT(\(year)) = \(dt) out of reasonable range")
        }
    }
}

// MARK: - Nutation

@Suite("Nutation")
struct NutationTests {

    @Test func atJ2000() {
        // At J2000.0 (T=0), nutation should be a small correction
        let deltaPsi = Nutation.nutationInLongitude(T: 0)
        // Δψ at J2000 ≈ -14" to -17" → -0.004° to -0.005°
        #expect(abs(deltaPsi) < 0.01)
        #expect(deltaPsi < 0) // Should be negative at J2000
    }

    @Test func nutationRange() {
        // Nutation in longitude oscillates within ±20"
        // Over a full nutation cycle (~18.6 years), the max is about ±17.2"
        for t in stride(from: -1.0, through: 1.0, by: 0.01) {
            let deltaPsi = Nutation.nutationInLongitude(T: t)
            let deltaPsiArcsec = deltaPsi * 3600
            #expect(abs(deltaPsiArcsec) < 25,
                    "Δψ at T=\(t) = \(deltaPsiArcsec)\" exceeds expected range")
        }
    }

    @Test func obliquityRange() {
        // Nutation in obliquity oscillates within ±10"
        for t in stride(from: -1.0, through: 1.0, by: 0.01) {
            let deltaEps = Nutation.nutationInObliquity(T: t)
            let deltaEpsArcsec = deltaEps * 3600
            #expect(abs(deltaEpsArcsec) < 15,
                    "Δε at T=\(t) = \(deltaEpsArcsec)\" exceeds expected range")
        }
    }

    @Test func periodicBehavior() {
        // Nutation should oscillate and cross zero over a long interval.
        var signChanges = 0
        var previous = Nutation.nutationInLongitude(T: -1.0)
        for t in stride(from: -0.99, through: 1.0, by: 0.01) {
            let current = Nutation.nutationInLongitude(T: t)
            if (previous <= 0 && current > 0) || (previous >= 0 && current < 0) {
                signChanges += 1
            }
            previous = current
        }
        #expect(signChanges >= 2, "Expected at least two sign changes, got \(signChanges)")
    }
}

// MARK: - MeeusSun

@Suite("MeeusSun")
struct MeeusSunTests {

    @Test func longitudeAtJ2000() {
        // J2000.0 = Jan 1.5, 2000. Sun should be near 280° (Capricorn)
        let lon = MeeusSun.apparentLongitude(jde: 2451545.0)
        #expect(lon > 278 && lon < 282,
                "Sun longitude at J2000 = \(lon)°, expected ~280°")
    }

    @Test func springEquinox2000() {
        // Spring equinox 2000: ~March 20, 07:35 UT → JDE ≈ 2451623.82
        let lon = MeeusSun.apparentLongitude(jde: 2451623.82)
        #expect(abs(lon) < 0.05 || abs(lon - 360) < 0.05,
                "Sun at spring equinox should be ~0°, got \(lon)°")
    }

    @Test func summerSolstice2000() {
        // Summer solstice 2000: ~June 21 → JDE ≈ 2451716.5
        // The Sun should be near 90°
        let lon = MeeusSun.apparentLongitude(jde: 2451716.5)
        #expect(abs(lon - 90) < 1.0,
                "Sun at summer solstice should be ~90°, got \(lon)°")
    }

    @Test func fullYearMonotonic() {
        // Solar longitude should increase monotonically over a year
        // (when accounting for 360° wrapping)
        var prevLon = MeeusSun.apparentLongitude(jde: 2451545.0)
        for day in 1...365 {
            let jde = 2451545.0 + Double(day)
            let lon = MeeusSun.apparentLongitude(jde: jde)
            var diff = lon - prevLon
            if diff < -180 { diff += 360 } // Handle 360° → 0° wrap
            #expect(diff > 0, "Longitude should increase: day \(day), prev=\(prevLon), cur=\(lon)")
            prevLon = lon
        }
    }

    @Test func normalize() {
        #expect(MeeusSun.normalize(0) == 0)
        #expect(MeeusSun.normalize(360) == 0)
        #expect(MeeusSun.normalize(361) == 1)
        #expect(abs(MeeusSun.normalize(-1) - 359) < 1e-10)
        #expect(abs(MeeusSun.normalize(-360) - 0) < 1e-10)
        #expect(abs(MeeusSun.normalize(720) - 0) < 1e-10)
    }

    @Test func annualMotion() {
        // Sun should travel ~360° in one year
        let lon1 = MeeusSun.apparentLongitude(jde: 2451545.0)
        let lon2 = MeeusSun.apparentLongitude(jde: 2451545.0 + 365.25)
        var diff = lon2 - lon1
        if diff < -180 { diff += 360 }
        if diff > 180 { diff -= 360 }
        // Should be close to 0° (full circle back)
        #expect(abs(diff) < 1.0,
                "After one year, longitude should return near start: diff=\(diff)°")
    }
}

// MARK: - MeeusMoon

@Suite("MeeusMoon")
struct MeeusMoonTests {

    @Test func longitudeAtJ2000Reasonable() {
        // Moon longitude changes rapidly; validate broad physically reasonable range.
        let lon = MeeusMoon.apparentLongitude(jde: 2_451_545.0)
        #expect(lon >= 0 && lon < 360)
        #expect(lon > 200 && lon < 250, "Moon longitude at J2000 should be around 223°, got \(lon)")
    }

    @Test func longitudeChangesDaily() {
        let lon1 = MeeusMoon.apparentLongitude(jde: 2_451_545.0)
        let lon2 = MeeusMoon.apparentLongitude(jde: 2_451_546.0)
        var diff = lon2 - lon1
        if diff < -180 { diff += 360 }
        if diff > 180 { diff -= 360 }
        // Moon advances about 12-15° per day.
        #expect(diff > 8 && diff < 17, "Daily lunar longitude motion expected ~13°, got \(diff)")
    }

    @Test func normalize() {
        #expect(MeeusMoon.normalize(0) == 0)
        #expect(MeeusMoon.normalize(360) == 0)
        #expect(MeeusMoon.normalize(-1) == 359)
        #expect(MeeusMoon.normalize(721) == 1)
    }
}

// MARK: - MoonPhase

@Suite("MoonPhase")
struct MoonPhaseTests {

    @Test func k0NearKnownEpoch() {
        // Meeus reference epoch: near 2000-01-06 new moon.
        let jde = MoonPhase.newMoonJDE(k: 0)
        #expect(abs(jde - 2_451_550.1) < 0.3, "k=0 new moon should be near 2451550.1, got \(jde)")
    }

    @Test func consecutiveNewMoonSpacing() {
        let nm0 = MoonPhase.newMoonJDE(k: 0)
        let nm1 = MoonPhase.newMoonJDE(k: 1)
        let interval = nm1 - nm0
        // Synodic month varies ~29.27 to ~29.83 days.
        #expect(interval > 29.2 && interval < 29.9, "Unexpected lunation interval \(interval)")
    }

    @Test func searchBeforeAndAfter() {
        let probe = 2_461_000.0
        let before = MoonPhase.newMoonBefore(jde: probe)
        let after = MoonPhase.newMoonOnOrAfter(jde: probe)
        #expect(before < probe)
        #expect(after >= probe)
        #expect(after - before < 30.0)
    }

    @Test func phaseNearNewMoon() {
        let jde = MoonPhase.newMoonJDE(k: 50)
        let sunLon = MeeusSun.apparentLongitude(jde: jde)
        let moonLon = MeeusMoon.apparentLongitude(jde: jde)
        var diff = moonLon - sunLon
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        // With truncated lunar series this should still stay within a tight phase error.
        #expect(abs(diff) < 1.0, "New moon phase mismatch: \(diff)°")
    }
}

// MARK: - LunarCalendarComputer

@Suite("LunarCalendarComputer")
struct LunarCalendarComputerTests {

    @Test func year2025Shape() throws {
        let raw = try #require(LunarCalendarComputer.computeLunarYear(year: 2025))
        let expectedCNY = try #require(SolarDate(year: 2025, month: 1, day: 29))
        #expect(raw.year == 2025)
        #expect(raw.chineseNewYear == expectedCNY)
        #expect(raw.months.count == 12 || raw.months.count == 13)
        for month in raw.months {
            #expect(month.dayCount == 29 || month.dayCount == 30)
            #expect((1...12).contains(month.month))
        }
    }

    @Test func monthSequenceIsValid() throws {
        let raw = try #require(LunarCalendarComputer.computeLunarYear(year: 2025))
        for i in 1..<raw.months.count {
            let prev = raw.months[i - 1]
            let cur = raw.months[i]
            if cur.isLeapMonth {
                #expect(cur.month == prev.month)
            } else {
                #expect(cur.month == (prev.month % 12) + 1)
            }
            #expect(prev.startDate < cur.startDate)
        }
    }

    @Test func yearsInSupportedRange() {
        for year in 1900...2100 {
            let raw = LunarCalendarComputer.computeLunarYear(year: year)
            #expect(raw != nil, "Failed to compute lunar year \(year)")
        }
    }

    @Test func knownLeapYears() throws {
        let y2020 = try #require(LunarCalendarComputer.computeLunarYear(year: 2020))
        let y2023 = try #require(LunarCalendarComputer.computeLunarYear(year: 2023))
        let y2025 = try #require(LunarCalendarComputer.computeLunarYear(year: 2025))

        #expect(y2020.leapMonth == 4)
        #expect(y2023.leapMonth == 2)
        #expect(y2025.leapMonth == 6)
    }

    @Test func knownNonLeapYear2024() throws {
        let y2024 = try #require(LunarCalendarComputer.computeLunarYear(year: 2024))
        let expectedCNY = try #require(SolarDate(year: 2024, month: 2, day: 10))
        #expect(y2024.leapMonth == nil)
        #expect(y2024.months.count == 12)
        #expect(y2024.chineseNewYear == expectedCNY)
    }

    @Test func knownBoundaryCNYYears() throws {
        let y1985 = try #require(LunarCalendarComputer.computeLunarYear(year: 1985))
        let y2015 = try #require(LunarCalendarComputer.computeLunarYear(year: 2015))
        #expect(y1985.chineseNewYear == SolarDate(year: 1985, month: 2, day: 20))
        #expect(y2015.chineseNewYear == SolarDate(year: 2015, month: 2, day: 19))
    }
}

// MARK: - SolarTermCalc

@Suite("SolarTermCalc")
struct SolarTermCalcTests {

    // User-specified verification dates
    @Test func chunFen2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .chunFen, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 3)
        #expect(date.day == 20, "春分 2025 should be March 20, got \(date.day)")
    }

    @Test func qingMing2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .qingMing, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 4)
        #expect(date.day == 4, "清明 2025 should be April 4, got \(date.day)")
    }

    // Well-known solstice/equinox dates
    @Test func dongZhi2024() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .dongZhi, year: 2024))
        #expect(date.year == 2024)
        #expect(date.month == 12)
        #expect(date.day == 21, "冬至 2024 should be Dec 21, got \(date.day)")
    }

    @Test func xiaZhi2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .xiaZhi, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 6)
        #expect(date.day == 21, "夏至 2025 should be June 21, got \(date.day)")
    }

    @Test func xiaoHan2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .xiaoHan, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 1)
        #expect(date.day == 5, "小寒 2025 should be Jan 5, got \(date.day)")
    }

    @Test func liChun2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .liChun, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 2)
        #expect(date.day == 3, "立春 2025 should be Feb 3, got \(date.day)")
    }

    // Cross-year test: dongZhi is in December of the requested year
    @Test func dongZhi2025() throws {
        let date = try #require(SolarTermCalc.solarTermDate(term: .dongZhi, year: 2025))
        #expect(date.year == 2025)
        #expect(date.month == 12)
        // dongZhi 2025 should be Dec 21 or 22
        #expect(date.day == 21 || date.day == 22,
                "冬至 2025 should be Dec 21-22, got \(date.day)")
    }

    // All 24 terms should produce valid dates in the correct year
    @Test func allTerms2025ReturnValidDates() {
        for term in SolarTerm.allCases {
            let date = SolarTermCalc.solarTermDate(term: term, year: 2025)
            #expect(date != nil, "\(term) 2025 returned nil")
            if let date {
                #expect(date.year == 2025,
                        "\(term) 2025 returned year \(date.year)")
            }
        }
    }

    // Solar terms should be in chronological order within a year
    @Test func termsChronologicalOrder() throws {
        var dates: [SolarDate] = []
        for term in SolarTerm.allCases {
            let date = try #require(SolarTermCalc.solarTermDate(term: term, year: 2025))
            dates.append(date)
        }
        // SolarTerm.allCases starts with xiaoHan (Jan) and ends with dongZhi (Dec)
        // They should be in ascending date order
        for i in 1..<dates.count {
            #expect(dates[i - 1] < dates[i],
                    "Term \(i-1) (\(dates[i-1])) should be before term \(i) (\(dates[i]))")
        }
    }

    // Terms should be roughly 15 days apart
    @Test func termSpacing() throws {
        var jdes: [Double] = []
        for term in SolarTerm.allCases {
            let jde = SolarTermCalc.solarTermJDE(
                targetLongitude: term.solarLongitude, year: 2025)
            jdes.append(jde)
        }
        for i in 1..<jdes.count {
            let spacing = jdes[i] - jdes[i - 1]
            // Spacing varies from ~14.7 to ~16.5 days
            #expect(spacing > 13 && spacing < 18,
                    "Spacing between terms \(i-1) and \(i) = \(spacing) days")
        }
    }

    // Multi-year stability: spring equinox always falls on March 19-21
    @Test func chunFenDateRange() {
        for year in 2000...2050 {
            let date = SolarTermCalc.solarTermDate(term: .chunFen, year: year)
            #expect(date != nil)
            if let date {
                #expect(date.month == 3, "春分 \(year): month=\(date.month)")
                #expect(date.day >= 19 && date.day <= 21,
                        "春分 \(year): day=\(date.day)")
            }
        }
    }

    // Newton-Raphson convergence: verify the JDE solution is accurate
    @Test func convergencePrecision() {
        let targetLon = 15.0 // 清明
        let jde = SolarTermCalc.solarTermJDE(targetLongitude: targetLon, year: 2025)
        let actualLon = MeeusSun.apparentLongitude(jde: jde)
        var diff = targetLon - actualLon
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        #expect(abs(diff) < 0.000001,
                "Convergence error: \(diff)° for target \(targetLon)°")
    }

    @Test func allTermsYearRange1900To2100() {
        for year in 1900...2100 {
            for term in SolarTerm.allCases {
                let date = SolarTermCalc.solarTermDate(term: term, year: year)
                #expect(date != nil, "\(term) \(year) is nil")
                if let date {
                    #expect(date.year == year, "\(term) \(year) returned \(date.year)")
                }
            }
        }
    }

    @Test func chronologicalOrder1900To2100() {
        for year in 1900...2100 {
            var previous: SolarDate? = nil
            for term in SolarTerm.allCases {
                guard let current = SolarTermCalc.solarTermDate(term: term, year: year) else {
                    Issue.record("Missing date for \(term) in \(year)")
                    continue
                }
                if let previous {
                    #expect(previous < current, "\(term) order mismatch in \(year)")
                }
                previous = current
            }
        }
    }
}
