import Foundation
import SwiftUI

/// 회의록 핀(고정) 상태를 UserDefaults에 저장한다.
/// id = MinutesEntry.id (= 파일 절대 경로)
@MainActor
final class PinnedStore: ObservableObject {
    static let shared = PinnedStore()

    private let key = "pinnedMinuteIDs"
    @Published private(set) var ids: Set<String> = []

    init() {
        if let arr = UserDefaults.standard.stringArray(forKey: key) {
            ids = Set(arr)
        }
    }

    func isPinned(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        persist()
    }

    func setPinned(_ id: String, pinned: Bool) {
        if pinned { ids.insert(id) } else { ids.remove(id) }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
