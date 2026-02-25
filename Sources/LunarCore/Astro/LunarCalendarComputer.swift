// Lunar year compilation based on GB/T 33661 core rules:
// 1) Month containing winter solstice is month 11.
// 2) If a lunation cycle between two month-11 anchors has 13 months,
//    the first month without a zhongqi is leap.

import Foundation

struct LunarMonthRaw: Sendable, Equatable, Hashable {
    let month: Int
    let isLeapMonth: Bool
    let dayCount: Int
    let startJDE: Double
    let startDate: SolarDate
}

struct LunarYearRaw: Sendable, Equatable, Hashable {
    let year: Int
    let leapMonth: Int?
    let chineseNewYear: SolarDate
    let months: [LunarMonthRaw]
}

enum LunarCalendarComputer: Sendable, Equatable, Hashable {

    // Computes lunar-year layout for a given lunar year number.
    // The returned months start from 正月 and end at 腊月 (plus optional leap month).
    static func computeLunarYear(year: Int) -> LunarYearRaw? {
        guard
            let cnyStart = chineseNewYearStartJDE(forGregorianYear: year),
            let nextCnyStart = chineseNewYearStartJDE(forGregorianYear: year + 1),
            cnyStart < nextCnyStart
        else {
            return nil
        }

        var monthStarts: [Double] = [cnyStart]
        while true {
            let next = MoonPhase.newMoonOnOrAfter(jde: monthStarts[monthStarts.count - 1] + 1.0)
            if next >= nextCnyStart - 1e-9 {
                break
            }
            monthStarts.append(next)
        }
        monthStarts.append(nextCnyStart)

        let monthCount = monthStarts.count - 1
        let zhongQi = zhongQiBetween(startJDE: cnyStart, endJDE: nextCnyStart)

        var leapIndex: Int? = nil
        if monthCount == 13 {
            for i in 1..<monthCount {
                if !hasZhongQi(startJDE: monthStarts[i], endJDE: monthStarts[i + 1], zhongQi: zhongQi) {
                    leapIndex = i
                    break
                }
            }
        }

        var months: [LunarMonthRaw] = []
        var previousMonthNumber = 1

        for i in 0..<monthCount {
            let isLeap = leapIndex == i
            let monthNumber: Int
            if i == 0 {
                monthNumber = 1
            } else if isLeap {
                monthNumber = previousMonthNumber
            } else {
                monthNumber = previousMonthNumber % 12 + 1
            }

            let dayCount = Int((monthStarts[i + 1] - monthStarts[i]).rounded())
            guard let startDate = solarDateFromJDEInBeijing(monthStarts[i]) else {
                return nil
            }
            let monthRaw = LunarMonthRaw(
                month: monthNumber,
                isLeapMonth: isLeap,
                dayCount: dayCount,
                startJDE: monthStarts[i],
                startDate: startDate
            )
            months.append(monthRaw)
            previousMonthNumber = monthNumber
        }

        guard let cnyDate = months.first?.startDate else {
            return nil
        }
        let leapMonthNumber = leapIndex.flatMap { idx in months[idx].month }

        return LunarYearRaw(
            year: year,
            leapMonth: leapMonthNumber,
            chineseNewYear: cnyDate,
            months: months
        )
    }

    // The first non-leap month-1 in the cycle between two winter solstices.
    private static func chineseNewYearStartJDE(forGregorianYear year: Int) -> Double? {
        guard let cycle = solsticeCycle(forGregorianYear: year) else {
            return nil
        }
        return cycle.months.first { $0.month == 1 && !$0.isLeapMonth }?.startJDE
    }

    private static func solsticeCycle(forGregorianYear year: Int) -> (months: [LunarMonthRaw], m11Start: Double, nextM11Start: Double)? {
        let wsPrev = SolarTermCalc.solarTermJDE(targetLongitude: SolarTerm.dongZhi.solarLongitude, year: year - 1)
        let wsCurr = SolarTermCalc.solarTermJDE(targetLongitude: SolarTerm.dongZhi.solarLongitude, year: year)

        let m11Start = MoonPhase.newMoonOnOrBefore(jde: wsPrev)
        let nextM11Start = MoonPhase.newMoonOnOrBefore(jde: wsCurr)
        guard m11Start < nextM11Start else {
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

            let dayCount = Int((starts[i + 1] - starts[i]).rounded())
            guard let startDate = solarDateFromJDEInBeijing(starts[i]) else {
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

    private static func solarDateFromJDEInBeijing(_ jde: Double) -> SolarDate? {
        let decimalYear = 2000.0 + (jde - 2_451_545.0) / 365.25
        let jdUT = jde - DeltaT.deltaT(year: decimalYear) / 86400.0
        let jdBeijing = jdUT + 8.0 / 24.0
        let (year, month, day) = JulianDay.toGregorian(jd: jdBeijing)
        return SolarDate(year: year, month: month, day: Int(day))
    }
}
