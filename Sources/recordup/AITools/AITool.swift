import Foundation

/// 회의록 생성에 쓸 수 있는 로컬 AI CLI 도구의 **선언적 스펙**.
/// `Resources/ai-tools.json` 에서 로드한다. 도구 추가는 대부분 이 JSON 변경만으로 끝난다.
struct AITool: Codable, Identifiable, Hashable {
    let id: String              // "claude" | "codex"
    let name: String            // 표시명 "Claude Code"
    let icon: String            // SF Symbol 이름
    let candidatePaths: [String] // 자동 탐지 후보 (`~` 포함 가능)
    let versionArgs: [String]   // 버전 조회 인자 (예: ["--version"])
    let invocation: Invocation
    let auth: AuthSpec?

    /// 비대화형 호출 규격.
    struct Invocation: Codable, Hashable {
        let args: [String]      // 프롬프트를 제외한 고정 인자
        let promptVia: PromptVia
        /// 있으면 최종 답을 stdout이 아니라 `<flag> <tempfile>` 로 받아 그 파일을 결과로 쓴다.
        /// codex `exec` 처럼 stdout에 에이전트 이벤트가 섞이는 도구용 (예: "-o").
        let outputLastMessageFlag: String?
    }

    /// 프롬프트 전달 방식.
    /// - stdin: 표준입력으로 프롬프트 전달 (claude `-p`)
    /// - argTail: 프롬프트를 마지막 인자로 추가 (codex `exec "…"`)
    enum PromptVia: String, Codable, Hashable {
        case stdin
        case argTail
    }

    /// 로그인/인증 상태 확인 스펙. 없으면 "확인 불가"로 처리.
    struct AuthSpec: Codable, Hashable {
        let type: AuthType
        let paths: [String]?         // credentialFile: 존재하면 로그인으로 추정 (`~` 포함 가능)
        let args: [String]?          // command: 실행 인자
        let successPattern: String?  // command: 성공 판정 부분 문자열

        enum AuthType: String, Codable, Hashable {
            case credentialFile
            case command
        }
    }

    /// 최종 프로세스 인자와 stdin으로 보낼 프롬프트를 계산하는 **순수 함수**.
    /// - Parameter outputFile: `outputLastMessageFlag` 가 있을 때 runner가 만든 임시 파일 경로.
    /// - Returns: `arguments` = Process.arguments, `stdin` = 표준입력 텍스트(없으면 nil).
    func resolvedInvocation(prompt: String, outputFile: String? = nil) -> (arguments: [String], stdin: String?) {
        var base = invocation.args
        if let flag = invocation.outputLastMessageFlag, let outputFile {
            base += [flag, outputFile]   // 프롬프트(argTail) 앞에 출력 플래그를 둔다
        }
        switch invocation.promptVia {
        case .stdin:
            return (base, prompt)
        case .argTail:
            return (base + [prompt], nil)
        }
    }
}
