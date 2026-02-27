# 🌙 LunarCore

> **A high-precision Chinese lunar calendar library in pure Swift, covering 1900–2100.**

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/babywbx/LunarCore-Swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[中文](README.md)

**LunarCore** computes Chinese lunar calendar dates from astronomical first principles. It implements Meeus-based solar/lunar position algorithms, follows the [GB/T 33661-2017](https://openstd.samr.gov.cn/) national standard for lunar calendar compilation, and packs 201 years of lunar data into just ~800 bytes.

---

## ✨ Features

| | Feature | Description |
|-|---------|-------------|
| 📅 | **Solar ↔ Lunar Conversion** | Bidirectional conversion for 1900–2100 (201 years) |
| 🌿 | **24 Solar Terms** | Real-time computation via Newton-Raphson iteration |
| 🐉 | **GanZhi (干支)** | Year, month, and day Heavenly Stems & Earthly Branches |
| 🐍 | **Chinese Zodiac** | 12 zodiac animals with Chinese, English, and emoji |
| 🎂 | **Lunar Birthdays** | Next occurrence with leap month fallback |
| 📝 | **Formatter** | Chinese `正月初一` and English `1st Month, Day 1` |
| 📦 | **~800 Bytes Data** | Compact `UInt32` encoding for 201 lunar years |
| 🧵 | **Thread-safe** | Full `Sendable` conformance |
| 🚫 | **Zero Dependencies** | Pure Swift, no third-party libraries |
| ✅ | **Verified Accuracy** | Validated against HKO data & Apple Foundation Calendar |

---

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/babywbx/LunarCore-Swift.git", from: "1.1.1"),
]
```

Then add `LunarCore` as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: ["LunarCore"]
),
```

Or in Xcode: **File → Add Package Dependencies…** → paste the URL above.

---

## 🚀 Usage

```swift
import LunarCore

let calendar = LunarCalendar.shared
let fmt = LunarFormatter(locale: .chinese)
```

### 📅 Solar → Lunar

```swift
let lunar = calendar.lunarDate(from: SolarDate(year: 2025, month: 1, day: 29)!)!
print(fmt.string(from: lunar))                 // "二〇二五年正月初一"
print(fmt.string(from: lunar, useGanZhi: true)) // "乙巳年正月初一"
```

### 📅 Lunar → Solar

```swift
let mid = calendar.solarDate(from: LunarDate(year: 2025, month: 8, day: 15)!)!
print(mid)  // 2025-10-06 (Mid-Autumn Festival)
```

### 🌿 Solar Terms

```swift
let qm = calendar.solarTermDate(.qingMing, in: 2025)!
print(qm)  // 2025-04-04 (Qingming)

// All 24 solar terms in a year
let terms = calendar.solarTerms(in: 2025)
for (term, date) in terms {
    print("\(term.chineseName) → \(date)")
}

// Check if a specific date is a solar term
if let term = calendar.solarTerm(on: SolarDate(year: 2025, month: 4, day: 4)!) {
    print(term.chineseName)  // "清明"
}
```

### 🐉 GanZhi & Zodiac

```swift
print(calendar.yearGanZhi(for: 2025).chinese)   // "乙巳"
print(calendar.zodiac(for: 2025).emoji)          // "🐍"
print(calendar.zodiac(for: 2025).chinese)        // "蛇"

// Day and month GanZhi
let today = SolarDate(year: 2025, month: 6, day: 15)!
print(calendar.dayGanZhi(for: today).chinese)    // "壬午"
print(calendar.monthGanZhi(for: today).chinese)  // "壬午"
```

### 🎂 Lunar Birthdays

```swift
// Next 10 occurrences of lunar August 15 (Mid-Autumn)
let birthdays = calendar.lunarBirthdays(month: 8, day: 15, years: 10)
for date in birthdays {
    let l = calendar.lunarDate(from: date)!
    print("\(date) ← \(fmt.shortString(from: l))")
}
// 2025-10-06 ← 八月十五
// 2026-09-25 ← 八月十五
// 2027-10-15 ← 八月十五
// ...
```

### 🔄 Leap Month Fallback

```swift
// Birthday is leap April 15, but 2026 has no leap April
// → automatically falls back to regular April 15
let next = calendar.nextLunarBirthday(month: 4, day: 15, isLeapMonth: true)!
```

### ℹ️ Year Info

```swift
// Leap month in a year
if let leap = calendar.leapMonth(in: 2025) {
    print("Leap month \(leap) in 2025")  // "Leap month 6 in 2025"
}

// Days in a lunar month
let days = calendar.daysInMonth(1, isLeap: false, year: 2025)!
print(days)  // 29 or 30

// Total days in a lunar year
let total = calendar.daysInYear(2025)!
print(total)  // 384 (years with leap months are longer)

// Lunar New Year (Spring Festival) date
let cny = calendar.lunarNewYear(in: 2025)!
print(cny)  // 2025-01-29

// Supported year range
print(calendar.supportedYearRange)  // 1900...2100
```

### 🕐 Foundation.Date Interop

```swift
// Default timezone: Asia/Shanghai (UTC+8)
let today = calendar.lunarDate(from: Date())!
print(fmt.shortString(from: today))  // e.g. "二月初四"

// SolarDate ↔ Foundation.Date
let date = SolarDate(year: 2025, month: 6, day: 15)!
let foundationDate = date.toDate(in: TimeZone(identifier: "Asia/Shanghai")!)!
let back = SolarDate.from(foundationDate, in: TimeZone(identifier: "Asia/Shanghai")!)!
```

### 📝 Formatting

```swift
let fmt = LunarFormatter(locale: .chinese)

// Full date string
fmt.string(from: lunar)                  // "二〇二五年正月初一"
fmt.string(from: lunar, useGanZhi: true) // "乙巳年正月初一"

// Short date string (without year)
fmt.shortString(from: lunar)             // "正月初一"

// Individual month/day names
fmt.monthName(6, isLeap: true)           // "闰六月"
fmt.dayName(15)                          // "十五"

// Numeric year to Chinese digits
fmt.chineseYear(2025)                    // "二〇二五"
```

---

## 🎯 Accuracy

| | Item | Target | Status |
|-|------|--------|--------|
| 🌑 | New moon date | 1929–present: zero deviation from official data | ✅ |
| 🌿 | 24 solar terms | 1929–present: zero deviation from official data | ✅ |
| 🌙 | Leap month | 1900–2100: 100% accurate | ✅ |
| 📏 | Month size (29/30) | 1900–2100: 100% accurate | ✅ |
| 🐉 | GanZhi & Zodiac | 100% accurate (pure mathematical cycles) | ✅ |

### 🧪 Test Coverage

| Metric | Value |
|--------|-------|
| Test functions | **243** |
| Parameterized test cases | **~2,888** |
| Line coverage | **94.49%** |

Validation sources:

- ✅ **Hong Kong Observatory (HKO)** — 1,826 daily matches across 2023–2027, 100% accuracy
- ✅ **Apple `Calendar(.chinese)`** — cross-validated 2000–2030, 100% match
- ✅ **15 boundary cases** — leap month 11, near-midnight solar terms, edge years, etc.

---

## 🗂️ API Overview

| Type | Description |
|------|-------------|
| `LunarCalendar` | Main entry point — conversion, solar terms, GanZhi, zodiac, birthdays |
| `SolarDate` | Gregorian date value type with `Comparable` |
| `LunarDate` | Lunar date value type with leap month flag |
| `LunarFormatter` | Chinese and English date formatting |
| `SolarTerm` | 24 solar terms enum with longitude and names |
| `GanZhi` | Sexagenary cycle (Heavenly Stems + Earthly Branches) |
| `TianGan` | 10 Heavenly Stems |
| `DiZhi` | 12 Earthly Branches |
| `ChineseZodiac` | 12 zodiac animals with emoji |

---

## 📋 Supported Range

| | Item | Range |
|-|------|-------|
| 📆 | Solar dates | 1900-01-31 — 2100-12-31 |
| 🌙 | Lunar years | 1900 — 2100 (201 years) |
| 🖥️ | Platforms | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift version | 6.2+ |

---

## 🔬 Algorithm References

| Source | Usage |
|--------|-------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | Solar/lunar position, new moon computation, solar term formulas |
| **VSOP87** (Bretagnon & Francou, 1988) | Truncated solar longitude series |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | Truncated lunar longitude series |
| **GB/T 33661-2017** | Chinese lunar calendar compilation rules |
| **Hong Kong Observatory Open Data** | Validation dataset (government public data) |

---

## 📄 License

[MIT License](LICENSE) © 2026 [Babywbx](https://github.com/babywbx)
