import Foundation

/// 번들 `Resources/ai-tools.json` 에서 도구 목록을 로드하고,
/// 사용자가 고른 **기본 생성 엔진**(`defaultEngineID`)을 관리한다.
/// `ReleaseNotesStore`/`PromptTemplateStore` 와 동일한 "번들 리소스 + Store" 패턴.
enum AIToolRegistry {
    private static let defaultEngineKey = "defaultEngineID"
    static let fallbackID = "claude"

    /// 번들에 정의된 모든 도구. JSON 순서를 유지한다.
    static func loadAll() -> [AITool] {
        guard let url = Bundle.main.url(forResource: "ai-tools", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tools = try? JSONDecoder().decode([AITool].self, from: data) else {
            return []
        }
        return tools
    }

    static func tool(id: String) -> AITool? {
        loadAll().first { $0.id == id }
    }

    /// 사용자가 고른 기본 엔진 id. 미설정 시 `claude`.
    static var defaultEngineID: String {
        get { UserDefaults.standard.string(forKey: defaultEngineKey) ?? fallbackID }
        set { UserDefaults.standard.set(newValue, forKey: defaultEngineKey) }
    }

    /// 기본 생성 엔진. 저장된 id가 없거나 사라졌으면 claude → 첫 도구로 폴백.
    static func defaultTool() -> AITool? {
        let all = loadAll()
        if let chosen = all.first(where: { $0.id == defaultEngineID }) { return chosen }
        if let claude = all.first(where: { $0.id == fallbackID }) { return claude }
        return all.first
    }
}
