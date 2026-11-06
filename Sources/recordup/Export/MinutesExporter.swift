import AppKit
import Foundation

enum MinutesExporter {
    /// claude -p 결과 본문 + 메타 헤더를 붙여 회의록 .md 저장.
    @discardableResult
    static func save(
        body: String,
        sourceURL: URL,
        templateTitle: String,
        templateID: String? = nil,
        elapsedSeconds: TimeInterval,
        existingURL: URL? = nil
    ) throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let now = formatter.string(from: Date())
        let elapsedStr = String(format: "%.1f", elapsedSeconds)
        let templateIDLine = templateID.map { "template_id: \($0)\n" } ?? ""

        let header = """
        ---
        source: \(sourceURL.path)
        template: \(templateTitle)
        \(templateIDLine.isEmpty ? "" : templateIDLine.trimmingCharacters(in: .newlines))
        generated_at: \(now)
        elapsed_seconds: \(elapsedStr)
        ---

        """

        let dir = TranscriptExporter.outputDirectory(subdir: "minutes")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // 같은 작업의 재저장(자동 저장 → 편집 ⌘S → 다시 생성)은 동일 파일을 덮어쓴다.
        // filename(for:)이 분 단위 타임스탬프를 쓰므로, 재사용 URL이 없으면 분 경계마다 중복 파일이 생긴다.
        let outURL = existingURL ?? dir.appending(path: TranscriptExporter.filename(for: sourceURL))
        try (header + body).write(to: outURL, atomically: true, encoding: .utf8)
        return outURL
    }

    static func openInDefaultEditor(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
