# 🌙 LunarCore-Swift — 高精度农历计算 Swift 库

## 开发规格书 v2.0

> 一个干净、精准、零依赖的中国农历计算 Swift 库
> 从天文算法第一性原理出发，完全自主计算，无任何第三方代码或数据
> 协议：MIT · 平台：所有 Apple 平台 + Linux

---

## 1. 项目定位

### 1.1 核心原则

**完全自主**：从天文学公式出发，自己实现算法，自己生成数据。不引用、不依赖、不借鉴任何第三方库或个人项目的代码和数据。验证仅使用政府公开数据（香港天文台 Open Data）和 Apple 系统 API。

**零外部依赖**：纯 Swift，不 import 任何第三方包。Foundation 仅用于 Date 互转的便捷方法，核心逻辑完全自包含。

### 1.2 功能范围

**做：**

| 功能 | 说明 |
|------|------|
| 公历 ↔ 农历互转 | 1900-2100，精度对齐国家标准 |
| 闰月查询 | 某年有无闰月、闰几月、闰月大小 |
| 农历月大小 | 29天 / 30天 |
| 二十四节气 | 每年24个节气的精确公历日期 |
| 干支纪年/纪月/纪日 | 天干地支完整计算 |
| 生肖 | 十二生肖 |
| 中英文格式化 | 正月、腊月、初一、廿三 等标准写法 |
| 农历生日计算 | 下一个农历生日、未来N年批量查询 |

**不做：** 黄历宜忌、八字五行、星宿纳音、佛历道历、节日（属业务层）

---

## 2. 算法基础——我们用什么来计算？

### 2.1 理论来源（全部是公开发表的科学文献/标准）

| 来源 | 性质 | 用途 |
|------|------|------|
| **GB/T 33661-2017《农历的编算和颁行》** | 中国国家标准（公开） | 定义农历编排规则：朔日定义、节气定义、闰月规则、时间标准 |
| **Jean Meeus《Astronomical Algorithms》(2nd Ed, 1998)** | 天文学教科书（已出版图书） | 太阳/月球位置计算公式、朔望计算公式、节气计算方法 |
| **VSOP87 行星理论** | Bretagnon & Francou 1988，公开发表的天文学论文 | 太阳黄经的高精度计算（我们用截断版，教科书中有完整公式） |
| **ELP-2000/82 月球理论** | Chapront-Touzé & Chapront 1983，公开发表的天文学论文 | 月球黄经的高精度计算（我们用截断版） |
| **IAU 决议** | 国际天文学联合会公开决议 | 岁差章动模型、时间标准定义 |

说明：以上全部是已出版的教科书、公开发表的学术论文、或政府/国际组织的公开标准。我们实现的是**数学公式**，不是某个人的代码。就像你用勾股定理不需要标注毕达哥拉斯的版权一样。

### 2.2 验证来源（全部是政府公开数据）

| 来源 | 性质 | 用途 |
|------|------|------|
| **香港天文台 Open Data** | 香港特区政府公开数据集，免费使用 | 农历对照表 JSON API，用于对比验证 |
| **香港天文台年历 PDF** | 政府每年免费发布 | 节气日期 + 农历月信息，交叉验证 |
| **Apple Foundation Calendar(.chinese)** | 系统内置 API | 作为第三方独立验证参照 |

### 2.3 精度目标

| 项目 | 目标 |
|------|------|
| 朔日（农历初一）日期 | 1929年至今：与官方零偏差；1900-1928年：已修正历史时间标准差异 |
| 二十四节气日期 | 1929年至今：与官方零偏差 |
| 闰月判断 | 1900-2100：100% 正确 |
| 农历月大小 | 1900-2100：100% 正确 |
| 干支 / 生肖 | 100% 正确（纯数学周期） |

---

## 3. 农历核心规则（依据 GB/T 33661-2017）

这是国家标准中对农历编算的规定，是我们实现的法规依据：

### 3.1 时间标准

- 农历使用 **UTC+8**（东经120度标准时间，即北京时间）
- 所有天文事件（合朔、节气）的发生时刻以 UTC+8 判定日期归属
- 若合朔时刻恰好在 UTC+8 午夜 00:00:00，归入新一天

### 3.2 朔日（农历月的第一天）

- **朔** = 日月合朔，即太阳和月球的地心视黄经相等的时刻
- 合朔时刻所在的 UTC+8 日期即为该农历月的初一

### 3.3 二十四节气

- 以太阳地心视黄经定义，每 15° 一个节气
- 春分 = 0°, 清明 = 15°, 谷雨 = 30°, ..., 惊蛰 = 345°
- 节气分两类交替排列：
  - **节**（奇数序号）：立春(315°)、惊蛰(345°)、清明(15°)、立夏(45°)、芒种(75°)、小暑(105°)、立秋(135°)、白露(165°)、寒露(195°)、立冬(225°)、大雪(255°)、小寒(285°)
  - **中气**（偶数序号）：雨水(330°)、春分(0°)、谷雨(30°)、小满(60°)、夏至(90°)、大暑(120°)、处暑(150°)、秋分(180°)、霜降(210°)、小雪(240°)、冬至(270°)、大寒(300°)
- 中气用于确定农历月份归属和闰月判定

### 3.4 农历月份命名

- 包含**冬至**中气（太阳黄经270°）的月份固定为**十一月**
- 其余月份按照中气对应关系命名（雨水→正月、春分→二月、...）

### 3.5 闰月规则（无中气置闰法）

- 如果从一个含冬至的十一月到下一个含冬至的十一月之间有 **13 个农历月**，则需设置一个闰月
- 闰月 = 这段区间内**第一个不含中气的月份**
- 闰月名称 = 前一个月的名称加「闰」字
- 如果有多个不含中气的月份，只取第一个为闰月

### 3.6 大月与小月

- 两个相邻朔日之间相差 **30 天** → 大月
- 两个相邻朔日之间相差 **29 天** → 小月
- 完全由天文计算决定，无简单规律

---

## 4. 技术架构

### 4.1 整体设计

```
┌──────────────────────────────────────────────┐
│              LunarCore Public API             │
│   LunarDate · SolarTerm · GanZhi · ...       │
├──────────────────────────────────────────────┤
│    查表（~800 bytes）    │   实时计算（天文引擎）  │
│  农历年数据：朔日、闰月、 │  节气日期：按需计算，   │
│  月大小、正月初一日期    │  Newton-Raphson 3-5次  │
│  查询 O(1)              │  迭代，微秒级响应       │
├──────────────────────────────────────────────┤
│         天文算法引擎（Meeus 公式自主实现）        │
│  · 太阳黄经 → 节气（运行时实时计算）             │
│  · 月球黄经 + 朔望 → 生成查表数据（构建时）       │
│  · 扩展表外年份 + 单元测试验证                   │
└──────────────────────────────────────────────┘
```

**设计原则：能算的不存，必须存的才存**

- **农历年数据必须查表**：朔日计算涉及月球黄经迭代求根 + GB/T 33661 闰月编排规则，实时算需要连算十几个月的朔日再判定闰月，开销大且边界情况多。预计算后查表 O(1)，~800 bytes 极其紧凑。
- **节气不存表，实时算**：节气 = 求解太阳黄经到达目标角度的时刻。太阳黄经公式简单（几十个三角函数），Newton-Raphson 3-5 次收敛，单次计算 < 0.1ms。省掉 ~9.4 KB 数据，库更干净。

### 4.2 数据生产流程（完全自主）

```
天文算法引擎（我们自己写的 Swift 代码）
    │
    │  构建时：计算 1900-2100 年的所有朔日
    │  算法: Meeus 朔望公式 → 每月朔日时刻
    │        Meeus 太阳黄经 → 节气时刻（用于闰月判定）
    │        GB/T 33661 规则 → 农历月份编排 + 闰月
    │
    ▼
Swift 常量数组 — LunarYearData.swift（~800 bytes）
    │
    │  验证（不影响数据本身）
    │
    ├──→ 对比香港天文台 Open Data → 输出差异报告
    ├──→ 对比 Apple Calendar(.chinese) → 输出差异报告
    └──→ 人工审查已知边界案例

运行时：
  · 农历查询 → 查表（O(1)）
  · 节气查询 → 天文引擎实时计算（< 0.1ms）
```

### 4.3 查表数据编码

每个农历年用 1 个 UInt32 编码（4 bytes）：

```
Bit 布局（高位 → 低位）：

[31]      : 保留 (0)
[30-19]   : 12 bits — 正月到十二月的大小 (1=大月30天, 0=小月29天)
            bit 30 = 正月, bit 29 = 二月, ..., bit 19 = 十二月
[18-15]   : 4 bits  — 闰月月份 (0=无闰月, 1=闰正月, ..., 12=闰十二月)
[14]      : 1 bit   — 闰月大小 (1=30天, 0=29天)，无闰月时为 0
[13-9]    : 5 bits  — 正月初一的公历日期 (1-31)
[8]       : 1 bit   — 正月初一的公历月份 (0=1月, 1=2月)
[7-0]     : 8 bits  — 保留/校验

总计: 201 年 × 4 bytes = 804 bytes
```

**全部数据体积：约 800 bytes**。一张小图片都比这大。节气不存表，运行时实时计算。

---

## 5. 天文算法引擎详细设计

这是整个库的技术核心。全部基于 Jean Meeus《Astronomical Algorithms》中的公式实现。

### 5.1 儒略日 (Julian Day)

公历日期与连续天数之间的桥梁，所有天文计算的基础。

```swift
/// 公历 → 儒略日数 (JD)
/// 参考: Meeus, Chapter 7
/// 精度: 精确（纯整数/浮点运算，无近似）
func julianDay(year: Int, month: Int, day: Double) -> Double {
    var y = year
    var m = month
    if m <= 2 {
        y -= 1
        m += 12
    }
    let A = y / 100
    let B = 2 - A + A / 4  // 格里历修正（1582年10月15日之后）
    return Double(Int(365.25 * Double(y + 4716)))
         + Double(Int(30.6001 * Double(m + 1)))
         + day + Double(B) - 1524.5
}

/// 儒略日 → 公历
/// 参考: Meeus, Chapter 7
func calendarDate(jd: Double) -> (year: Int, month: Int, day: Double)
```

### 5.2 太阳黄经（截断 VSOP87）

用于计算二十四节气（节气 = 太阳到达特定黄经角度的时刻）。

```swift
/// 计算给定时刻的太阳地心视黄经
/// 参考: Meeus, Chapter 25 (Solar Coordinates)
/// 精度: ~1" (角秒)，对应节气时刻误差 < 30秒
///
/// 步骤:
/// 1. 计算儒略世纪数 T = (JDE - 2451545.0) / 36525
/// 2. 太阳几何平黄经 L0
/// 3. 太阳平近点角 M
/// 4. 太阳中心差方程 C (包含一次、二次、三次项)
/// 5. 太阳真黄经 = L0 + C
/// 6. 章动修正 Δψ
/// 7. 光行差修正 (约 -20.4")
/// 8. 视黄经 = 真黄经 + Δψ + 光行差
func solarApparentLongitude(jde: Double) -> Double
```

Meeus Chapter 25 中给出了完整的系数表，包括：
- 太阳平黄经 L0 = 280.46646° + 36000.76983°T + 0.0003032°T²
- 太阳平近点角 M = 357.52911° + 35999.05029°T - 0.0001537°T²
- 中心差方程 C（三项正弦级数）
- 章动 Δψ（简化公式，Meeus Chapter 22）

### 5.3 月球黄经（截断 ELP-2000/82）

用于计算合朔时刻（合朔 = 日月黄经相等）。

```swift
/// 计算给定时刻的月球地心视黄经
/// 参考: Meeus, Chapter 47 (Position of the Moon)
/// 精度: ~10" (角秒)，对应朔望时刻误差 < 数十秒
///
/// Meeus 给出了 60 个主要周期项的正弦级数，足够我们的精度需求。
/// 完整 ELP-2000/82 有 37862 项，但截断到 ~60 项已足够。
func lunarLongitude(jde: Double) -> Double
```

需要实现的月球参数：
- 月球平黄经 L'
- 月球平近点角 M'
- 月球平升交点黄经 F
- 月球到太阳平距角 D
- 太阳平近点角 M（与太阳计算共享）

### 5.4 朔望计算

```swift
/// 计算某次朔（新月）的精确时刻
/// 参考: Meeus, Chapter 49 (Phases of the Moon)
/// 精度: 平均误差 ~4秒，最大误差 ~17秒（对于日期判定绰绰有余）
///
/// Meeus 的朔望算法分两步:
/// 1. 先用近似公式估算朔的平均时刻 (基于朔望月平均长度)
/// 2. 再用 14 个修正项精确修正
///
/// 这比自己做 Newton-Raphson 迭代简单很多，精度也足够。
func newMoonJDE(k: Double) -> Double {
    // k 为朔望序号:
    // k = 0 对应 2000年1月6日的新月
    // k = 正整数 → 之后的新月
    // k = 负整数 → 之前的新月
    // k 必须是整数（新月）或整数+0.5（满月）
    
    let T = k / 1236.85  // 儒略世纪数
    
    // 平均朔时刻 (JDE)
    var jde = 2451550.09766 + 29.530588861 * k
                + 0.00015437 * T * T
                - 0.000000150 * T * T * T
                + 0.00000000073 * T * T * T * T
    
    // 计算 M, M', F, Ω 等参数
    // ...
    
    // 14 个修正项 (Meeus Table 49.A)
    // ...
    
    // 额外的行星修正项 (Meeus Table 49.C)
    // ...
    
    return jde
}

/// 查找包含指定公历日期的农历月的朔日
/// 从近似 k 值开始搜索
func findNewMoonBefore(solarDate: SolarDate) -> Double  // 返回 JDE
func findNewMoonOnOrAfter(solarDate: SolarDate) -> Double
```

### 5.5 节气计算

```swift
/// 计算某年某个节气的精确时刻
/// 参考: Meeus, Chapter 27 (Equinoxes and Solstices) + 扩展到所有节气
///
/// 方法:
/// 1. 先用近似公式估算节气的平均时刻
/// 2. 用 Newton-Raphson 迭代精确求解太阳黄经 = 目标角度的时刻
///    即求解: solarApparentLongitude(jde) = targetLongitude
func solarTermJDE(term: SolarTerm, year: Int) -> Double {
    let targetLongitude = term.solarLongitude  // 0°, 15°, 30°, ...
    
    // 初始估值（基于平均太阳运动）
    var jde = initialEstimate(term: term, year: year)
    
    // Newton-Raphson 迭代
    for _ in 0..<50 {
        let currentLon = solarApparentLongitude(jde: jde)
        var diff = targetLongitude - currentLon
        // 处理角度跨越 0°/360° 的情况
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        if abs(diff) < 0.0000001 { break }
        // 太阳每天移动约 360°/365.25 ≈ 0.9856°
        jde += diff / 360.0 * 365.25
    }
    
    return jde
}
```

### 5.6 ΔT（力学时与世界时之差）

天文算法计算出的是力学时 (TT/TDE)，需要转换为世界时 (UT) 才能判定 UTC+8 日期。

```swift
/// 估算 ΔT = TT - UT (秒)
/// 参考: Meeus Chapter 10 + Morrison & Stephenson 2004 的多项式拟合
/// 对于 1900-2100 年，各时段使用不同的多项式
func deltaT(year: Double) -> Double {
    // 1900-2100 分段多项式
    // 这些系数来自天文学公开文献中发布的经验拟合公式
    // ...
}
```

### 5.7 完整农历编排

把以上全部组件组合起来，按 GB/T 33661-2017 的规则编排农历：

```swift
/// 计算某一年的完整农历数据
/// 这是数据生成的核心函数
func computeLunarYear(year: Int) -> LunarYearRaw {
    // 1. 计算该年及前后年的所有朔日 (约 25-30 个)
    //    → 每个朔日 = 一个农历月的起始
    
    // 2. 计算该年及前后年的所有中气 (约 30 个)
    //    → 用于确定月份名称和闰月
    
    // 3. 确定冬至所在月 = 十一月（固定规则）
    
    // 4. 判断两个冬至之间是否有 13 个月
    //    → 是 → 需要置闰
    //    → 找到第一个无中气的月份 → 标记为闰月
    
    // 5. 为每个月命名（按中气对应关系）
    
    // 6. 计算每个月的天数 = 下一个朔日 - 当前朔日
    
    // 7. 返回结构化数据
}
```

---

## 6. 数据模型（Public API）

### 6.1 LunarDate

```swift
public struct LunarDate: Equatable, Hashable, Comparable, Sendable {
    public let year: Int            // 农历年（公历纪年，如 2025）
    public let month: Int           // 农历月（1-12）
    public let day: Int             // 农历日（1-30）
    public let isLeapMonth: Bool    // 是否闰月
}
```

### 6.2 SolarDate

```swift
public struct SolarDate: Equatable, Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int   // 1-12
    public let day: Int     // 1-31
    
    public func toDate(in timeZone: TimeZone) -> Date
    public static func from(_ date: Date, in timeZone: TimeZone) -> SolarDate
}
```

### 6.3 SolarTerm

```swift
public enum SolarTerm: Int, CaseIterable, Sendable {
    case xiaoHan = 0        // 小寒 285°
    case daHan              // 大寒 300°
    case liChun             // 立春 315°
    case yuShui             // 雨水 330°
    case jingZhe            // 惊蛰 345°
    case chunFen            // 春分 0°
    case qingMing           // 清明 15°
    case guYu               // 谷雨 30°
    case liXia              // 立夏 45°
    case xiaoMan            // 小满 60°
    case mangZhong          // 芒种 75°
    case xiaZhi             // 夏至 90°
    case xiaoShu            // 小暑 105°
    case daShu              // 大暑 120°
    case liQiu              // 立秋 135°
    case chuShu             // 处暑 150°
    case baiLu              // 白露 165°
    case qiuFen             // 秋分 180°
    case hanLu              // 寒露 195°
    case shuangJiang        // 霜降 210°
    case liDong             // 立冬 225°
    case xiaoXue            // 小雪 240°
    case daXue              // 大雪 255°
    case dongZhi            // 冬至 270°
    
    /// 对应的太阳黄经角度
    public var solarLongitude: Double
    
    /// 是否为中气
    public var isZhongQi: Bool
    
    /// 中文名
    public var chineseName: String
    
    /// 英文名
    public var englishName: String
}
```

### 6.4 GanZhi / TianGan / DiZhi

```swift
public enum TianGan: Int, CaseIterable, Sendable {
    case jia = 0, yi, bing, ding, wu, ji, geng, xin, ren, gui
    public var chinese: String   // 甲乙丙丁戊己庚辛壬癸
    public var pinyin: String
}

public enum DiZhi: Int, CaseIterable, Sendable {
    case zi = 0, chou, yin, mao, chen, si, wu, wei, shen, you, xu, hai
    public var chinese: String   // 子丑寅卯辰巳午未申酉戌亥
    public var pinyin: String
}

public struct GanZhi: Equatable, Hashable, Sendable {
    public let gan: TianGan
    public let zhi: DiZhi
    public var index: Int        // 六十甲子序号 (0-59)
    public var chinese: String   // 如 "甲子"
}
```

### 6.5 ChineseZodiac

```swift
public enum ChineseZodiac: Int, CaseIterable, Sendable {
    case rat = 0, ox, tiger, rabbit, dragon, snake,
         horse, goat, monkey, rooster, dog, pig
    
    public var chinese: String
    public var english: String
    public var emoji: String     // 🐀🐂🐅🐇🐉🐍🐎🐐🐒🐓🐕🐖
}
```

---

## 7. 核心 API

### 7.1 LunarCalendar — 主入口

```swift
public final class LunarCalendar: Sendable {
    
    public static let shared = LunarCalendar()
    
    // ── 转换 ──
    public func lunarDate(from solar: SolarDate) -> LunarDate?
    public func solarDate(from lunar: LunarDate) -> SolarDate?
    public func lunarDate(from date: Date,
                          in timeZone: TimeZone = .init(identifier: "Asia/Shanghai")!) -> LunarDate?
    
    // ── 农历年信息 ──
    public func leapMonth(in year: Int) -> Int?
    public func daysInMonth(_ month: Int, isLeap: Bool, year: Int) -> Int?
    public func daysInYear(_ year: Int) -> Int?
    public func lunarNewYear(in year: Int) -> SolarDate?
    
    // ── 节气（实时计算，内部自动缓存已查询年份） ──
    public func solarTerms(in year: Int) -> [(term: SolarTerm, date: SolarDate)]
    public func solarTermDate(_ term: SolarTerm, in year: Int) -> SolarDate?
    public func solarTerm(on date: SolarDate) -> SolarTerm?
    
    // ── 干支 ──
    public func yearGanZhi(for lunarYear: Int) -> GanZhi
    public func monthGanZhi(for solar: SolarDate) -> GanZhi
    public func dayGanZhi(for solar: SolarDate) -> GanZhi
    
    // ── 生肖 ──
    public func zodiac(for lunarYear: Int) -> ChineseZodiac
    
    // ── 生日便捷方法 ──
    /// 下一个农历生日（含闰月降级 + 大小月降级）
    public func nextLunarBirthday(month: Int, day: Int,
                                   isLeapMonth: Bool = false,
                                   after: SolarDate? = nil) -> SolarDate?
    
    /// 未来N年的农历生日列表
    public func lunarBirthdays(month: Int, day: Int,
                                isLeapMonth: Bool = false,
                                from: SolarDate? = nil,
                                years: Int = 10) -> [SolarDate]
    
    // ── 元数据 ──
    public var supportedYearRange: ClosedRange<Int> { 1900...2100 }
    public static let version = "1.0.0"
}
```

### 7.2 LunarFormatter

```swift
public struct LunarFormatter: Sendable {
    
    public enum Locale: Sendable { case chinese, english }
    public var locale: Locale
    
    public init(locale: Locale = .chinese)
    
    /// "正月" "腊月" "闰六月" / "1st Month" "Leap 6th Month"
    public func monthName(_ month: Int, isLeap: Bool = false) -> String
    
    /// "初一" "十五" "廿三" "三十" / "Day 1" "Day 15"
    public func dayName(_ day: Int) -> String
    
    /// "二〇二五年正月十五" 或 "乙巳年正月十五"
    public func string(from lunar: LunarDate, useGanZhi: Bool = false) -> String
    
    /// "正月十五"
    public func shortString(from lunar: LunarDate) -> String
    
    /// 2025 → "二〇二五"
    public func chineseYear(_ year: Int) -> String
}
```

---

## 8. 干支 / 生肖计算规则

### 8.1 干支纪年（以立春为界）

```
天干序号 = (年 - 4) % 10       → 0=甲, ..., 9=癸
地支序号 = (年 - 4) % 12       → 0=子, ..., 11=亥

例: 2025 → 天干=(2025-4)%10=1→乙  地支=(2025-4)%12=5→巳 → 乙巳年 ✓
```

### 8.2 干支纪月（以节为界，五虎遁元推天干）

```
月天干起始 = (年天干序号 % 5) × 2 + 2
月地支 = 寅(2)起，正月=寅，二月=卯，...
```

### 8.3 干支纪日（连续循环）

```
参考日: 2000年1月7日 = 甲子日
dayGanZhi = daysSince(2000, 1, 7) % 60
```

### 8.4 生肖（以正月初一为界）

```
生肖 = (农历年 - 4) % 12
0=鼠 1=牛 2=虎 3=兔 4=龙 5=蛇 6=马 7=羊 8=猴 9=鸡 10=狗 11=猪
```

---

## 9. 项目结构

```
LunarCore/
├── Package.swift
├── README.md                              # 中英双语
├── LICENSE                                # MIT
│
├── Sources/LunarCore/
│   ├── LunarCalendar.swift                # 主入口
│   ├── LunarFormatter.swift               # 格式化
│   │
│   ├── Models/
│   │   ├── LunarDate.swift
│   │   ├── SolarDate.swift
│   │   ├── SolarTerm.swift
│   │   ├── GanZhi.swift
│   │   ├── TianGan.swift
│   │   ├── DiZhi.swift
│   │   └── ChineseZodiac.swift
│   │
│   ├── Data/
│   │   └── LunarYearData.swift            # 自主计算生成的农历年数据（~800 bytes）
│   │
│   ├── Internal/
│   │   ├── LunarTableLookup.swift         # 查表法实现
│   │   ├── JulianDay.swift                # 儒略日
│   │   ├── DateHelper.swift               # 日期工具
│   │   └── Validator.swift                # 输入校验
│   │
│   └── Astro/                             # 天文算法引擎
│       ├── MeeusSun.swift                 # 太阳黄经
│       ├── MeeusMoon.swift                # 月球黄经
│       ├── MoonPhase.swift                # 朔望计算
│       ├── SolarTermCalc.swift            # 节气时刻计算
│       ├── Nutation.swift                 # 章动修正
│       ├── DeltaT.swift                   # ΔT 计算
│       └── LunarCalendarComputer.swift    # 完整农历编排
│
├── Tests/LunarCoreTests/
│   ├── ConversionTests.swift
│   ├── LeapMonthTests.swift
│   ├── SolarTermTests.swift
│   ├── GanZhiTests.swift
│   ├── ZodiacTests.swift
│   ├── FormatterTests.swift
│   ├── BirthdayTests.swift
│   ├── BoundaryTests.swift
│   ├── AstroEngineTests.swift             # 天文引擎自身精度测试
│   ├── CrossValidationTests.swift         # 对比 Apple Calendar(.chinese)
│   ├── HKOValidationTests.swift           # 对比香港天文台 Open Data
│   └── Fixtures/
│       └── hko_data.json                  # 从 HKO API 获取的政府公开数据
│
└── Scripts/                               # 不参与 SPM 编译
    ├── generate_data.swift                # 用天文引擎生成查表数据 → Swift 源码
    ├── fetch_hko.swift                    # 从香港天文台 API 拉取验证数据
    └── validate.swift                     # 交叉验证报告
```

---

## 10. 开发计划

### Phase 1: 骨架 + 模型（1 天）
- [ ] SPM 包结构
- [ ] 全部 public 数据类型（LunarDate, SolarDate, SolarTerm, GanZhi, ChineseZodiac）
- [ ] SolarDate ↔ Foundation.Date
- [ ] LunarFormatter（月名、日名、年份中文数字）
- [ ] 干支 + 生肖计算（纯数学，不依赖查表）

### Phase 2: 天文算法引擎（3-4 天）— 最核心
- [ ] JulianDay: 儒略日 ↔ 公历
- [ ] DeltaT: ΔT 多项式
- [ ] Nutation: 章动修正
- [ ] MeeusSun: 太阳视黄经（截断 VSOP87 系数，Meeus Chapter 25）
- [ ] MeeusMoon: 月球视黄经（截断 ELP-2000/82 系数，Meeus Chapter 47）
- [ ] MoonPhase: 朔望计算（Meeus Chapter 49 的 14 项修正）
- [ ] SolarTermCalc: 节气时刻（Newton-Raphson 求解太阳黄经 = 目标值）
- [ ] LunarCalendarComputer: 用 GB/T 33661 规则编排完整农历

### Phase 3: 数据生成 + 查表法（1-2 天）
- [ ] 用 Phase 2 的引擎计算 1900-2100 全部朔日和闰月
- [ ] 设计 UInt32 压缩编码
- [ ] generate_data.swift 脚本 → 输出 LunarYearData.swift（~800 bytes）
- [ ] LunarTableLookup: 解码 + 查询
- [ ] 人工审查关键年份

### Phase 4: 主 API 整合（1 天）
- [ ] LunarCalendar: 公历↔农历转换
- [ ] LunarCalendar: 闰月/月大小/年天数查询
- [ ] LunarCalendar: 节气查询
- [ ] LunarCalendar: nextLunarBirthday + lunarBirthdays（含降级逻辑）

### Phase 5: 验证 + 测试（2-3 天）
- [ ] 从香港天文台 API 获取数据 → hko_data.json
- [ ] HKOValidationTests: 逐日对比
- [ ] CrossValidationTests: 对比 Apple Calendar(.chinese)
- [ ] BoundaryTests: 已知边界案例全覆盖
- [ ] 全部单元测试 ≥ 700 用例
- [ ] 性能测试: 10000 次转换 < 100ms

### Phase 6: 文档 + 发布准备（1 天）
- [ ] README.md（中英双语，含使用示例）
- [ ] DocC API 文档注释
- [ ] CHANGELOG.md
- [ ] GitHub Actions CI（macOS + Linux）
- [ ] Tag v1.0.0

**预计总工期：9-11 天**

---

## 11. 使用示例

```swift
import LunarCore

let calendar = LunarCalendar.shared
let fmt = LunarFormatter(locale: .chinese)

// ── 公历 → 农历 ──
let lunar = calendar.lunarDate(from: SolarDate(year: 2025, month: 1, day: 29))!
print(fmt.string(from: lunar))                // "二〇二五年正月初一"
print(fmt.string(from: lunar, useGanZhi: true)) // "乙巳年正月初一"

// ── 农历 → 公历 ──
let mid = calendar.solarDate(from: LunarDate(year: 2025, month: 8, day: 15))!
print(mid)  // 2025-10-06 (中秋)

// ── 节气 ──
let qm = calendar.solarTermDate(.qingMing, in: 2025)!
print(qm)  // 2025-04-04

// ── 干支 + 生肖 ──
print(calendar.yearGanZhi(for: 2025).chinese)  // "乙巳"
print(calendar.zodiac(for: 2025).emoji)        // "🐍"

// ── 农历生日（核心场景） ──
let birthdays = calendar.lunarBirthdays(month: 8, day: 15, years: 10)
for date in birthdays {
    let l = calendar.lunarDate(from: date)!
    print("\(date) ← \(fmt.shortString(from: l))")
}
// 2025-10-06 ← 八月十五
// 2026-09-25 ← 八月十五
// 2027-10-15 ← 八月十五
// ...

// ── 闰月降级 ──
// 用户的生日是闰四月十五，但 2026 年没有闰四月
// → 自动降级到普通四月十五
let next = calendar.nextLunarBirthday(month: 4, day: 15, isLeapMonth: true)!

// ── 直接用 Date ──
let today = calendar.lunarDate(from: Date())!
print(fmt.shortString(from: today))
```

---

## 12. 已知边界案例清单（测试必须覆盖）

| # | 案例 | 要点 |
|---|------|------|
| 1 | 2033 年闰冬月（闰十一月） | 极罕见，很多库算错 |
| 2 | 1979 年大寒 | 节气时刻距午夜仅 6 秒 |
| 3 | 2057 年中秋 | 农历九月有争议的边界年份 |
| 4 | 1900 年第一天 | 支持范围下界 |
| 5 | 2100 年最后一天 | 支持范围上界 |
| 6 | 腊月二十九 vs 三十 | 某些年腊月是小月，没有三十 |
| 7 | 2023 年闰二月 | 近年实例验证 |
| 8 | 2025 年闰六月 | 近年实例验证 |
| 9 | 2020 年闰四月 | 近年实例验证 |
| 10 | 1914/1916/1920 朔日 | 历史时间标准差异 |
| 11 | 连续两个小月 | 农历可以出现连续两个 29 天月 |
| 12 | 连续两个大月 | 农历可以出现连续两个 30 天月 |
| 13 | 春节在1月 vs 2月 | 正月初一可以出现在公历1月21日至2月20日之间 |
| 14 | 闰月后的月份编号 | 闰四月后下一个月是五月不是六月 |
| 15 | 农历年总天数 | 平年 353/354/355 天，闰年 383/384/385 天 |

