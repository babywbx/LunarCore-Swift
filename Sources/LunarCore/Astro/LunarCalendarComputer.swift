// Lunar year compilation based on GB/T 33661 core rules:
// 1) Month containing winter solstice is month 11.
// 2) If a lunation cycle between two month-11 anchors has 13 months,
//    the first month without a zhongqi is leap.

import Foundation

package struct LunarMonthRaw: Sendable, Equatable, Hashable {
    package let month: Int
    package let isLeapMonth: Bool
    package let dayCount: Int
    package let startJDE: Double
    package let startDate: SolarDate
}

package struct LunarYearRaw: Sendable, Equatable, Hashable {
    package let year: Int
    package let leapMonth: Int?
    package let chineseNewYear: SolarDate
    package let months: [LunarMonthRaw]
}

package enum LunarCalendarComputer: Sendable, Equatable, Hashable {

    // Computes lunar-year layout for a given lunar year number.
    // The returned months start from 正月 and end at 腊月 (plus optional leap month).
    //
    // Assembles from two solstice cycles per GB/T 33661:
    //   Cycle A (WS year-1 → WS year): provides months 1-10
    //   Cycle B (WS year → WS year+1): provides months 11-12
    // Leap month is determined within each solstice cycle independently.
    package static func computeLunarYear(year: Int) -> LunarYearRaw? {
        guard
            let cycleA = solsticeCycle(forGregorianYear: year),
            let cycleB = solsticeCycle(forGregorianYear: year + 1)
        else {
            return nil
        }

        // Months 1-10 (with any leap) from cycle A
        var months: [LunarMonthRaw] = []
        for m in cycleA.months where m.month >= 1 && m.month <= 10 {
            months.append(m)
        }

        // Months 11-12 (with any leap) from cycle B
        for m in cycleB.months where m.month == 11 || m.month == 12 {
            months.append(m)
        }

        guard let cnyDate = months.first?.startDate else {
            return nil
        }
        let leapMonthNumber = months.first(where: { $0.isLeapMonth })?.month

        return LunarYearRaw(
            year: year,
            leapMonth: leapMonthNumber,
            chineseNewYear: cnyDate,
            months: months
        )
    }

    private static func solsticeCycle(forGregorianYear year: Int) -> (months: [LunarMonthRaw], m11Start: Double, nextM11Start: Double)? {
        let wsPrev = SolarTermCalc.solarTermJDE(targetLongitude: SolarTerm.dongZhi.solarLongitude, year: year - 1)
        let wsCurr = SolarTermCalc.solarTermJDE(targetLongitude: SolarTerm.dongZhi.solarLongitude, year: year)

        guard
            let m11Start = month11Start(forWinterSolstice: wsPrev),
            let nextM11Start = month11Start(forWinterSolstice: wsCurr),
            m11Start < nextM11Start
        else {
            return nil
        }

        var starts: [Double] = [m11Start]
        while starts[starts.count - 1] < nextM11Start - 1e-9 {
            let next = MoonPhase.newMoonOnOrAfter(jde: starts[starts.count - 1] + 1.0)
            starts.append(next)
            if starts.count > 20 { break }
        }
        guard starts.count >= 2, starts[starts.count - 1] >= nextM11Start - 1e-9 else {
            return nil
        }
        if starts[starts.count - 1] > nextM11Start + 1e-6 {
            starts[starts.count - 1] = nextM11Start
        }

        let monthCount = starts.count - 1
        let zhongQi = zhongQiBetween(startJDE: m11Start, endJDE: nextM11Start)

        var leapIndex: Int? = nil
        if monthCount == 13 {
            for i in 1..<monthCount {
                if !hasZhongQi(startJDE: starts[i], endJDE: starts[i + 1], zhongQi: zhongQi) {
                    leapIndex = i
                    break
                }
            }
        }

        var months: [LunarMonthRaw] = []
        for i in 0..<monthCount {
            let monthNumber: Int
            let isLeap = leapIndex == i
            if i == 0 {
                monthNumber = 11
            } else if isLeap {
                monthNumber = months[i - 1].month
            } else {
                monthNumber = months[i - 1].month % 12 + 1
            }

            guard
                let startDate = solarDateFromJDEInBeijing(starts[i]),
                let endDate = solarDateFromJDEInBeijing(starts[i + 1])
            else {
                return nil
            }
            let dayCount = solarDayDistance(from: startDate, to: endDate)
            guard dayCount == 29 || dayCount == 30 else {
                return nil
            }
            months.append(
                LunarMonthRaw(
                    month: monthNumber,
                    isLeapMonth: isLeap,
                    dayCount: dayCount,
                    startJDE: starts[i],
                    startDate: startDate
                )
            )
        }
        return (months, m11Start, nextM11Start)
    }

    // Month 11 anchor under date-level containment in UTC+8:
    // if winter solstice and a new moon share a date, solstice belongs to the later month.
    private static func month11Start(forWinterSolstice wsJDE: Double) -> Double? {
        let before = MoonPhase.newMoonOnOrBefore(jde: wsJDE)
        let after = MoonPhase.newMoonOnOrAfter(jde: wsJDE)
        guard
            let wsDate = solarDateFromJDEInBeijing(wsJDE),
            let afterDate = solarDateFromJDEInBeijing(after)
        else {
            return nil
        }
        if afterDate == wsDate {
            return after
        }
        return before
    }

    private static func zhongQiBetween(startJDE: Double, endJDE: Double) -> [Double] {
        guard
            let beijingStart = solarDateFromJDEInBeijing(startJDE),
            let beijingEnd = solarDateFromJDEInBeijing(endJDE)
        else {
            return []
        }
        let startYear = min(beijingStart.year, beijingEnd.year) - 1
        let endYear = max(beijingStart.year, beijingEnd.year) + 1

        var zhongQi: [Double] = []
        for year in startYear...endYear {
            for term in SolarTerm.allCases where term.isZhongQi {
                let jde = SolarTermCalc.solarTermJDE(targetLongitude: term.solarLongitude, year: year)
                if jde >= startJDE - 1e-9 && jde < endJDE - 1e-9 {
                    zhongQi.append(jde)
                }
            }
        }
        return zhongQi.sorted()
    }

    // Date-level containment in UTC+8:
    // [monthStartDate, nextMonthStartDate). If zhongqi and new moon share a date,
    // zhongqi belongs to the later month.
    private static func hasZhongQi(startJDE: Double, endJDE: Double, zhongQi: [Double]) -> Bool {
        guard
            let startDate = solarDateFromJDEInBeijing(startJDE),
            let endDate = solarDateFromJDEInBeijing(endJDE)
        else {
            return false
        }

        for zq in zhongQi {
            guard let zqDate = solarDateFromJDEInBeijing(zq) else {
                continue
            }
            if zqDate >= startDate && zqDate < endDate {
                return true
            }
        }
        return false
    }

    private static func solarDayDistance(from start: SolarDate, to end: SolarDate) -> Int {
        let startJD = JulianDay.fromGregorian(year: start.year, month: start.month, day: Double(start.day))
        let endJD = JulianDay.fromGregorian(year: end.year, month: end.month, day: Double(end.day))
        return Int((endJD - startJD).rounded())
    }

    private static func solarDateFromJDEInBeijing(_ jde: Double) -> SolarDate? {
        let decimalYear = 2000.0 + (jde - 2_451_545.0) / 365.25
        let jdUT = jde - DeltaT.deltaT(year: decimalYear) / 86400.0
        let jdBeijing = jdUT + 8.0 / 24.0
        let (year, month, day) = JulianDay.toGregorian(jd: jdBeijing)
        return SolarDate(uncheckedYear: year, month: month, day: Int(day))
    }
}
