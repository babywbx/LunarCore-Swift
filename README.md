# 🌙 LunarCore

> **纯 Swift 实现的高精度中国农历计算库，覆盖 1900–2100 年。**

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://github.com/babywbx/LunarCore-Swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.en.md)

**LunarCore** 从天文算法第一性原理出发计算中国农历。自主实现基于 Jean Meeus 的日月位置算法，遵循 [GB/T 33661-2017](https://openstd.samr.gov.cn/) 国家标准，201 年农历数据仅占约 800 字节。

---

## ✨ 特点

| | 功能 | 说明 |
|-|------|------|
| 📅 | **公历 ↔ 农历转换** | 1900–2100（201 年）双向转换 |
| 🌿 | **二十四节气** | 牛顿迭代法实时计算 |
| 🐉 | **干支** | 年、月、日天干地支 |
| 🐍 | **生肖** | 十二生肖（中英文 + emoji） |
| 🎂 | **农历生日** | 含闰月降级逻辑 |
| 📝 | **格式化** | 中文 `正月初一`、英文 `1st Month, Day 1` |
| 📦 | **~800 字节数据** | `UInt32` 紧凑编码 201 年农历数据 |
| 🧵 | **线程安全** | 全面遵循 `Sendable` |
| 🚫 | **零依赖** | 纯 Swift，无第三方库 |
| ✅ | **精度验证** | 经香港天文台数据 + Apple 系统日历双重验证 |

---

## 📦 安装

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/babywbx/LunarCore-Swift.git", from: "1.1.1"),
]
```

然后在 target 中添加依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: ["LunarCore"]
),
```

或在 Xcode 中：**文件 → 添加包依赖…** → 粘贴上方 URL。

---

## 🚀 使用

```swift
import LunarCore

let calendar = LunarCalendar.shared
let fmt = LunarFormatter(locale: .chinese)
```

### 📅 公历转农历

```swift
let lunar = calendar.lunarDate(from: SolarDate(year: 2025, month: 1, day: 29)!)!
print(fmt.string(from: lunar))                 // "二〇二五年正月初一"
print(fmt.string(from: lunar, useGanZhi: true)) // "乙巳年正月初一"
```

### 📅 农历转公历

```swift
let mid = calendar.solarDate(from: LunarDate(year: 2025, month: 8, day: 15)!)!
print(mid)  // 2025-10-06（中秋节）
```

### 🌿 节气

```swift
let qm = calendar.solarTermDate(.qingMing, in: 2025)!
print(qm)  // 2025-04-04（清明）

// 某年全部 24 个节气
let terms = calendar.solarTerms(in: 2025)
for (term, date) in terms {
    print("\(term.chineseName) → \(date)")
}

// 查询某天是否为节气
if let term = calendar.solarTerm(on: SolarDate(year: 2025, month: 4, day: 4)!) {
    print(term.chineseName)  // "清明"
}
```

### 🐉 干支与生肖

```swift
print(calendar.yearGanZhi(for: 2025).chinese)   // "乙巳"
print(calendar.zodiac(for: 2025).emoji)          // "🐍"
print(calendar.zodiac(for: 2025).chinese)        // "蛇"

// 日干支与月干支
let today = SolarDate(year: 2025, month: 6, day: 15)!
print(calendar.dayGanZhi(for: today).chinese)    // "壬午"
print(calendar.monthGanZhi(for: today).chinese)  // "壬午"
```

### 🎂 农历生日

```swift
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

### 🔄 闰月降级

```swift
// 生日是闰四月十五，但 2026 年没有闰四月
// → 自动降级到普通四月十五
let next = calendar.nextLunarBirthday(month: 4, day: 15, isLeapMonth: true)!
```

### ℹ️ 年份信息

```swift
// 某年的闰月
if let leap = calendar.leapMonth(in: 2025) {
    print("2025 年闰 \(leap) 月")  // "2025 年闰 6 月"
}

// 某农历月天数
let days = calendar.daysInMonth(1, isLeap: false, year: 2025)!
print(days)  // 29 或 30

// 某农历年总天数
let total = calendar.daysInYear(2025)!
print(total)  // 384（有闰月的年份较长）

// 春节（正月初一）日期
let cny = calendar.lunarNewYear(in: 2025)!
print(cny)  // 2025-01-29

// 支持的年份范围
print(calendar.supportedYearRange)  // 1900...2100
```

### 🕐 Foundation.Date 互操作

```swift
// 默认时区：Asia/Shanghai（UTC+8）
let today = calendar.lunarDate(from: Date())!
print(fmt.shortString(from: today))  // 如 "二月初四"

// SolarDate ↔ Foundation.Date
let date = SolarDate(year: 2025, month: 6, day: 15)!
let foundationDate = date.toDate(in: TimeZone(identifier: "Asia/Shanghai")!)!
let back = SolarDate.from(foundationDate, in: TimeZone(identifier: "Asia/Shanghai")!)!
```

### 📝 格式化

```swift
let fmt = LunarFormatter(locale: .chinese)

// 完整日期
fmt.string(from: lunar)                  // "二〇二五年正月初一"
fmt.string(from: lunar, useGanZhi: true) // "乙巳年正月初一"

// 简短日期（不含年）
fmt.shortString(from: lunar)             // "正月初一"

// 单独获取月名、日名
fmt.monthName(6, isLeap: true)           // "闰六月"
fmt.dayName(15)                          // "十五"

// 数字年转中文
fmt.chineseYear(2025)                    // "二〇二五"
```

---

## 🎯 精度

| | 项目 | 目标 | 状态 |
|-|------|------|------|
| 🌑 | 朔日 | 1929 至今：与官方数据零偏差 | ✅ |
| 🌿 | 节气 | 1929 至今：与官方数据零偏差 | ✅ |
| 🌙 | 闰月 | 1900–2100：100% 准确 | ✅ |
| 📏 | 月大小 | 1900–2100：100% 准确 | ✅ |
| 🐉 | 干支生肖 | 100% 准确（纯数学周期） | ✅ |

### 🧪 测试覆盖

| 指标 | 数值 |
|------|------|
| 测试函数 | **243** |
| 参数化用例 | **~2,888** |
| 行覆盖率 | **94.49%** |

验证来源：

- ✅ **香港天文台 (HKO)** — 2023–2027 共 1,826 天逐日验证，100% 准确
- ✅ **Apple `Calendar(.chinese)`** — 2000–2030 交叉验证，100% 一致
- ✅ **15 个边界案例** — 闰十一月、午夜附近节气、边界年份等

---

## 🗂️ API 概览

| 类型 | 说明 |
|------|------|
| `LunarCalendar` | 主入口 — 转换、节气、干支、生肖、生日 |
| `SolarDate` | 公历日期值类型 |
| `LunarDate` | 农历日期值类型（含闰月标志） |
| `LunarFormatter` | 中英文日期格式化 |
| `SolarTerm` | 二十四节气枚举 |
| `GanZhi` | 六十甲子（天干地支） |
| `TianGan` | 十天干 |
| `DiZhi` | 十二地支 |
| `ChineseZodiac` | 十二生肖 |

---

## 📋 支持范围

| | 项目 | 范围 |
|-|------|------|
| 📆 | 公历日期 | 1900-01-31 — 2100-12-31 |
| 🌙 | 农历年 | 1900 — 2100（201 年） |
| 🖥️ | 平台 | iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+ |
| 🔧 | Swift | 6.2+ |

---

## 🔬 算法参考

| 来源 | 用途 |
|------|------|
| **Jean Meeus, _Astronomical Algorithms_ (2nd Ed, 1998)** | 日月位置、朔望计算、节气公式 |
| **VSOP87** (Bretagnon & Francou, 1988) | 截断太阳黄经级数 |
| **ELP-2000/82** (Chapront-Touzé & Chapront, 1983) | 截断月球黄经级数 |
| **GB/T 33661-2017** 《农历的编算和颁行》 | 农历编排国家标准 |
| **香港天文台公开数据** | 验证数据集 |

---

## 📄 许可

[MIT License](LICENSE) © 2026 [Babywbx](https://github.com/babywbx)
