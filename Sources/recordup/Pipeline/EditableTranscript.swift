import Foundation
import SpeakerKit

/// 화자 단위로 그룹된 편집 가능한 한 블록.
struct EditableSegment: Identifiable, Hashable {
    let id: UUID = UUID()
    var speakerId: Int?
    var startTime: Double
    var endTime: Double
    var text: String
}

/// SpeakerKit 분리 결과를 사용자 편집용 모델로 흡수한다.
/// - 화자 ID → 표시 이름 매핑(`speakerNames`)을 사용자가 바꿀 수 있다.
/// - 화자/블록을 사용자가 추가·삭제할 수 있다.
/// - 각 블록의 텍스트도 자유 편집 가능.
@MainActor
final class EditableTranscript: ObservableObject {
    let sourceURL: URL
    let durationSeconds: Double

    /// 사용자 정의 화자 이름. 비어 있으면 기본 라벨("화자 A", "화자 B" …) 사용.
    @Published var speakerNames: [Int: String] = [:]
    @Published var segments: [EditableSegment] = []
    /// 화자 picker 옵션. 자동 감지된 ID + 사용자가 수동 추가한 ID 합집합.
    @Published private(set) var registeredSpeakerIds: [Int] = []

    init(sourceURL: URL, durationSeconds: Double, segments: [EditableSegment]) {
        self.sourceURL = sourceURL
        self.durationSeconds = durationSeconds
        self.segments = segments
        self.registeredSpeakerIds = Self.uniqueSorted(from: segments)
    }

    /// SpeakerKit `addSpeakerInfo(to:)` 가 돌려준 `[[SpeakerSegment]]` 에서 변환.
    /// outer 배열은 같은 화자가 연속된 블록 단위.
    static func from(
        sourceURL: URL,
        durationSeconds: Double,
        speakerSegments: [[SpeakerSegment]]
    ) -> EditableTranscript {
        var blocks: [EditableSegment] = []
        for group in speakerSegments {
            guard let first = group.first, let last = group.last else { continue }
            let body = group.map { $0.text }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { continue }
            blocks.append(EditableSegment(
                speakerId: first.speaker.speakerId,
                startTime: Double(first.startTime),
                endTime: Double(last.endTime),
                text: body
            ))
        }
        return EditableTranscript(
            sourceURL: sourceURL,
            durationSeconds: durationSeconds,
            segments: blocks
        )
    }

    private static func uniqueSorted(from segments: [EditableSegment]) -> [Int] {
        Array(Set(segments.compactMap { $0.speakerId })).sorted()
    }

    /// 블록에 실제로 사용된 unique 화자 ID(정렬).
    var usedSpeakerIds: [Int] {
        Array(Set(segments.compactMap { $0.speakerId })).sorted()
    }

    /// 실제 .md 저장에 쓰이는 화자 수(블록에 사용된 unique 화자).
    var activeSpeakerCount: Int { usedSpeakerIds.count }

    /// 등록된 전체 화자 수(자동 감지 + 수동 추가).
    var registeredSpeakerCount: Int { registeredSpeakerIds.count }

    /// 사용자 매핑이 있으면 그것, 없으면 "화자 A" 식 기본 라벨.
    func displayName(for speakerId: Int?) -> String {
        guard let id = speakerId else { return "화자 ?" }
        if let custom = speakerNames[id]?.trimmingCharacters(in: .whitespaces),
           !custom.isEmpty {
            return custom
        }
        return Self.defaultLabel(for: id)
    }

    static func defaultLabel(for id: Int) -> String {
        if id >= 0, id < 26 {
            let scalar = UnicodeScalar(65 + id)!
            return "화자 \(Character(scalar))"
        }
        return "화자 \(id)"
    }

    // MARK: - Speaker mutation

    /// 새 화자 추가. 0..N 중 가장 작은 빈 자리에 등록한다.
    @discardableResult
    func addSpeaker() -> Int {
        let used = Set(registeredSpeakerIds)
        var id = 0
        while used.contains(id) { id += 1 }
        registeredSpeakerIds.append(id)
        registeredSpeakerIds.sort()
        return id
    }

    /// 화자 삭제. 단, 등록된 화자가 1명만 남으면 삭제하지 않는다.
    /// 사용 중인 화자를 지우면 해당 블록의 speakerId는 남은 첫 화자로 재매핑된다.
    @discardableResult
    func removeSpeaker(id: Int) -> Bool {
        guard registeredSpeakerIds.count > 1 else { return false }
        guard let idx = registeredSpeakerIds.firstIndex(of: id) else { return false }
        registeredSpeakerIds.remove(at: idx)
        speakerNames.removeValue(forKey: id)

        // 사용 중인 블록 재매핑
        let fallback = registeredSpeakerIds.first
        for i in segments.indices where segments[i].speakerId == id {
            segments[i].speakerId = fallback
        }
        return true
    }

    // MARK: - Segment mutation

    /// `index` 위치 바로 다음에 새 블록 삽입. (-1 이면 맨 앞)
    func insertSegment(after index: Int) {
        let newSpeakerId: Int?
        let newStart: Double
        let newEnd: Double

        if index < 0 {
            // 맨 앞
            let firstStart = segments.first?.startTime ?? 0
            newStart = max(0, firstStart - 0.001)
            newEnd = newStart
            newSpeakerId = segments.first?.speakerId ?? registeredSpeakerIds.first
        } else if index < segments.count {
            let prev = segments[index]
            newStart = prev.endTime
            // 다음 블록의 시작이 더 뒤면 그 사이를 채움. 아니면 0 길이.
            let next = (index + 1 < segments.count) ? segments[index + 1] : nil
            newEnd = next?.startTime ?? prev.endTime
            newSpeakerId = prev.speakerId
        } else {
            // 맨 뒤
            let lastEnd = segments.last?.endTime ?? 0
            newStart = lastEnd
            newEnd = lastEnd
            newSpeakerId = segments.last?.speakerId ?? registeredSpeakerIds.first
        }

        let new = EditableSegment(
            speakerId: newSpeakerId,
            startTime: newStart,
            endTime: newEnd,
            text: ""
        )
        let insertAt = max(0, min(segments.count, index + 1))
        segments.insert(new, at: insertAt)
    }

    func removeSegment(at index: Int) {
        guard segments.indices.contains(index) else { return }
        segments.remove(at: index)
    }

    /// picker에서 블록의 화자를 변경할 때.
    func setSpeaker(_ speakerId: Int?, forSegmentAt index: Int) {
        guard segments.indices.contains(index) else { return }
        segments[index].speakerId = speakerId
    }
}
