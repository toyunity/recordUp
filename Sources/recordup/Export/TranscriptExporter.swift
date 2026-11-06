import Foundation

enum TranscriptExporter {
    /// EditableTranscript(사용자 매핑·편집 반영본)를 사람·LLM 모두 읽기 좋은 Markdown으로 변환.
    @MainActor
    static func render(transcript: EditableTranscript) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let now = formatter.string(from: Date())

        var lines: [String] = []
        lines.append("---")
        lines.append("source: \(transcript.sourceURL.path)")
        lines.append("duration: \(formatTime(transcript.durationSeconds))")
        lines.append("speakers: \(transcript.activeSpeakerCount)")
        lines.append("generated_at: \(now)")
        if !transcript.speakerNames.isEmpty {
            let mappings = transcript.usedSpeakerIds
                .map { id -> String in
                    let name = transcript.displayName(for: id)
                    return "\(EditableTranscript.defaultLabel(for: id))→\(name)"
                }
                .joined(separator: ", ")
            if !mappings.isEmpty {
                lines.append("speaker_mapping: \(mappings)")
            }
        }
        lines.append("---")
        lines.append("")
        lines.append("# 전사본 — \(transcript.sourceURL.deletingPathExtension().lastPathComponent)")
        lines.append("")

        for seg in transcript.segments {
            let body = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { continue }
            let label = transcript.displayName(for: seg.speakerId)
            let timeRange = "(\(formatTime(seg.startTime))–\(formatTime(seg.endTime)))"
            lines.append("**\(label)** \(timeRange)")
            lines.append(body)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// 결과 `.md` 를 표준 위치에 저장하고 URL을 반환.
    @discardableResult
    static func save(
        markdown: String,
        sourceURL: URL,
        subdir: String = "transcripts"
    ) throws -> URL {
        let dir = outputDirectory(subdir: subdir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fname = filename(for: sourceURL)
        let outURL = dir.appending(path: fname)
        try markdown.write(to: outURL, atomically: true, encoding: .utf8)
        return outURL
    }

    static func outputDirectory(subdir: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appending(path: "record-up/\(subdir)", directoryHint: .isDirectory)
    }

    static func filename(for sourceURL: URL) -> String {
        let stamp = stampFormatter.string(from: Date())
        let base = sourceURL.deletingPathExtension().lastPathComponent
        return "\(stamp)-\(base).md"
    }

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
