// Lunar apparent longitude — truncated Meeus Chapter 47 series
// This is a practical truncation focused on new-moon and month-layout accuracy.

import Foundation

enum MeeusMoon: Sendable, Equatable, Hashable {

    // Input: JDE (Julian Ephemeris Day in Terrestrial Time)
    // Output: lunar apparent longitude in degrees [0, 360)
    static func apparentLongitude(jde: Double) -> Double {
        let t = (jde - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        let lPrime = normalize(
            218.3164477
                + 481267.88123421 * t
                - 0.0015786 * t2
                + t3 / 538841.0
                - t4 / 65_194_000.0
        )
        let d = normalize(
            297.8501921
                + 445267.1114034 * t
                - 0.0018819 * t2
                + t3 / 545868.0
                - t4 / 113_065_000.0
        )
        let m = normalize(
            357.5291092
                + 35999.0502909 * t
                - 0.0001536 * t2
                + t3 / 24_490_000.0
        )
        let mPrime = normalize(
            134.9633964
                + 477198.8675055 * t
                + 0.0087414 * t2
                + t3 / 69_699.0
                - t4 / 14_712_000.0
        )
        let f = normalize(
            93.2720950
                + 483202.0175233 * t
                - 0.0036539 * t2
                - t3 / 3_526_000.0
                + t4 / 863_310_000.0
        )
        let e = 1.0 - 0.002516 * t - 0.0000074 * t2

        let dRad = radians(d)
        let mRad = radians(m)
        let mPrimeRad = radians(mPrime)
        let fRad = radians(f)

        var longitude = lPrime
        longitude += 6.289 * sin(mPrimeRad)
        longitude += 1.274 * sin(2 * dRad - mPrimeRad)
        longitude += 0.658 * sin(2 * dRad)
        longitude += 0.214 * sin(2 * mPrimeRad)
        longitude -= 0.186 * e * sin(mRad)
        longitude -= 0.114 * sin(2 * fRad)
        longitude += 0.059 * sin(2 * dRad - 2 * mPrimeRad)
        longitude += 0.057 * e * sin(2 * dRad - mRad - mPrimeRad)
        longitude += 0.053 * sin(2 * dRad + mPrimeRad)
        longitude += 0.046 * e * sin(2 * dRad - mRad)
        longitude += 0.041 * e * sin(mRad - mPrimeRad)
        longitude -= 0.035 * sin(dRad)
        longitude -= 0.031 * e * sin(mRad + mPrimeRad)
        longitude -= 0.015 * sin(2 * fRad - 2 * dRad)
        longitude += 0.011 * sin(mPrimeRad - 4 * dRad)
        longitude -= 0.009 * sin(2 * fRad - mPrimeRad)
        longitude -= 0.008 * e * sin(2 * dRad + mRad - mPrimeRad)
        longitude += 0.007 * e * sin(2 * dRad + mRad)
        longitude -= 0.007 * e * sin(mRad - 2 * mPrimeRad)
        longitude -= 0.006 * e * sin(2 * dRad + mPrimeRad - mRad)
        longitude += 0.005 * sin(dRad + mPrimeRad)
        longitude += 0.005 * e * sin(mRad + 2 * mPrimeRad)
        longitude += 0.004 * e * sin(2 * dRad - mRad + 2 * mPrimeRad)
        longitude += 0.004 * e * e * sin(2 * dRad - 2 * mRad - mPrimeRad)
        longitude += 0.003 * sin(2 * mPrimeRad - 2 * dRad)
        longitude += 0.003 * e * sin(dRad + mRad - mPrimeRad)
        longitude += 0.003 * sin(mPrimeRad + 2 * fRad)
        longitude += 0.002 * sin(2 * dRad + mPrimeRad - 2 * fRad)
        longitude += 0.002 * e * sin(2 * mPrimeRad + mRad)
        longitude += 0.002 * sin(2 * dRad - mPrimeRad - 2 * fRad)

        // Add nutation in longitude to convert true ecliptic longitude to apparent.
        longitude += Nutation.nutationInLongitude(T: t)

        return normalize(longitude)
    }

    static func normalize(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360.0)
        if result < 0 {
            result += 360.0
        }
        return result
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }
}
