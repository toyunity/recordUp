import Foundation

/// 개발 중 GUI 앱의 stdout이 안 보이는 문제 우회용. `/tmp/recordup-debug.log` 에 항상 append.
/// NSLog 와 병행해 호출. 릴리스 단계에서 제거 예정.
enum DebugLog {
    private static let url = URL(fileURLWithPath: "/tmp/recordup-debug.log")
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func log(_ message: String) {
        let line = "\(formatter.string(from: Date())) \(message)\n"
        NSLog("%@", message)
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            if let h = try? FileHandle(forWritingTo: url) {
                defer { try? h.close() }
                h.seekToEndOfFile()
                try? h.write(contentsOf: data)
            }
        } else {
            try? data.write(to: url)
        }
    }
}
