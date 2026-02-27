// Solar term date calculation — Newton-Raphson iteration
// Solves: solarApparentLongitude(jde) = targetLongitude
// Conversion chain: JDE (TT) → subtract ΔT → UT → add 8h → UTC+8 date

enum SolarTermCalc: Sendable, Equatable, Hashable {

    // Calculate JDE when the Sun reaches a specific longitude.
    // Input: target longitude (degrees), calendar year
    // Output: JDE (Julian Ephemeris Day in TT)
    static func solarTermJDE(targetLongitude: Double, year: Int) -> Double {
        var jde = initialEstimate(targetLongitude: targetLongitude, year: year)

        // Newton-Raphson iteration (converges in 3-5 steps typically)
        for _ in 0..<50 {
            let currentLon = MeeusSun.apparentLongitude(jde: jde)
            var diff = targetLongitude - currentLon

            // Shortest path around the circle
            if diff > 180 { diff -= 360 }
            if diff < -180 { diff += 360 }

            if abs(diff) < 0.0000001 { break }

            // Sun moves ~360°/365.25 per day
            jde += diff / 360.0 * 365.25
        }

        return jde
    }

    // Calculate the Beijing-time (UTC+8) calendar date of a solar term.
    // Input: solar term, calendar year
    // Output: SolarDate in UTC+8
    static func solarTermDate(term: SolarTerm, year: Int) -> SolarDate? {
        let jde = solarTermJDE(targetLongitude: term.solarLongitude, year: year)

        // Decimal year from JDE for ΔT lookup
        let decimalYear = 2000.0 + (jde - 2451545.0) / 365.25
        let dt = DeltaT.deltaT(year: decimalYear)

        // JDE (TT) → JD (UT)
        let jdUT = jde - dt / 86400.0

        // UT → UTC+8 (Beijing time)
        let jdBeijing = jdUT + 8.0 / 24.0

        // JD → calendar date
        let (y, m, d) = JulianDay.toGregorian(jd: jdBeijing)
        return SolarDate(uncheckedYear: y, month: m, day: Int(d))
    }

    // Initial JDE estimate based on average solar motion.
    // The Sun is near 280° on January 1, so terms ≥ 280° fall before the equinox.
    private static func initialEstimate(targetLongitude: Double, year: Int) -> Double {
        // Approximate JDE of March equinox (0° longitude) for this year
        let equinoxJDE = 2451623.81 + 365.2422 * Double(year - 2000)

        if targetLongitude >= 280 {
            // Terms before equinox (xiaoHan 285° through jingZhe 345°, Jan–Mar)
            // Reference from previous year's equinox
            let prevEquinoxJDE = equinoxJDE - 365.2422
            return prevEquinoxJDE + targetLongitude / 360.0 * 365.2422
        } else {
            // Terms at/after equinox (chunFen 0° through dongZhi 270°, Mar–Dec)
            return equinoxJDE + targetLongitude / 360.0 * 365.2422
        }
    }
}
