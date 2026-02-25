# 🌙 LunarCore

> **A high-precision Chinese lunar calendar library in pure Swift, covering 1900–2100.**
> **纯 Swift 实现的高精度中国农历计算库，覆盖 1900–2100 年。**

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/babywbx/LunarCore-Swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**LunarCore** computes Chinese lunar calendar dates from astronomical first principles. It implements Meeus-based solar/lunar position algorithms, follows the [GB/T 33661-2017](https://openstd.samr.gov.cn/) national standard for lunar calendar compilation, and packs 201 years of lunar data into just ~800 bytes.

**LunarCore** 从天文算法第一性原理出发计算中国农历。自主实现基于 Jean Meeus 的日月位置算法，遵循 [GB/T 33661-2017](https://openstd.samr.gov.cn/) 国家标准，201 年农历数据仅占约 800 字节。

---

## ✨ Features / 特点

| | Feature | Description |
|-|---------|-------------|
| 📅 | **Solar ↔ Lunar Conversion** | Bidirectional conversion for 1900–2100 (201 years) / 公历 ↔ 农历双向转换 |
| 🌿 | **24 Solar Terms** | Real-time computation via Newton-Raphson iteration / 牛顿迭代法实时计算二十四节气 |
| 🐉 | **GanZhi (干支)** | Year, month, and day Heavenly Stems & Earthly Branches / 年月日天干地支 |
| 🐍 | **Chinese Zodiac (生肖)** | 12 zodiac animals with Chinese, English, and emoji / 十二生肖（中英文 + emoji） |
| 🎂 | **Lunar Birthdays** | Next occurrence with leap month & big/small month fallback / 农历生日计算（含闰月降级） |
| 📝 | **Formatter** | Chinese `正月初一` and English `1st Month, Day 1` / 中英文格式化 |
| 📦 | **~800 Bytes Data** | Compact `UInt32` encoding for 201 lunar years / 201 年数据仅 ~800 字节 |
| 🧵 | **Thread-safe** | Full `Sendable` conformance, safe for concurrent use / 全面遵循 `Sendable` |
| 🚫 | **Zero Dependencies** | Pure Swift, no third-party libraries / 纯 Swift，零外部依赖 |
| ✅ | **Verified Accuracy** | Validated against HKO data & Apple Foundation Calendar / 经香港天文台数据双重验证 |

---

## 📦 Installation / 安装

### Swift Package Manager

Add to your `Package.swift` / 在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/babywbx/LunarCore-Swift.git", from: "1.0.0"),
]
```

Then add `LunarCore` as a target dependency / 然后在 target 中添加依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: ["LunarCore"]
),
```

Or in Xcode: **File → Add Package Dependencies…** → paste the URL above.

或在 Xcode 中：**文件 → 添加包依赖…** → 粘贴上方 URL。

---

## 🚀 Usage / 使用

```swift
import LunarCore

let calendar = LunarCalendar.shared
let fmt = LunarFormatter(locale: .chinese)
```

### 📅 Solar → Lunar / 公历转农历

```swift
let lunar = calendar.lunarDate(from: SolarDate(year: 2025, month: 1, day: 29)!)!
print(fmt.string(from: lunar))                 // "二〇二五年正月初一"
print(fmt.string(from: lunar, useGanZhi: true)) // "乙巳年正月初一"
```

### 📅 Lunar → Solar / 农历转公历

```swift
let mid = calendar.solarDate(from: LunarDate(year: 2025, month: 8, day: 15)!)!
print(mid)  // 2025-10-06 (Mid-Autumn Festival / 中秋节)
```

### 🌿 Solar Terms / 节气

```swift
let qm = calendar.solarTermDate(.qingMing, in: 2025)!
print(qm)  // 2025-04-04 (Qingming / 清明)

// All 24 solar terms in a year / 某年全部 24 个节气
let terms = calendar.solarTerms(in: 2025)
for (term, date) in terms {
    print("\(term.chineseName) → \(date)")
}

// Check if a specific date is a solar term / 查询某天是否为节气
if let term = calendar.solarTerm(on: SolarDate(year: 2025, month: 4, day: 4)!) {
    print(term.chineseName)  // "清明"
}
```

### 🐉 GanZhi & Zodiac / 干支与生肖

```swift
print(calendar.yearGanZhi(for: 2025).chinese)   // "乙巳"
print(calendar.zodiac(for: 2025).emoji)          // "🐍"
print(calendar.zodiac(for: 2025).chinese)        // "蛇"

// Day and month GanZhi / 日干支与月干支
let today = SolarDate(year: 2025, month: 6, day: 15)!
print(calendar.dayGanZhi(for: today).chinese)    // "壬午"
print(calendar.monthGanZhi(for: today).chinese)  // "壬午"
```

### 🎂 Lunar Birthdays / 农历生日

```swift
// Next 10 occurrences of lunar August 15 (Mid-Autumn)
// 未来 10 年的农历八月十五（中秋）
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

### 🔄 Leap Month Fallback / 闰月降级

```swift
// Birthday is leap April 15, but 2026 has no leap April
// 生日是闰四月十五，但 2026 年没有闰四月
// → automatically falls back to regular April 15
// → 自动降级到普通四月十五
let next = calendar.nextLunarBirthday(month: 4, day: 15, isLeapMonth: true)!
```

### ℹ️ Year Info / 年份信息

```swift
// Leap month in a year / 某年的闰月
if let leap = calendar.leapMonth(in: 2025) {
    print("2025 年闰 \(leap) 月")  // "2025 年闰 6 月"
}

// Days in a lunar month / 某农历月天数
let days = calendar.daysInMonth(1, isLeap: false, year: 2025)!
print(days)  // 29 or 30

// Lunar New Year (Spring Festival) date / 春节（正月初一）日期
let cny = calendar.lunarNewYear(in: 2025)!
print(cny)  // 2025-01-29
```

### 🕐 Foundation.Date Interop / Foundation.Date 互操作

```swift
// Default timezone: Asia/Shanghai (UTC+8)
// 默认时区：Asia/Shanghai（UTC+8）
let today = calendar.lunarDate(from: Date())!
print(fmt.shortString(from: today))  // e.g. "二月初四"
```

---

## 🎯 Accuracy / 精度

| | Item | Target | Status |
|-|------|--------|--------|
| 🌑 | New moon date / 朔日 | 1929–present: zero deviation from official data | ✅ |
| 🌿 | 24 solar terms / 节气 | 1929–present: zero deviation from official data | ✅ |
| 🌙 | Leap month / 闰月 | 1900–2100: 100% accurate | ✅ |
| 📏 | Month size (29/30) / 月大小 | 1900–2100: 100% accurate | ✅ |
| 🐉 | GanZhi & Zodiac / 干支生肖 | 100% accurate (pure mathematical cycles) | ✅ |

### 🧪 Test Coverage / 测试覆盖

| Metric | Value |
|--------|-------|
| Test functions / 测试函数 | **231** |
| Parameterized test cases / 参数化用例 | **~2,366** |
| Line coverage / 行覆盖率 | **94.49%** |

Validation sources / 验证来源：

- ✅ **Hong Kong Observatory (HKO)** — 1,096 daily matches across 2024–2026, 100% accuracy / 香港天文台 1096 天逐日验证
- ✅ **Apple `Calendar(.chinese)`** — cross-validated 2000–2030, 100% match / Apple 系统日历交叉验证
- ✅ **15 boundary cases** — leap month 11, near-midnight solar terms, edge years, etc. / 15 个边界案例全覆盖

---

## 🏗️ Architecture / 架构

```
┌──────────────────────────────────────────────────┐
│              LunarCore Public API                 │
│     LunarCalendar · LunarFormatter · Models      │
├─────────────────────┬────────────────────────────┤
│  📂 Lookup Table    │  ⚡ Astronomical Engine     │
│  (~800 bytes)       │  (runtime computation)     │
│                     │                            │
│  Lunar year data:   │  Solar terms:              │
│  new moons, leap    │  Newton-Raphson on solar   │
│  months, month      │  longitude, converges in   │
│  sizes, CNY date    │  3–5 iterations            │
│  → O(1) query       │  → < 0.1ms per term        │
├─────────────────────┴────────────────────────────┤
│        Astronomical Algorithms (Meeus)            │
│  🌞 Solar longitude → solar terms (runtime)       │
│  🌙 Lunar longitude + new moons → table (build)   │
│  📐 GB/T 33661 rules → month naming & leap month  │
└──────────────────────────────────────────────────┘
```

**Design principle: compute what's cheap, store what's expensive.**
**设计原则：能算的不存，必须存的才存。**

- 📂 **Lunar year data → lookup table**: New moon computation involves lunar longitude iteration + GB/T 33661 leap month rules. Pre-computed at build time, O(1) at runtime (~800 bytes for 201 years).
- ⚡ **Solar terms → real-time**: Solar longitude is a simple trigonometric series. Newton-Raphson converges in 3–5 iterations, < 0.1ms per term. No need to store ~9.4 KB of pre-computed data.

---

## 🗂️ API Overview / API 概览

| Type | Description | 说明 |
|------|-------------|------|
| `LunarCalendar` | Main entry point — conversion, solar terms, GanZhi, zodiac, birthdays | 主入口 — 转换、节气、干支、生肖、生日 |
| `SolarDate` | Gregorian date value type with `Comparable` | 公历日期值类型 |
| `LunarDate` | Lunar date value type with leap month flag | 农历日期值类型（含闰月标志） |
| `LunarFormatter` | Chinese and English date formatting | 中英文日期格式化 |
| `SolarTerm` | 24 solar terms enum with longitude and names | 二十四节气枚举 |
| `GanZhi` | Sexagenary cycle (Heavenly Stems + Earthly Branches) | 六十甲子（天干地支） |
| `TianGan` | 10 Heavenly Stems | 十天干 |
| `DiZhi` | 12 Earthly Branches | 十二地支 |
| `ChineseZodiac` | 12 zodiac animals with emoji | 十二生肖 |

---

## 📋 Supported Range / 支持范围

| | Item | Range |
|-|------|-------|
| 📆 | Solar dates / 公历日期 | 1900-01-31 — 2100-12-31 |
| 🌙 | Lunar years / 农历年 | 1900 — 2100 (201 years / 201 年) |
| 🖥️ | Platforms / 平台 | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift version | 6.2+ |

---

## 🔬 Algorithm References / 算法参考

| Source | Usage |
|--------|-------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | Solar/lunar position, new moon computation, solar term formulas |
| **VSOP87** (Bretagnon & Francou, 1988) | Truncated solar longitude series |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | Truncated lunar longitude series |
| **GB/T 33661-2017** 《农历的编算和颁行》 | Chinese lunar calendar compilation rules / 农历编排国家标准 |
| **Hong Kong Observatory Open Data** | Validation dataset (government public data) / 验证数据集 |

---

## 📄 License / 许可

[MIT License](LICENSE) © 2025 [Babywbx](https://github.com/babywbx)
