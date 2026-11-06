import Foundation

/// 템플릿 사용량 통계 (사용 횟수, 마지막 사용일).
/// UserDefaults에 dict 형태로 저장: ["templateID": (count, lastUsedISO)]
struct TemplateUsageStat {
    let count: Int
    let lastUsed: Date?

    var summary: String {
        if count == 0 { return "사용 0회" }
        if let date = lastUsed {
            if Calendar.current.isDateInToday(date) {
                return "사용 \(count)회 · 마지막 오늘"
            } else {
                return "사용 \(count)회 · 마지막 \(DateFormatters.short(date))"
            }
        }
        return "사용 \(count)회"
    }

    static func read(for templateID: String) -> TemplateUsageStat {
        let counts = UserDefaults.standard.dictionary(forKey: "templateUseCounts") as? [String: Int] ?? [:]
        let lastUsedRaw = UserDefaults.standard.dictionary(forKey: "templateLastUsed") as? [String: String] ?? [:]
        let count = counts[templateID] ?? 0
        let last: Date? = lastUsedRaw[templateID].flatMap { ISO8601DateFormatter().date(from: $0) }
        return TemplateUsageStat(count: count, lastUsed: last)
    }

    static func record(for templateID: String) {
        var counts = UserDefaults.standard.dictionary(forKey: "templateUseCounts") as? [String: Int] ?? [:]
        var lastUsed = UserDefaults.standard.dictionary(forKey: "templateLastUsed") as? [String: String] ?? [:]
        counts[templateID, default: 0] += 1
        lastUsed[templateID] = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(counts, forKey: "templateUseCounts")
        UserDefaults.standard.set(lastUsed, forKey: "templateLastUsed")
    }
}
