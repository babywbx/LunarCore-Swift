// ΔT = TT - UT (seconds)
// Segmented polynomials for 1900-2100.
// Source: Espenak & Meeus (2006), NASA "Five Millennium Canon of Solar Eclipses"

enum DeltaT: Sendable, Equatable, Hashable {

    // Input: decimal year (e.g. 2025.5 = mid-2025)
    // Output: ΔT in seconds
    static func deltaT(year: Double) -> Double {
        let t: Double

        if year < 1900 {
            // Before supported range — parabolic extrapolation
            let u = (year - 1820) / 100
            return -20 + 32 * u * u
        } else if year < 1920 {
            t = year - 1900
            return polynomial(t, -2.79, 1.494119, -0.0598939, 0.0061966, -0.000197)
        } else if year < 1941 {
            t = year - 1920
            return polynomial(t, 21.20, 0.84493, -0.076100, 0.0020936)
        } else if year < 1961 {
            t = year - 1950
            return polynomial(t, 29.07, 0.407, -1.0 / 233, 1.0 / 2547)
        } else if year < 1986 {
            t = year - 1975
            return polynomial(t, 45.45, 1.067, -1.0 / 260, -1.0 / 718)
        } else if year < 2005 {
            t = year - 2000
            return polynomial(t, 63.86, 0.3345, -0.060374, 0.0017275,
                              0.000651814, 0.00002373599)
        } else if year < 2050 {
            t = year - 2000
            return polynomial(t, 62.92, 0.32217, 0.005589)
        } else if year <= 2150 {
            let u = (year - 1820) / 100
            return -20 + 32 * u * u - 0.5628 * (2150 - year)
        } else {
            // After supported range — parabolic extrapolation
            let u = (year - 1820) / 100
            return -20 + 32 * u * u
        }
    }

    // Horner's method: polynomial(x, a0, a1, a2, ...) = a0 + a1*x + a2*x² + ...
    private static func polynomial(_ x: Double, _ coeffs: Double...) -> Double {
        var result = 0.0
        for coeff in coeffs.reversed() {
            result = result * x + coeff
        }
        return result
    }
}
