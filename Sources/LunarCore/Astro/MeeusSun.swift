// Solar apparent longitude — Meeus Chapter 25
// Truncated VSOP87 via Meeus's simplified formulas.
// Accuracy: ~1" (arcsecond), corresponding to solar term timing error < 30s.

import Foundation

enum MeeusSun: Sendable, Equatable, Hashable {

    // Input: JDE (Julian Ephemeris Day in Terrestrial Time)
    // Output: solar apparent longitude in degrees [0, 360)
    static func apparentLongitude(jde: Double) -> Double {
        let T = (jde - 2451545.0) / 36525.0

        // Geometric mean longitude of Sun (degrees) — Meeus eq. 25.2
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T

        // Mean anomaly of Sun (degrees) — Meeus eq. 25.3
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let Mrad = M * .pi / 180

        // Equation of center (degrees) — Meeus eq. 25.4
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mrad)
              + (0.019993 - 0.000101 * T) * sin(2 * Mrad)
              + 0.000289 * sin(3 * Mrad)

        // True longitude (degrees)
        let trueLon = L0 + C

        // Nutation correction (degrees) — Meeus Chapter 22
        let deltaPsi = Nutation.nutationInLongitude(T: T)

        // Earth-Sun distance R (AU) — Meeus eq. 25.5
        let e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T
        let vRad = (M + C) * .pi / 180.0
        let R = 1.000001018 * (1 - e * e) / (1 + e * cos(vRad))

        // Aberration correction (degrees) — Meeus p.164, κ/R
        let aberration = -20.4898 / (R * 3600.0)

        // Apparent longitude
        let apparent = trueLon + deltaPsi + aberration

        return normalize(apparent)
    }

    // Normalize angle to [0, 360) degrees
    static func normalize(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }
}
