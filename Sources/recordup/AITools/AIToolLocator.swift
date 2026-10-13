import Foundation

/// 도구의 로그인/인증 상태.
enum AuthState {
    case loggedIn, loggedOut, unknown, checking
}

/// 도구별 바이너리 경로 탐지/캐시, 버전, 로그인 상태를 담당한다.
/// GUI macOS 앱은 PATH가 비어 있어 사용자 셸의 CLI를 못 찾으므로,
/// 후보 경로 + login shell(`/bin/zsh -lc 'command -v <id>'`) 폴백으로 절대 경로를 얻고
/// UserDefaults(`aiToolPath.<id>`)에 캐시한다. (기존 `ClaudeBinaryLocator` 일반화)
enum AIToolLocator {
    private static func cacheKey(_ tool: AITool) -> String { "aiToolPath.\(tool.id)" }

    static func cachedPath(_ tool: AITool) -> String? {
        UserDefaults.standard.string(forKey: cacheKey(tool))
    }

    static func setCachedPath(_ path: String?, for tool: AITool) {
        UserDefaults.standard.set(path, forKey: cacheKey(tool))
    }

    /// 캐시에 유효 실행파일이 있으면 반환. 없으면 후보 경로 → login shell 순으로 탐색 후 캐시.
    /// - Returns: 절대 경로. 못 찾으면 nil.
    static func locate(_ tool: AITool) -> String? {
        if let cached = cachedPath(tool), FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }
        for candidate in tool.candidatePaths.map(expandTilde)
        where FileManager.default.isExecutableFile(atPath: candidate) {
            setCachedPath(candidate, for: tool)
            return candidate
        }
        if let discovered = discoverViaLoginShell(binary: tool.id) {
            setCachedPath(discovered, for: tool)
            return discovered
        }
        return nil
    }

    /// 캐시를 비우고 강제 재탐지한다. (설정 "자동 탐지" 버튼)
    @discardableResult
    static func rediscover(_ tool: AITool) -> String? {
        setCachedPath(nil, for: tool)
        return locate(tool)
    }

    /// `versionArgs` 를 실행해 버전 문자열을 반환한다. 실패 시 nil.
    /// 도구마다 형식이 달라(예: claude "2.1.160 (Claude Code)", codex "codex-cli 0.125.0")
    /// **숫자로 시작하는 첫 토큰**을 버전으로 고른다. 없으면 첫 토큰.
    static func version(of tool: AITool) -> String? {
        guard let path = locate(tool) else { return nil }
        guard let raw = run(path: path, args: tool.versionArgs)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        let tokens = raw.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let versionToken = tokens.first(where: { $0.first?.isNumber == true }) ?? tokens.first ?? raw
        return versionToken.hasPrefix("v") ? versionToken : "v\(versionToken)"
    }

    /// 로그인/인증 상태. 스펙이 없으면 `.unknown`.
    static func authState(of tool: AITool) -> AuthState {
        guard let auth = tool.auth else { return .unknown }
        switch auth.type {
        case .credentialFile:
            let paths = (auth.paths ?? []).map(expandTilde)
            let exists = paths.contains { FileManager.default.fileExists(atPath: $0) }
            return exists ? .loggedIn : .loggedOut
        case .command:
            guard let path = locate(tool), let args = auth.args else { return .unknown }
            guard let out = run(path: path, args: args) else { return .loggedOut }
            if let pattern = auth.successPattern {
                return out.contains(pattern) ? .loggedIn : .loggedOut
            }
            return .loggedIn
        }
    }

    /// 구 `claudeBinaryPath` → `aiToolPath.claude` 1회 마이그레이션.
    /// 기존 사용자가 환경설정에서 지정했던 claude 경로를 유지한다.
    static func migrateLegacyClaudePathIfNeeded() {
        let legacyKey = "claudeBinaryPath"
        let newKey = "aiToolPath.claude"
        let ud = UserDefaults.standard
        guard ud.string(forKey: newKey) == nil,
              let legacy = ud.string(forKey: legacyKey), !legacy.isEmpty else { return }
        ud.set(legacy, forKey: newKey)
    }

    // MARK: - Helpers

    static func expandTilde(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    /// 동기 Process 실행 후 stdout 반환. 비정상 종료/예외 시 nil.
    private static func run(path: String, args: [String]) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return nil
        }
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private static func discoverViaLoginShell(binary: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-lc", "command -v \(binary)"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return nil
        }
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return path.isEmpty ? nil : path
    }
}
