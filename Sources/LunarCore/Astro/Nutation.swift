// Nutation in longitude (Δψ) — simplified formula
// Meeus Chapter 22, equations 22.1 & 22.2
// Accuracy: ~0.5" — sufficient for solar term calculations

import Foundation

enum Nutation: Sendable, Equatable, Hashable {

    // Input: T = Julian centuries from J2000.0
    //        T = (JDE - 2451545.0) / 36525
    // Output: Δψ (nutation in longitude) in degrees
    static func nutationInLongitude(T: Double) -> Double {
        // Longitude of ascending node of Moon's mean orbit (degrees)
        let omega = 125.04452 - 1934.136261 * T
        // Mean longitude of Sun (degrees)
        let Lsun = 280.4665 + 36000.7698 * T
        // Mean longitude of Moon (degrees)
        let Lmoon = 218.3165 + 481267.8813 * T

        let omegaRad = omega * .pi / 180
        let LsunRad = Lsun * .pi / 180
        let LmoonRad = Lmoon * .pi / 180

        // Δψ in arcseconds
        let deltaPsi = -17.20 * sin(omegaRad)
                       - 1.32 * sin(2 * LsunRad)
                       - 0.23 * sin(2 * LmoonRad)
                       + 0.21 * sin(2 * omegaRad)

        // Convert arcseconds → degrees
        return deltaPsi / 3600.0
    }

    // Input: T = Julian centuries from J2000.0
    // Output: Δε (nutation in obliquity) in degrees
    static func nutationInObliquity(T: Double) -> Double {
        let omega = 125.04452 - 1934.136261 * T
        let Lsun = 280.4665 + 36000.7698 * T
        let Lmoon = 218.3165 + 481267.8813 * T

        let omegaRad = omega * .pi / 180
        let LsunRad = Lsun * .pi / 180
        let LmoonRad = Lmoon * .pi / 180

        // Δε in arcseconds
        let deltaEpsilon = 9.20 * cos(omegaRad)
                         + 0.57 * cos(2 * LsunRad)
                         + 0.10 * cos(2 * LmoonRad)
                         - 0.09 * cos(2 * omegaRad)

        return deltaEpsilon / 3600.0
    }
}
