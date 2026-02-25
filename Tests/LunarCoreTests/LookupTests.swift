import Testing

@testable import LunarCore

// MARK: - UInt32 Encode/Decode Round-Trip

@Suite("LunarYearData")
struct LunarYearDataTests {

    @Test("table has 201 entries for 1900-2100")
    func tableSize() {
        #expect(LunarYearData.table.count == 201)
        #expect(LunarYearData.startYear == 1900)
        #expect(LunarYearData.endYear == 2100)
    }

    @Test("all entries have valid month day counts (29 or 30)")
    func validMonthDays() {
        for year in 1900...2100 {
            let info = LunarTableLookup.decode(year: year)
            #expect(info != nil, "decode failed for year \(year)")
            guard let info else { continue }
            for (i, d) in info.monthDays.enumerated() {
                #expect(d == 29 || d == 30, "year \(year) month \(i+1) has \(d) days")
            }
            if info.leapMonth > 0 {
                #expect(info.leapMonthDays == 29 || info.leapMonthDays == 30,
                        "year \(year) leap month has \(info.leapMonthDays) days")
            }
        }
    }

    @Test("CNY dates stay in legal window (Jan 21 - Feb 20)")
    func cnyMonths() {
        for year in 1900...2100 {
            guard let info = LunarTableLookup.decode(year: year) else { continue }
            #expect(info.cnyMonth == 1 || info.cnyMonth == 2,
                    "year \(year) CNY in month \(info.cnyMonth)")
            if info.cnyMonth == 1 {
                #expect((21...31).contains(info.cnyDay),
                        "year \(year) CNY day \(info.cnyDay) out of Jan range")
            } else {
                #expect((1...20).contains(info.cnyDay),
                        "year \(year) CNY day \(info.cnyDay) out of Feb range")
            }
        }
    }

    @Test("lunar year has valid day count")
    func yearDayRange() {
        for year in 1900...2100 {
            guard let info = LunarTableLookup.decode(year: year) else { continue }
            let total = LunarTableLookup.yearDayCount(info: info)
            if info.leapMonth > 0 {
                // Leap year: 383-385 days
                #expect(total >= 383 && total <= 385,
                        "leap year \(year) has \(total) days, expected 383-385")
            } else {
                // Non-leap year: 353-355 days
                #expect(total >= 353 && total <= 355,
                        "year \(year) has \(total) days, expected 353-355")
            }
        }
    }

    @Test("year day count equals next CNY interval")
    func cnyIntervalMatchesYearDayCount() {
        for year in 1900..<2100 {
            guard
                let info = LunarTableLookup.decode(year: year),
                let next = LunarTableLookup.decode(year: year + 1),
                let cny = SolarDate(year: year, month: info.cnyMonth, day: info.cnyDay),
                let nextCny = SolarDate(year: year + 1, month: next.cnyMonth, day: next.cnyDay)
            else {
                Issue.record("failed to decode/build CNY dates for year \(year)")
                continue
            }
            let interval = Int(
                (
                    JulianDay.fromGregorian(year: nextCny.year, month: nextCny.month, day: Double(nextCny.day))
                    - JulianDay.fromGregorian(year: cny.year, month: cny.month, day: Double(cny.day))
                ).rounded()
            )
            #expect(interval == LunarTableLookup.yearDayCount(info: info),
                    "year \(year) interval=\(interval) but yearDayCount=\(LunarTableLookup.yearDayCount(info: info))")
        }
    }

    @Test("round-trip: encode then decode matches LunarCalendarComputer")
    func roundTrip() {
        for year in [1900, 1950, 2000, 2020, 2023, 2025, 2033, 2050, 2100] {
            guard let raw = LunarCalendarComputer.computeLunarYear(year: year) else {
                Issue.record("computeLunarYear failed for \(year)")
                continue
            }
            guard let info = LunarTableLookup.decode(year: year) else {
                Issue.record("decode failed for \(year)")
                continue
            }

            // Verify CNY
            #expect(info.cnyMonth == raw.chineseNewYear.month, "year \(year) CNY month")
            #expect(info.cnyDay == raw.chineseNewYear.day, "year \(year) CNY day")

            // Verify leap month
            #expect(info.leapMonth == (raw.leapMonth ?? 0), "year \(year) leap month")

            // Verify regular month day counts
            let regularMonths = raw.months.filter { !$0.isLeapMonth }
            for (i, m) in regularMonths.enumerated() where i < 12 {
                #expect(info.monthDays[i] == m.dayCount,
                        "year \(year) month \(i+1): got \(info.monthDays[i]), expected \(m.dayCount)")
            }

            // Verify leap month day count
            if let leapRaw = raw.months.first(where: { $0.isLeapMonth }) {
                #expect(info.leapMonthDays == leapRaw.dayCount, "year \(year) leap month days")
            }
        }
    }
}

// MARK: - Known Year Spot-Checks

@Suite("LunarTableLookup - Known Years")
struct KnownYearTests {

    @Test("2020: CNY=Jan 25, leap 4")
    func year2020() {
        let info = LunarTableLookup.decode(year: 2020)!
        #expect(info.cnyMonth == 1)
        #expect(info.cnyDay == 25)
        #expect(info.leapMonth == 4)
    }

    @Test("2023: CNY=Jan 22, leap 2")
    func year2023() {
        let info = LunarTableLookup.decode(year: 2023)!
        #expect(info.cnyMonth == 1)
        #expect(info.cnyDay == 22)
        #expect(info.leapMonth == 2)
    }

    @Test("2024: CNY=Feb 10, no leap")
    func year2024() {
        let info = LunarTableLookup.decode(year: 2024)!
        #expect(info.cnyMonth == 2)
        #expect(info.cnyDay == 10)
        #expect(info.leapMonth == 0)
    }

    @Test("2025: CNY=Jan 29, leap 6")
    func year2025() {
        let info = LunarTableLookup.decode(year: 2025)!
        #expect(info.cnyMonth == 1)
        #expect(info.cnyDay == 29)
        #expect(info.leapMonth == 6)
    }

    @Test("2033: CNY=Jan 31, leap 11")
    func year2033() {
        let info = LunarTableLookup.decode(year: 2033)!
        #expect(info.cnyMonth == 1)
        #expect(info.cnyDay == 31)
        #expect(info.leapMonth == 11)
    }

    @Test("1985: CNY=Feb 20, leap 0")
    func year1985() {
        let info = LunarTableLookup.decode(year: 1985)!
        #expect(info.cnyMonth == 2)
        #expect(info.cnyDay == 20)
        #expect(info.leapMonth == 0)
    }

    @Test("2015: CNY=Feb 19, leap 0")
    func year2015() {
        let info = LunarTableLookup.decode(year: 2015)!
        #expect(info.cnyMonth == 2)
        #expect(info.cnyDay == 19)
        #expect(info.leapMonth == 0)
    }
}

// MARK: - Solar ↔ Lunar Conversion

@Suite("LunarTableLookup - Conversion")
struct ConversionTests {

    @Test("2025-01-29 (CNY) = Lunar 2025-1-1")
    func cny2025() {
        let solar = SolarDate(year: 2025, month: 1, day: 29)!
        let lunar = LunarTableLookup.solarToLunar(solar)
        #expect(lunar == LunarDate(year: 2025, month: 1, day: 1))
    }

    @Test("2024-02-10 (CNY) = Lunar 2024-1-1")
    func cny2024() {
        let solar = SolarDate(year: 2024, month: 2, day: 10)!
        let lunar = LunarTableLookup.solarToLunar(solar)
        #expect(lunar == LunarDate(year: 2024, month: 1, day: 1))
    }

    @Test("2025-01-28 = Lunar 2024-12-29")
    func dayBeforeCny2025() {
        let solar = SolarDate(year: 2025, month: 1, day: 28)!
        let lunar = LunarTableLookup.solarToLunar(solar)
        #expect(lunar != nil)
        #expect(lunar?.year == 2024)
        #expect(lunar?.month == 12)
    }

    @Test("2025 Mid-Autumn: Lunar 8/15 = 2025-10-06")
    func midAutumn2025() {
        let lunar = LunarDate(year: 2025, month: 8, day: 15)!
        let solar = LunarTableLookup.lunarToSolar(lunar)
        #expect(solar == SolarDate(year: 2025, month: 10, day: 6))
    }

    @Test("solar → lunar → solar round-trip")
    func roundTrip() {
        let dates: [SolarDate] = [
            SolarDate(year: 2000, month: 1, day: 1)!,
            SolarDate(year: 2020, month: 6, day: 15)!,
            SolarDate(year: 2024, month: 12, day: 31)!,
            SolarDate(year: 2025, month: 3, day: 15)!,
            SolarDate(year: 2025, month: 8, day: 20)!,
            SolarDate(year: 1900, month: 2, day: 1)!,
            SolarDate(year: 2100, month: 6, day: 1)!,
        ]
        for solar in dates {
            guard let lunar = LunarTableLookup.solarToLunar(solar) else {
                Issue.record("solarToLunar failed for \(solar)")
                continue
            }
            let back = LunarTableLookup.lunarToSolar(lunar)
            #expect(back == solar,
                    "round-trip failed: \(solar) → \(lunar) → \(String(describing: back))")
        }
    }

    @Test("lunar → solar → lunar round-trip")
    func reverseRoundTrip() {
        let dates: [LunarDate] = [
            LunarDate(year: 2025, month: 1, day: 1)!,
            LunarDate(year: 2025, month: 6, day: 15, isLeapMonth: true)!,
            LunarDate(year: 2023, month: 2, day: 10, isLeapMonth: true)!,
            LunarDate(year: 2020, month: 4, day: 1, isLeapMonth: true)!,
            LunarDate(year: 2024, month: 12, day: 15)!,
            LunarDate(year: 2000, month: 6, day: 20)!,
        ]
        for lunar in dates {
            guard let solar = LunarTableLookup.lunarToSolar(lunar) else {
                Issue.record("lunarToSolar failed for \(lunar)")
                continue
            }
            let back = LunarTableLookup.solarToLunar(solar)
            #expect(back == lunar,
                    "round-trip failed: \(lunar) → \(solar) → \(String(describing: back))")
        }
    }

    @Test("out-of-range years return nil")
    func outOfRange() {
        #expect(LunarTableLookup.decode(year: 1899) == nil)
        #expect(LunarTableLookup.decode(year: 2101) == nil)
    }

    @Test("month day count query")
    func monthDayCount() {
        let info = LunarTableLookup.decode(year: 2025)!
        // Regular month
        let m1 = LunarTableLookup.monthDayCount(info: info, month: 1, isLeap: false)
        #expect(m1 == 30 || m1 == 29)
        // Leap month 6
        let l6 = LunarTableLookup.monthDayCount(info: info, month: 6, isLeap: true)
        #expect(l6 == 29 || l6 == 30)
        // Non-existent leap month
        let l3 = LunarTableLookup.monthDayCount(info: info, month: 3, isLeap: true)
        #expect(l3 == nil)
    }

    @Test("invalid lunar day is rejected by lookup")
    func invalidLunarDayRejected() {
        let invalid = LunarDate(year: 2025, month: 2, day: 30)!
        #expect(LunarTableLookup.lunarToSolar(invalid) == nil)
    }
}
