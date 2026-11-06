import SwiftUI

/// 설정 "AI 도구" 패널에 표시할 도구별 연결 상태.
struct AIToolStatus: Identifiable {
    let tool: AITool
    var detected: Bool
    var path: String?
    var version: String?
    var auth: AuthState

    var id: String { tool.id }

    static func checking(_ tool: AITool) -> AIToolStatus {
        AIToolStatus(tool: tool, detected: false, path: nil, version: nil, auth: .checking)
    }
}

/// 도구별 연결 상태를 비동기 프로브로 채워 설정 뷰에 게시한다.
/// `Process` 호출은 detached Task에서 수행하고 결과만 메인에서 갱신한다.
@MainActor
final class ConnectionsModel: ObservableObject {
    @Published private(set) var statuses: [AIToolStatus]
    @Published private(set) var defaultEngineID: String

    let tools: [AITool]

    init() {
        let loaded = AIToolRegistry.loadAll()
        self.tools = loaded
        self.statuses = loaded.map(AIToolStatus.checking)
        self.defaultEngineID = AIToolRegistry.defaultEngineID
    }

    /// 모든 도구 상태를 재프로브한다. (패널 onAppear / "테스트")
    func refreshAll() {
        for tool in tools { probe(tool) }
    }

    /// 단일 도구 재프로브.
    func probe(_ tool: AITool) {
        update(tool.id) { $0.auth = .checking }
        Task.detached(priority: .userInitiated) {
            let path = AIToolLocator.locate(tool)
            let version = path == nil ? nil : AIToolLocator.version(of: tool)
            let auth: AuthState = path == nil ? .unknown : AIToolLocator.authState(of: tool)
            await MainActor.run {
                self.update(tool.id) {
                    $0.detected = path != nil
                    $0.path = path
                    $0.version = version
                    $0.auth = auth
                }
            }
        }
    }

    /// 캐시를 비우고 강제 재탐지 후 프로브. (설정 "자동 탐지")
    func rediscover(_ tool: AITool) {
        update(tool.id) { $0.auth = .checking }
        Task.detached(priority: .userInitiated) {
            _ = AIToolLocator.rediscover(tool)
            await MainActor.run { self.probe(tool) }
        }
    }

    /// 사용자가 NSOpenPanel로 고른 실행파일 경로를 저장하고 프로브.
    /// 호출 전에 실행 가능 여부를 검증해야 한다.
    func setPath(_ path: String, for tool: AITool) {
        AIToolLocator.setCachedPath(path, for: tool)
        probe(tool)
    }

    /// 기본 생성 엔진 변경. 연결된 도구만 호출할 것.
    func setDefault(_ tool: AITool) {
        AIToolRegistry.defaultEngineID = tool.id
        defaultEngineID = tool.id
    }

    func status(for id: String) -> AIToolStatus? {
        statuses.first { $0.id == id }
    }

    private func update(_ id: String, _ mutate: (inout AIToolStatus) -> Void) {
        guard let idx = statuses.firstIndex(where: { $0.id == id }) else { return }
        mutate(&statuses[idx])
    }
}
