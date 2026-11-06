import Foundation

enum AIToolRunnerError: LocalizedError {
    case binaryNotFound(toolName: String)
    case nonZeroExit(toolName: String, code: Int32, stderr: String)
    case noOutput(toolName: String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound(let name):
            return "기본 엔진 \(name)을(를) 찾을 수 없습니다. 설정 › AI 도구에서 경로를 지정하거나 \(name)을(를) 설치하세요."
        case .nonZeroExit(let name, let code, let stderr):
            return "\(name) 실행이 코드 \(code)로 실패했습니다.\n\(stderr.prefix(800))"
        case .noOutput(let name):
            return "\(name)이(가) 빈 응답을 반환했습니다."
        }
    }
}

/// 선택된 AI 도구로 회의록 본문을 생성한다. (기존 `ClaudeRunner` 일반화)
/// 도구의 `invocation.promptVia` 에 따라 프롬프트를 stdin 또는 마지막 인자로 전달한다.
enum AIToolRunner {
    /// - Parameters:
    ///   - onResponseChunk: stdout이 곧 결과인 도구(claude)에서 응답이 차오를 때마다
    ///     **누적 텍스트**를 전달한다. tempfile 도구(codex)는 stdout에 노이즈가 섞여 호출하지 않는다.
    ///   - timeout: 초. 0이면 무제한.
    static func generateMinutes(
        tool: AITool,
        template: PromptTemplate,
        transcriptMarkdown: String,
        hint: String? = nil,
        onResponseChunk: (@Sendable (String) -> Void)? = nil,
        timeout: TimeInterval = 600
    ) async throws -> String {
        guard let path = AIToolLocator.locate(tool) else {
            throw AIToolRunnerError.binaryNotFound(toolName: tool.name)
        }

        let prompt = buildPrompt(template: template, transcriptMarkdown: transcriptMarkdown, hint: hint)

        // outputLastMessageFlag 도구(codex)는 stdout에 에이전트 이벤트가 섞이므로
        // 최종 답을 임시 파일로 받는다. 그 외(claude)는 stdout이 곧 결과.
        var outputFileURL: URL?
        if tool.invocation.outputLastMessageFlag != nil {
            outputFileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("recordup-ai-\(UUID().uuidString).txt")
        }
        // stdin: (args, prompt) · argTail: (args + [prompt], nil)
        // NOTE: argTail 도구는 긴 전사본이 ARG_MAX를 넘을 수 있다. 그런 도구는
        // 스펙에서 promptVia를 "stdin"으로 바꾸는 것이 안전(구현 검증 항목).
        let resolved = tool.resolvedInvocation(prompt: prompt, outputFile: outputFileURL?.path)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = resolved.arguments
        // 임의 프로젝트 디렉터리에서 실행돼 cwd 기반 동작(codex git 체크, claude의
        // CLAUDE.md 로드 등)이 끼어들지 않도록 작업 폴더를 임시 디렉터리로 고정.
        proc.currentDirectoryURL = FileManager.default.temporaryDirectory

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        try proc.run()

        // stdin 방식이면 프롬프트를 쓰고, 어느 경우든 반드시 close (입력 끝 인식).
        if let stdin = resolved.stdin, let data = stdin.data(using: .utf8) {
            try inPipe.fileHandleForWriting.write(contentsOf: data)
        }
        try inPipe.fileHandleForWriting.close()

        // 타임아웃 감시
        if timeout > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if proc.isRunning { proc.terminate() }
            }
        }

        // 동시 read (블로킹 회피). stdout이 곧 결과인 도구만 증분 스트리밍.
        let streamStdout = (outputFileURL == nil) ? onResponseChunk : nil
        async let stdoutData: Data = readPipe(outPipe, onChunk: streamStdout)
        async let stderrData: Data = readPipe(errPipe, onChunk: nil)
        let outData = await stdoutData
        let errData = await stderrData

        proc.waitUntilExit()

        let stdoutText = String(data: outData, encoding: .utf8) ?? ""
        let stderrText = String(data: errData, encoding: .utf8) ?? ""

        // 결과 읽기 전에 임시 출력 파일은 어떤 경로로 끝나든 정리.
        defer {
            if let outURL = outputFileURL {
                try? FileManager.default.removeItem(at: outURL)
            }
        }

        guard proc.terminationStatus == 0 else {
            // codex 등은 에러를 stdout에도 쓰므로 stderr가 비면 stdout을 보여준다.
            let detail = stderrText.isEmpty ? stdoutText : stderrText
            throw AIToolRunnerError.nonZeroExit(toolName: tool.name, code: proc.terminationStatus, stderr: detail)
        }

        let rawResult: String
        if let outURL = outputFileURL {
            rawResult = (try? String(contentsOf: outURL, encoding: .utf8)) ?? ""
        } else {
            rawResult = stdoutText
        }
        let trimmed = rawResult.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw AIToolRunnerError.noOutput(toolName: tool.name)
        }
        return trimmed
    }

    private static func buildPrompt(
        template: PromptTemplate,
        transcriptMarkdown: String,
        hint: String?
    ) -> String {
        let hintBlock: String
        if let hint, !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hintBlock = """

            --- 추가 지시 ---
            \(hint.trimmingCharacters(in: .whitespacesAndNewlines))
            --- 추가 지시 끝 ---

            """
        } else {
            hintBlock = ""
        }
        return """
        \(template.body)
        \(hintBlock)
        --- 전사본 시작 ---
        \(transcriptMarkdown)
        --- 전사본 끝 ---
        """
    }

    /// onChunk가 있으면 stdout을 증분으로 읽어 매번 **누적 디코드 텍스트**를 전달한다.
    /// 없으면 종전대로 끝까지 한 번에 읽는다.
    private static func readPipe(_ pipe: Pipe, onChunk: (@Sendable (String) -> Void)?) async -> Data {
        await Task.detached(priority: .userInitiated) {
            let handle = pipe.fileHandleForReading
            guard let onChunk else {
                return handle.readDataToEndOfFile()
            }
            var acc = Data()
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                acc.append(chunk)
                onChunk(decodeBestEffort(acc))
            }
            return acc
        }.value
    }

    /// UTF-8 멀티바이트 경계에서 잘린 청크가 한국어를 깨뜨리지 않도록 끝 1~3바이트를 잘라가며 디코드.
    private static func decodeBestEffort(_ data: Data) -> String {
        var d = data
        var dropped = 0
        while dropped < 3 {
            if let s = String(data: d, encoding: .utf8) { return s }
            d = d.dropLast()
            dropped += 1
        }
        return String(decoding: data, as: UTF8.self)
    }
}
