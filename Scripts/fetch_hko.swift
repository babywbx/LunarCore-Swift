#!/usr/bin/env swift
// Fetches lunar calendar data from Hong Kong Observatory Open Data API
// for 2024-2026, saves to Tests/LunarCoreTests/Fixtures/hko_data.json.
// Usage: swift Scripts/fetch_hko.swift

import Foundation

struct HKOEntry: Codable {
    let date: String      // "YYYY-MM-DD"
    let lunarYear: String // e.g. "乙巳年，蛇"
    let lunarDate: String // e.g. "正月初一" or "閏六月廿七"
}

// Generate all dates from start to end inclusive.
func allDates(startYear: Int, endYear: Int) -> [String] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    var current = calendar.date(from: DateComponents(year: startYear, month: 1, day: 1))!
    let end = calendar.date(from: DateComponents(year: endYear, month: 12, day: 31))!

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    formatter.timeZone = TimeZone(identifier: "UTC")!

    var dates: [String] = []
    while current <= end {
        dates.append(formatter.string(from: current))
        current = calendar.date(byAdding: .day, value: 1, to: current)!
    }
    return dates
}

// Synchronous fetch with retry.
func fetchEntry(_ dateStr: String, retries: Int = 3) -> HKOEntry? {
    for attempt in 1...retries {
        let sem = DispatchSemaphore(value: 0)
        let url = URL(string:
            "https://data.weather.gov.hk/weatherAPI/opendata/lunardate.php?date=\(dateStr)")!
        var result: HKOEntry?

        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { sem.signal() }
            guard
                let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                let ly = json["LunarYear"],
                let ld = json["LunarDate"]
            else { return }
            let formatted = "\(dateStr.prefix(4))-\(dateStr.dropFirst(4).prefix(2))-\(dateStr.suffix(2))"
            result = HKOEntry(date: formatted, lunarYear: ly, lunarDate: ld)
        }.resume()

        sem.wait()
        if let result { return result }
        if attempt < retries {
            Thread.sleep(forTimeInterval: Double(attempt) * 0.5)
        }
    }
    return nil
}

// Main
let dates = allDates(startYear: 2024, endYear: 2026)
print("Fetching \(dates.count) dates from HKO API...")

var entries: [HKOEntry] = []
var failures: [String] = []
let batchSize = 10

for i in stride(from: 0, to: dates.count, by: batchSize) {
    let batch = Array(dates[i..<min(i + batchSize, dates.count)])
    let group = DispatchGroup()
    var batchResults: [(Int, HKOEntry)] = []
    let lock = NSLock()

    for (j, dateStr) in batch.enumerated() {
        group.enter()
        DispatchQueue.global().async {
            if let entry = fetchEntry(dateStr) {
                lock.lock()
                batchResults.append((i + j, entry))
                lock.unlock()
            } else {
                lock.lock()
                failures.append(dateStr)
                lock.unlock()
            }
            group.leave()
        }
    }

    group.wait()
    entries.append(contentsOf: batchResults.sorted(by: { $0.0 < $1.0 }).map(\.1))

    let progress = min(i + batchSize, dates.count)
    print("\r  \(progress)/\(dates.count) (\(Int(Double(progress) / Double(dates.count) * 100))%)", terminator: "")
    fflush(stdout)

    if i + batchSize < dates.count {
        Thread.sleep(forTimeInterval: 0.3)
    }
}

print("\nDone: \(entries.count) fetched, \(failures.count) failed")
if !failures.isEmpty {
    print("Failed dates: \(failures.prefix(20).joined(separator: ", "))")
}

entries.sort(by: { $0.date < $1.date })
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let jsonData = try encoder.encode(entries)

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectRoot = scriptDir.deletingLastPathComponent()
let outputDir = projectRoot.appendingPathComponent("Tests/LunarCoreTests/Fixtures")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
let outputPath = outputDir.appendingPathComponent("hko_data.json")
try jsonData.write(to: outputPath)
print("Saved to \(outputPath.path)")
