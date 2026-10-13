import SwiftUI

/// "새 템플릿" 모달. 시안 (screen-templates.jsx의 NewTemplateSheet) 기준.
/// - 이름 + 아이콘 picker (6개)
/// - 설명 (선택)
/// - 시작 방식 라디오: blank / duplicate / preset
struct NewTemplateSheet: View {
    let existing: [PromptTemplate]
    let onCreate: (TemplateDraft) -> Void
    let onCancel: () -> Void

    @Environment(\.palette) private var p
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var iconName: String = "doc.text"
    @State private var startMode: StartMode = .blank
    @State private var presetID: String?
    @State private var presetTopic: String = "스프린트 회고"

    private let iconChoices = [
        "doc.text", "flag.fill", "person.2", "person", "sparkle", "bolt.fill"
    ]
    private let presetTopics = [
        "스프린트 회고", "디자인 리뷰", "리서치 인터뷰", "주간 1:1", "브레인스토밍"
    ]

    enum StartMode: String, CaseIterable {
        case blank, duplicate, preset
        var label: String {
            switch self {
            case .blank: return "빈 템플릿"
            case .duplicate: return "기존 템플릿 복제"
            case .preset: return "프리셋에서 시작"
            }
        }
        var sub: String {
            switch self {
            case .blank: return "섹션을 직접 추가합니다"
            case .duplicate: return "선택한 템플릿의 섹션·프롬프트를 복사"
            case .preset: return "회고·리서치·1:1 등 추천 구성"
            }
        }
        var icon: String {
            switch self {
            case .blank: return "plus"
            case .duplicate: return "doc.on.doc"
            case .preset: return "sparkle"
            }
        }
    }

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var summary: String {
        switch startMode {
        case .blank: return "빈 상태로 만들기"
        case .duplicate:
            let t = existing.first(where: { $0.id == presetID })?.title ?? "—"
            return "\(t) 복제"
        case .preset: return "프리셋에서 시작"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            VStack(spacing: 0) {
                header
                Divider().background(p.line)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        nameField
                        descriptionField
                        startModeSection
                        if startMode == .duplicate { duplicatePicker }
                        if startMode == .preset { presetPicker }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                }
                Divider().background(p.line)
                footer
            }
            .frame(width: 540)
            .frame(maxHeight: 600)
            .background(p.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(p.lineStrong, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        }
        .onAppear {
            if presetID == nil { presetID = existing.first?.id }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("새 템플릿")
                    .font(.display(size: 17, weight: .semibold))
                    .foregroundColor(p.ink)
                Text("회의록 양식의 이름과 시작 방식을 정해주세요")
                    .font(.ui(size: 12))
                    .foregroundColor(p.ink50)
            }
            Spacer()
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(p.ink50)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6).fill(Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이름")
                .font(.ui(size: 11, weight: .semibold))
                .foregroundColor(p.ink70)
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(p.surfaceMuted)
                        .frame(width: 38, height: 38)
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(p.accent)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
                )
                TextField("예: 스프린트 리뷰", text: $name)
                    .textFieldStyle(.plain)
                    .font(.ui(size: 13))
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(p.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
                    )
            }
            HStack(spacing: 4) {
                ForEach(iconChoices, id: \.self) { ic in
                    Button { iconName = ic } label: {
                        Image(systemName: ic)
                            .font(.system(size: 12))
                            .foregroundColor(iconName == ic ? p.accent : p.ink50)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(iconName == ic ? p.accentSoft : p.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(iconName == ic ? p.accent : p.line, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("설명")
                    .font(.ui(size: 11, weight: .semibold))
                    .foregroundColor(p.ink70)
                Text("(선택)")
                    .font(.ui(size: 11))
                    .foregroundColor(p.ink35)
            }
            TextField("이 템플릿을 언제 쓰는지 한 줄로", text: $description)
                .textFieldStyle(.plain)
                .font(.ui(size: 12.5))
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(p.canvas)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
                )
        }
    }

    private var startModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("시작 방식")
                .font(.ui(size: 11, weight: .semibold))
                .foregroundColor(p.ink70)
            VStack(spacing: 6) {
                ForEach(StartMode.allCases, id: \.self) { mode in
                    startModeRow(mode)
                }
            }
        }
    }

    private func startModeRow(_ mode: StartMode) -> some View {
        let active = startMode == mode
        return Button {
            startMode = mode
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(active ? p.accentSoft : p.surfaceMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: mode.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(active ? p.accent : p.ink50)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.label)
                        .font(.ui(size: 12.5, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text(mode.sub)
                        .font(.ui(size: 11))
                        .foregroundColor(p.ink50)
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(active ? p.accent : p.lineStrong, lineWidth: 1.4)
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(p.accent)
                        .frame(width: 7, height: 7)
                        .opacity(active ? 1 : 0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(active ? p.surface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(active ? p.accent : p.line, lineWidth: active ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var duplicatePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("복제할 템플릿")
                .font(.ui(size: 11))
                .foregroundColor(p.ink50)
            FlowLayout(spacing: 6) {
                ForEach(existing) { tpl in
                    chip(label: tpl.title, isSelected: presetID == tpl.id) {
                        presetID = tpl.id
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 9).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9).stroke(p.line, lineWidth: 0.5)
        )
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("프리셋")
                .font(.ui(size: 11))
                .foregroundColor(p.ink50)
            FlowLayout(spacing: 6) {
                ForEach(presetTopics, id: \.self) { topic in
                    chip(label: topic, isSelected: presetTopic == topic) {
                        presetTopic = topic
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 9).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9).stroke(p.line, lineWidth: 0.5)
        )
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.ui(size: 11.5, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? p.accent : p.ink70)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isSelected ? p.accentSoft : p.canvas)
                )
                .overlay(
                    Capsule().stroke(isSelected ? p.accent : p.line, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text(summary)
                .font(.mono(size: 11))
                .foregroundColor(p.ink50)
            Spacer()
            Button("취소", action: onCancel)
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                createDraft()
            } label: {
                Label("만들기", systemImage: "checkmark")
            }
            .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            .disabled(!valid)
            .opacity(valid ? 1 : 0.4)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(p.surface)
    }

    private func createDraft() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let id = generateID(from: trimmed)
        var body: String
        switch startMode {
        case .blank:
            body = "회의록 작성 지침을 여기에 입력하세요.\n\n# 형식\n\n# 섹션\n1. 한눈에 보기\n\n# 입력\n{{transcript}}"
        case .duplicate:
            body = existing.first(where: { $0.id == presetID })?.body ?? ""
        case .preset:
            body = "다음은 한국어로 진행된 \(presetTopic) 회의의 전사본입니다. 이를 바탕으로 회의록을 작성해주세요.\n\n# 입력\n{{transcript}}"
        }
        let draft = TemplateDraft(
            id: id,
            title: trimmed,
            description: description.trimmingCharacters(in: .whitespaces),
            body: body
        )
        onCreate(draft)
    }

    private func generateID(from name: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let cleaned = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
        let base = cleaned.isEmpty ? "tpl" : cleaned
        let usedIDs = Set(existing.map { $0.id })
        if !usedIDs.contains(base) { return base }
        var n = 2
        while usedIDs.contains("\(base)-\(n)") { n += 1 }
        return "\(base)-\(n)"
    }
}

/// 간단한 wrap layout — 칩 컬렉션용.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                width = max(width, x - spacing)
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        width = max(width, x - spacing)
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
