import Foundation
import LunarCore

struct BenchResult {
    let name: String
    let operations: Int
    let elapsed: TimeInterval

    var microsecondsPerOp: Double {
        elapsed / Double(operations) * 1_000_000
    }
}

struct Pair<A, B> {
    let first: A
    let second: B
}

struct RandomNumberGeneratorLCG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

@inline(never)
func measure(name: String, operations: Int, warmup: Bool = true, _ block: () -> Int) -> BenchResult {
    if warmup {
        let warmupSink = block()
        precondition(warmupSink != .min)
    }

    let start = CFAbsoluteTimeGetCurrent()
    let sink = block()
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    precondition(sink != .min)

    return BenchResult(name: name, operations: operations, elapsed: elapsed)
}

func printHeader() {
    print("LunarCore BenchmarkCLI")
    print("Run with: swift run -c release BenchmarkCLI")
    #if DEBUG
    print("Configuration: DEBUG")
    #else
    print("Configuration: RELEASE")
    #endif
    print("")
    print("\(pad("Benchmark", to: 34)) \(pad("Total", to: 12, alignRight: true)) \(pad("Ops", to: 10, alignRight: true)) \(pad("us/op", to: 12, alignRight: true))")
    print(String(repeating: "-", count: 74))
}

func printResult(_ result: BenchResult) {
    let total = String(format: "%.4fs", result.elapsed)
    let microseconds = String(format: "%.3f", result.microsecondsPerOp)
    print("\(pad(result.name, to: 34)) \(pad(total, to: 12, alignRight: true)) \(pad("\(result.operations)", to: 10, alignRight: true)) \(pad(microseconds, to: 12, alignRight: true))")
}

func pad(_ text: String, to width: Int, alignRight: Bool = false) -> String {
    guard text.count < width else { return text }
    let padding = String(repeating: " ", count: width - text.count)
    return alignRight ? padding + text : text + padding
}

let calendar = LunarCalendar.shared

var solarRng = RandomNumberGeneratorLCG(seed: 42)
let solarDates = (0..<100_000).compactMap { _ in
    SolarDate(
        year: Int.random(in: 1900...2100, using: &solarRng),
        month: Int.random(in: 1...12, using: &solarRng),
        day: Int.random(in: 1...28, using: &solarRng)
    )
}

var lunarRng = RandomNumberGeneratorLCG(seed: 99)
let lunarDates = (0..<100_000).compactMap { _ in
    LunarDate(
        year: Int.random(in: 1900...2100, using: &lunarRng),
        month: Int.random(in: 1...12, using: &lunarRng),
        day: Int.random(in: 1...29, using: &lunarRng)
    )
}

var termRng = RandomNumberGeneratorLCG(seed: 7)
let termRequests = (0..<100_000).map { _ in
    Pair(
        first: SolarTerm.allCases.randomElement(using: &termRng) ?? .qingMing,
        second: Int.random(in: 1900...2100, using: &termRng)
    )
}

var ganZhiRng = RandomNumberGeneratorLCG(seed: 123)
let ganZhiDates = (0..<100_000).compactMap { _ in
    SolarDate(
        year: Int.random(in: 1900...2100, using: &ganZhiRng),
        month: Int.random(in: 1...12, using: &ganZhiRng),
        day: Int.random(in: 1...28, using: &ganZhiRng)
    )
}

let years = Array(1900...2100)

let results = [
    measure(name: "solar -> lunar", operations: solarDates.count) {
        var sink = 0
        for solar in solarDates {
            if let lunar = calendar.lunarDate(from: solar) {
                sink &+= lunar.hashValue
            }
        }
        return sink
    },
    measure(name: "lunar -> solar", operations: lunarDates.count) {
        var sink = 0
        for lunar in lunarDates {
            if let solar = calendar.solarDate(from: lunar) {
                sink &+= solar.hashValue
            }
        }
        return sink
    },
    measure(name: "cold solar terms sweep", operations: years.count, warmup: false) {
        var sink = 0
        for year in years {
            for item in calendar.solarTerms(in: year) {
                sink &+= item.date.hashValue
            }
        }
        return sink
    },
    measure(name: "solarTermDate lookup", operations: termRequests.count) {
        var sink = 0
        for request in termRequests {
            if let date = calendar.solarTermDate(request.first, in: request.second) {
                sink &+= date.hashValue
            }
        }
        return sink
    },
    measure(name: "monthGanZhi lookup", operations: ganZhiDates.count) {
        var sink = 0
        for solar in ganZhiDates {
            sink &+= calendar.monthGanZhi(for: solar).hashValue
        }
        return sink
    },
]

printHeader()
results.forEach(printResult)
