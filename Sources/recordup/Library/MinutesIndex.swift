import Foundation

/// `~/Documents/record-up/minutes/*.md` 의 파일 목록과 메타데이터를 가볍게 인덱싱한다.
/// 라이브러리 화면과 사이드바 "최근 회의록"이 공유한다.
struct MinutesEntry: Identifiable, Hashable {
    let id: String           // 파일 경로
    let url: URL
    let title: String        // # H1 또는 파일명
    let createdAt: Date      // frontmatter generated_at 또는 파일 생성일
    let elapsedSeconds: Double?
    let templateLabel: String?
    let templateID: String?
    let sourceFileName: String?
    let speakerCount: Int?
    let decisionCount: Int
    let actionCount: Int
}

@MainActor
final class MinutesIndex: ObservableObject {
    @Published private(set) var entries: [MinutesEntry] = []

    static let shared = MinutesIndex()

    init() { reload() }

    func reload() {
        let dir = TranscriptExporter.outputDirectory(subdir: "minutes")
        guard FileManager.default.fileExists(atPath: dir.path) else {
            entries = []
            return
        }
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        let parsed = urls
            .filter { $0.pathExtension == "md" }
            .compactMap(parse(url:))
            .sorted { $0.createdAt > $1.createdAt }

        entries = parsed
    }

    var recents: [MinutesEntry] {
        Array(entries.prefix(6))
    }

    // MARK: - Parsing

    private func parse(url: URL) -> MinutesEntry? {
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let creation = (attrs[.creationDate] as? Date) ?? Date()

        var fmTitle: String?
        var fmDate: Date?
        var fmElapsed: Double?
        var fmTemplate: String?
        var fmTemplateID: String?
        var fmSource: String?
        var body = raw

        if raw.hasPrefix("---") {
            let parts = raw.split(separator: "---", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count >= 3 {
                let frontmatter = parts[1]
                body = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                let iso = ISO8601DateFormatter()
                for line in frontmatter.split(whereSeparator: \.isNewline) {
                    let kv = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard kv.count == 2 else { continue }
                    switch kv[0] {
                    case "title": fmTitle = kv[1]
                    case "generated_at": fmDate = iso.date(from: kv[1])
                    case "elapsed_seconds": fmElapsed = Double(kv[1])
                    case "template": fmTemplate = kv[1]
                    case "template_id": fmTemplateID = kv[1]
                    case "source":
                        fmSource = (kv[1] as NSString).lastPathComponent
                    default: break
                    }
                }
            }
        }

        let firstH1 = body
            .split(whereSeparator: \.isNewline)
            .first(where: { $0.hasPrefix("# ") })
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        let titleFromName = url.deletingPathExtension().lastPathComponent
        let title = fmTitle ?? firstH1 ?? titleFromName

        let decisionCount = MinutesIndex.countDecisions(body)
        let actionCount = MinutesIndex.countActions(body)

        return MinutesEntry(
            id: url.path,
            url: url,
            title: title,
            createdAt: fmDate ?? creation,
            elapsedSeconds: fmElapsed,
            templateLabel: fmTemplate,
            templateID: fmTemplateID,
            sourceFileName: fmSource,
            speakerCount: nil,
            decisionCount: decisionCount,
            actionCount: actionCount
        )
    }

    private static func countDecisions(_ body: String) -> Int {
        // "결정 사항" 섹션 안 또는 본문 전체에서 번호 매김 줄을 센다.
        // 안전하게: 결정 키워드 등장 횟수에 캡 적용.
        let lower = body.lowercased()
        let pattern = body.contains("결정 사항") ? "결정" : "decision"
        let count = body.components(separatedBy: pattern).count - 1
        if pattern == "결정" { return min(count, 99) }
        return min(lower.components(separatedBy: pattern).count - 1, 99)
    }

    private static func countActions(_ body: String) -> Int {
        // 액션 아이템 체크박스 패턴: `- [ ] ` 또는 `- [x] `
        var count = 0
        for line in body.split(whereSeparator: \.isNewline) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("- [ ]") || t.hasPrefix("- [x]") || t.hasPrefix("- [X]") {
                count += 1
            }
        }
        return count
    }
}
