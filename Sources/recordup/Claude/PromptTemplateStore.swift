import Foundation

/// `Resources/prompts/*.md` 에서 회의록 프롬프트 템플릿을 로드한다.
/// 사용자가 `~/Documents/record-up/Templates/` 에 같은 파일명을 두면 그쪽이 우선.
struct PromptTemplate: Identifiable, Hashable {
    let id: String           // 파일명 (확장자 제외)
    let title: String        // frontmatter `title` 또는 파일명
    let description: String  // frontmatter `description`
    let body: String         // frontmatter 제거된 본문
    let sourceURL: URL
}

/// 편집 폼에서 양방향 바인딩하기 위한 mutable draft.
struct TemplateDraft: Identifiable, Hashable {
    var id: String
    var title: String
    var description: String
    var body: String

    init(id: String, title: String = "", description: String = "", body: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.body = body
    }

    init(from template: PromptTemplate) {
        self.id = template.id
        self.title = template.title
        self.description = template.description
        self.body = template.body
    }
}

enum PromptTemplateStoreError: LocalizedError {
    case invalidID(String)
    case notUserTemplate
    case ioFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidID(let id):
            return "템플릿 ID는 영문/숫자/-/_ 만 허용합니다: '\(id)'"
        case .notUserTemplate:
            return "번들 템플릿은 직접 수정할 수 없습니다. 먼저 사용자 영역으로 복제하세요."
        case .ioFailed(let msg):
            return "템플릿 저장/삭제 실패: \(msg)"
        }
    }
}

enum PromptTemplateStore {
    static func loadAll() -> [PromptTemplate] {
        var byID: [String: PromptTemplate] = [:]

        // 1) 번들 내장 템플릿
        if let bundleURL = Bundle.main.url(forResource: "prompts", withExtension: nil) {
            for tpl in scan(directory: bundleURL) {
                byID[tpl.id] = tpl
            }
        }
        // 2) 사용자 디렉토리 — 같은 ID는 덮어씀
        let userDir = userTemplatesDirectory()
        if let userTemplates = try? scanIfExists(directory: userDir) {
            for tpl in userTemplates {
                byID[tpl.id] = tpl
            }
        }

        // id 정렬: default 가 항상 첫 번째
        return byID.values.sorted { lhs, rhs in
            if lhs.id == "default" { return true }
            if rhs.id == "default" { return false }
            return lhs.title < rhs.title
        }
    }

    static func userTemplatesDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appending(path: "record-up/Templates", directoryHint: .isDirectory)
    }

    static func isUserTemplate(_ template: PromptTemplate) -> Bool {
        let userPath = userTemplatesDirectory().standardizedFileURL.path
        return template.sourceURL.standardizedFileURL.path.hasPrefix(userPath)
    }

    /// `~/Documents/record-up/Templates/{id}.md` 에 저장. 이미 있으면 덮어쓴다.
    @discardableResult
    static func write(draft: TemplateDraft) throws -> URL {
        let id = draft.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidID(id) else {
            throw PromptTemplateStoreError.invalidID(id)
        }
        let dir = userTemplatesDirectory()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            throw PromptTemplateStoreError.ioFailed(error.localizedDescription)
        }
        let url = dir.appending(path: "\(id).md")
        let text = serialize(draft: draft)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw PromptTemplateStoreError.ioFailed(error.localizedDescription)
        }
        return url
    }

    static func delete(template: PromptTemplate) throws {
        guard isUserTemplate(template) else {
            throw PromptTemplateStoreError.notUserTemplate
        }
        do {
            try FileManager.default.removeItem(at: template.sourceURL)
        } catch {
            throw PromptTemplateStoreError.ioFailed(error.localizedDescription)
        }
    }

    /// 충돌 안 나는 새 ID 생성: "custom-1", "custom-2", ...
    static func nextNewID(among existing: [PromptTemplate]) -> String {
        let used = Set(existing.map { $0.id })
        var i = 1
        while used.contains("custom-\(i)") { i += 1 }
        return "custom-\(i)"
    }

    private static func isValidID(_ id: String) -> Bool {
        guard !id.isEmpty else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        return id.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func serialize(draft: TemplateDraft) -> String {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = draft.body
        var lines: [String] = []
        lines.append("---")
        if !title.isEmpty { lines.append("title: \(title)") }
        if !desc.isEmpty { lines.append("description: \(desc)") }
        lines.append("---")
        lines.append("")
        lines.append(body)
        return lines.joined(separator: "\n")
    }

    private static func scanIfExists(directory: URL) throws -> [PromptTemplate] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return scan(directory: directory)
    }

    private static func scan(directory: URL) -> [PromptTemplate] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        return urls
            .filter { $0.pathExtension == "md" }
            .compactMap { parse(url: $0) }
    }

    private static func parse(url: URL) -> PromptTemplate? {
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let id = url.deletingPathExtension().lastPathComponent

        var title = id
        var description = ""
        var body = raw

        if raw.hasPrefix("---") {
            let parts = raw.split(separator: "---", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count >= 3 {
                let frontmatter = parts[1]
                body = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                for line in frontmatter.split(whereSeparator: \.isNewline) {
                    let kv = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard kv.count == 2 else { continue }
                    switch kv[0] {
                    case "title": title = kv[1]
                    case "description": description = kv[1]
                    default: break
                    }
                }
            }
        }

        return PromptTemplate(id: id, title: title, description: description, body: body, sourceURL: url)
    }
}
