// New-moon calculation — Meeus Chapter 49
// Uses Meeus's mean lunation + correction series (new moon case).

import Foundation

enum MoonPhase: Sendable, Equatable, Hashable {

    // Mean new moon around lunation index k.
    // k = 0 corresponds to the new moon near 2000-01-06.
    static func meanNewMoonJDE(k: Double) -> Double {
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        return 2_451_550.09766
            + 29.530588861 * k
            + 0.00015437 * t2
            - 0.000000150 * t3
            + 0.00000000073 * t4
    }

    // Meeus Chapter 49 corrected new moon time (JDE, TT).
    static func newMoonJDE(k: Double) -> Double {
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let e = 1 - 0.002516 * t - 0.0000074 * t2

        let m = radians(
            2.5534
                + 29.10535669 * k
                - 0.0000218 * t2
                - 0.00000011 * t3
        )
        let mPrime = radians(
            201.5643
                + 385.81693528 * k
                + 0.0107438 * t2
                + 0.00001239 * t3
                - 0.000000058 * t4
        )
        let f = radians(
            160.7108
                + 390.67050284 * k
                - 0.0016341 * t2
                - 0.00000227 * t3
                + 0.000000011 * t4
        )
        let omega = radians(
            124.7746
                - 1.56375580 * k
                + 0.0020691 * t2
                + 0.00000215 * t3
        )

        var jde = meanNewMoonJDE(k: k)

        // Table 49.A (new moon)
        jde += -0.40720 * sin(mPrime)
        jde += 0.17241 * e * sin(m)
        jde += 0.01608 * sin(2 * mPrime)
        jde += 0.01039 * sin(2 * f)
        jde += 0.00739 * e * sin(mPrime - m)
        jde += -0.00514 * e * sin(mPrime + m)
        jde += 0.00208 * e * e * sin(2 * m)
        jde += -0.00111 * sin(mPrime - 2 * f)
        jde += -0.00057 * sin(mPrime + 2 * f)
        jde += 0.00056 * e * sin(2 * mPrime + m)
        jde += -0.00042 * sin(3 * mPrime)
        jde += 0.00042 * e * sin(m + 2 * f)
        jde += 0.00038 * e * sin(m - 2 * f)
        jde += -0.00024 * e * sin(2 * mPrime - m)
        jde += -0.00017 * sin(omega)
        jde += -0.00007 * sin(mPrime + 2 * m)
        jde += 0.00004 * sin(2 * mPrime - 2 * f)
        jde += 0.00004 * sin(3 * m)
        jde += 0.00003 * sin(mPrime + m - 2 * f)
        jde += 0.00003 * sin(2 * mPrime + 2 * f)
        jde += -0.00003 * sin(mPrime + m + 2 * f)
        jde += 0.00003 * sin(mPrime - m + 2 * f)
        jde += -0.00002 * sin(mPrime - m - 2 * f)
        jde += -0.00002 * sin(3 * mPrime + m)
        jde += 0.00002 * sin(4 * mPrime)

        // Table 49.C additional periodic terms
        let a1 = radians(299.77 + 0.107408 * k - 0.009173 * t2)
        let a2 = radians(251.88 + 0.016321 * k)
        let a3 = radians(251.83 + 26.651886 * k)
        let a4 = radians(349.42 + 36.412478 * k)
        let a5 = radians(84.66 + 18.206239 * k)
        let a6 = radians(141.74 + 53.303771 * k)
        let a7 = radians(207.14 + 2.453732 * k)
        let a8 = radians(154.84 + 7.306860 * k)
        let a9 = radians(34.52 + 27.261239 * k)
        let a10 = radians(207.19 + 0.121824 * k)
        let a11 = radians(291.34 + 1.844379 * k)
        let a12 = radians(161.72 + 24.198154 * k)
        let a13 = radians(239.56 + 25.513099 * k)
        let a14 = radians(331.55 + 3.592518 * k)

        jde += 0.000325 * sin(a1)
        jde += 0.000165 * sin(a2)
        jde += 0.000164 * sin(a3)
        jde += 0.000126 * sin(a4)
        jde += 0.000110 * sin(a5)
        jde += 0.000062 * sin(a6)
        jde += 0.000060 * sin(a7)
        jde += 0.000056 * sin(a8)
        jde += 0.000047 * sin(a9)
        jde += 0.000042 * sin(a10)
        jde += 0.000040 * sin(a11)
        jde += 0.000037 * sin(a12)
        jde += 0.000035 * sin(a13)
        jde += 0.000023 * sin(a14)

        return jde
    }

    // Approximate lunation index near the provided JDE.
    static func lunationNumber(for jde: Double) -> Double {
        (jde - 2_451_550.09766) / 29.530588861
    }

    // Finds the new moon at or before the provided JDE.
    static func newMoonOnOrBefore(jde: Double) -> Double {
        var k = floor(lunationNumber(for: jde))
        var nm = newMoonJDE(k: k)

        while nm > jde {
            k -= 1
            nm = newMoonJDE(k: k)
        }
        while true {
            let next = newMoonJDE(k: k + 1)
            if next > jde {
                break
            }
            k += 1
            nm = next
        }
        return nm
    }

    // Finds the first new moon at or after the provided JDE.
    static func newMoonOnOrAfter(jde: Double) -> Double {
        var k = floor(lunationNumber(for: jde))
        var nm = newMoonJDE(k: k)

        while nm < jde {
            k += 1
            nm = newMoonJDE(k: k)
        }
        while true {
            let prev = newMoonJDE(k: k - 1)
            if prev < jde {
                break
            }
            k -= 1
            nm = prev
        }
        return nm
    }

    // Finds the first new moon strictly before the provided JDE.
    static func newMoonBefore(jde: Double) -> Double {
        let nm = newMoonOnOrBefore(jde: jde)
        if abs(nm - jde) < 1e-9 {
            return newMoonJDE(k: floor(lunationNumber(for: nm)) - 1)
        }
        return nm
    }

    // Finds the new moon strictly before a Beijing calendar day.
    static func newMoonBefore(solarDate: SolarDate) -> Double {
        let jde = solarDateToJDE(solarDate)
        return newMoonBefore(jde: jde)
    }

    // Finds the new moon at or after a Beijing calendar day.
    static func newMoonOnOrAfter(solarDate: SolarDate) -> Double {
        let jde = solarDateToJDE(solarDate)
        return newMoonOnOrAfter(jde: jde)
    }

    // Convert a Beijing-time SolarDate (midnight) to JDE (TT).
    // Beijing midnight → UT → TT by adding ΔT.
    private static func solarDateToJDE(_ date: SolarDate) -> Double {
        let jdBeijing = JulianDay.fromGregorian(
            year: date.year, month: date.month, day: Double(date.day))
        let jdUT = jdBeijing - 8.0 / 24.0
        let decimalYear = 2000.0 + (jdUT - 2_451_545.0) / 365.25
        return jdUT + DeltaT.deltaT(year: decimalYear) / 86400.0
    }

    private static func radians(_ degrees: Double) -> Double {
        let normalized = degrees.truncatingRemainder(dividingBy: 360.0)
        return normalized * .pi / 180.0
    }
}
