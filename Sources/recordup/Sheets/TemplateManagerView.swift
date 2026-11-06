import AppKit
import SwiftUI

/// 회의록 양식(프롬프트 템플릿) 관리 화면.
/// 좌측: 템플릿 카드 리스트.
/// 우측: 선택 템플릿의 헤더 + 섹션 구성 + 프롬프트.
struct TemplateManagerView: View {
    let onClose: () -> Void

    @Environment(\.palette) private var p
    @AppStorage("defaultTemplateID") private var defaultTemplateID: String = "decision-action"
    @State private var templates: [PromptTemplate] = []
    @State private var selectedID: String?
    @State private var draft: TemplateDraft?
    @State private var sections: [TemplateSection] = []
    @State private var sectionDraft: String = ""
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var showNewSheet = false
    @State private var editing = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopBar(breadcrumb: "템플릿", breadcrumbDetail: "회의록 양식 관리")
                HStack(spacing: 0) {
                    templateList
                        .frame(width: 320)
                        .background(p.canvas.opacity(0.5))
                    Divider().background(p.line)
                    detailPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            if showNewSheet {
                NewTemplateSheet(
                    existing: templates,
                    onCreate: { newDraft in
                        do {
                            _ = try PromptTemplateStore.write(draft: newDraft)
                            statusMessage = "생성됨 — \(newDraft.id).md"
                            reload(selecting: newDraft.id)
                        } catch {
                            errorMessage = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                        }
                        showNewSheet = false
                    },
                    onCancel: { showNewSheet = false }
                )
            }
        }
        .onAppear {
            reload(selecting: nil)
        }
    }

    // MARK: - Sidebar list

    private var templateList: some View {
        VStack(spacing: 12) {
            Button {
                showNewSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("새 템플릿")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandButtonStyle(size: .md, palette: p))
            .padding(.horizontal, 18)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(templates) { tpl in
                        templateCard(tpl)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
    }

    private func templateCard(_ tpl: PromptTemplate) -> some View {
        let active = selectedID == tpl.id
        let isUser = PromptTemplateStore.isUserTemplate(tpl)
        let usageStat = TemplateUsageStat.read(for: tpl.id)
        return Button {
            select(tpl)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(active ? AnyShapeStyle(p.brandGradient) : AnyShapeStyle(p.surfaceMuted))
                            .frame(width: 26, height: 26)
                        Image(systemName: icon(for: tpl.id))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(active ? .white : p.ink70)
                    }
                    Text(tpl.title)
                        .font(.ui(size: 13, weight: .semibold))
                        .foregroundColor(p.ink)
                    Spacer(minLength: 0)
                    if !isUser {
                        Text("기본")
                            .font(.ui(size: 9.5, weight: .heavy))
                            .foregroundColor(p.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3).fill(p.accentSoft)
                            )
                            .textCase(.uppercase)
                            .tracking(0.4)
                    } else {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(p.ink50)
                    }
                }
                Text(tpl.description.isEmpty ? "—" : tpl.description)
                    .font(.ui(size: 11.5))
                    .foregroundColor(p.ink50)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 34)
                Text(usageStat.summary)
                    .font(.mono(size: 10.5))
                    .foregroundColor(p.ink35)
                    .padding(.top, 2)
                    .padding(.leading, 34)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? AnyShapeStyle(p.surface) : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? p.lineStrong : Color.clear, lineWidth: 0.5)
            )
            .shadow(color: active ? .black.opacity(p.isDark ? 0.2 : 0.04) : .clear, radius: 2, y: 1)
            // 비선택 카드는 배경이 Color.clear라 투명 영역이 hit-test되지 않는다.
            // contentShape로 패딩 포함 카드 전체를 클릭 영역으로 만든다.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(for id: String) -> String {
        switch id {
        case "default": return "doc.text"
        case "decision-action": return "flag"
        case "customer-interview": return "person.2"
        case "1on1", "one-on-one": return "person"
        default: return "doc"
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPanel: some View {
        if let _ = draft {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    detailHeader
                    sectionEditor
                    promptEditor
                    if let msg = statusMessage {
                        Text(msg)
                            .font(.ui(size: 12))
                            .foregroundColor(p.success)
                    }
                    if let err = errorMessage {
                        Text(err)
                            .font(.ui(size: 12))
                            .foregroundColor(p.accent2)
                    }
                    actionRow
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundColor(p.ink35)
            Text("좌측에서 템플릿을 선택하세요")
                .font(.ui(size: 14, weight: .semibold))
                .foregroundColor(p.ink70)
            Text("또는 \"+ 새 템플릿\"으로 만들 수 있어요")
                .font(.ui(size: 12))
                .foregroundColor(p.ink50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(p.brandGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: p.accent2.opacity(0.30), radius: 5, y: 2)
                Image(systemName: icon(for: draft?.id ?? "default"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                if editing && !isReadonly {
                    TextField("템플릿 이름", text: bind(\.title))
                        .textFieldStyle(.plain)
                        .font(.display(size: 22, weight: .semibold))
                        .foregroundColor(p.ink)
                    TextField("부제 (선택)", text: bind(\.description))
                        .textFieldStyle(.plain)
                        .font(.ui(size: 13))
                        .foregroundColor(p.ink70)
                } else {
                    Text(draft?.title ?? "")
                        .font(.display(size: 22, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text((draft?.description ?? "").isEmpty ? "(설명 없음)" : (draft?.description ?? ""))
                        .font(.ui(size: 13))
                        .foregroundColor((draft?.description ?? "").isEmpty ? p.ink35 : p.ink70)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Button {
                    if let cur = currentTemplate { duplicateToUser(cur) }
                } label: {
                    Label("복제", systemImage: "doc.on.doc")
                }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))

                Button {
                    if let id = selectedID {
                        defaultTemplateID = id
                        statusMessage = "기본 템플릿으로 설정됨 — 다음 회의록부터 자동 선택됩니다"
                    }
                } label: {
                    Label(
                        isCurrentDefault ? "기본 템플릿" : "기본 템플릿 설정",
                        systemImage: isCurrentDefault ? "star.fill" : "star"
                    )
                }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                .disabled(isCurrentDefault)

                Button {
                    if isReadonly, let cur = currentTemplate {
                        duplicateToUser(cur)
                        editing = true
                    } else {
                        editing.toggle()
                    }
                } label: {
                    Label(editing ? "완료" : "편집", systemImage: editing ? "checkmark" : "pencil")
                }
                .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            }
        }
    }

    // MARK: - Section editor

    private var sectionEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("섹션 구성")
                .font(.ui(size: 12, weight: .semibold))
                .foregroundColor(p.ink70)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { idx, section in
                    sectionCard(idx: idx, section: section)
                }
                addSectionRow
            }
            Text("이 구성이 그대로 프롬프트에 반영됩니다")
                .font(.ui(size: 11))
                .foregroundColor(p.ink50)
        }
    }

    private func sectionCard(idx: Int, section: TemplateSection) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(p.surfaceMuted)
                    .frame(width: 16, height: 16)
                Text("\(idx + 1)")
                    .font(.mono(size: 10, weight: .semibold))
                    .foregroundColor(p.ink70)
            }
            TextField("섹션 이름", text: Binding(
                get: { sections[idx].name },
                set: { newVal in
                    sections[idx].name = newVal
                    refreshPromptFromSections()
                }
            ))
            .textFieldStyle(.plain)
            .font(.ui(size: 13))
            .foregroundColor(p.ink)
            .disabled(isReadonly)

            Button {
                sections.remove(at: idx)
                refreshPromptFromSections()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(p.ink50)
            }
            .buttonStyle(.plain)
            .disabled(isReadonly)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(p.line, lineWidth: 0.5)
        )
    }

    private var addSectionRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 11))
                .foregroundColor(p.ink50)
            TextField("+ 섹션 추가", text: $sectionDraft, onCommit: addSection)
                .textFieldStyle(.plain)
                .font(.ui(size: 13))
                .foregroundColor(p.ink)
                .disabled(isReadonly)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(p.line, style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
        )
    }

    private func addSection() {
        let n = sectionDraft.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        sections.append(.init(id: UUID(), name: n))
        sectionDraft = ""
        refreshPromptFromSections()
    }

    // MARK: - Prompt editor

    private var promptEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("프롬프트")
                    .font(.ui(size: 12, weight: .semibold))
                    .foregroundColor(p.ink70)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text("섹션 변경 시 자동 갱신됩니다")
                        .font(.ui(size: 11))
                }
                .foregroundColor(p.ink50)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(p.ink10)
                )
            }
            TextEditor(text: bind(\.body))
                .font(.mono(size: 12))
                .foregroundColor(p.ink70)
                .scrollContentBackground(.hidden)
                .padding(14)
                .frame(minHeight: 240)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(p.surfaceMuted)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(p.line, lineWidth: 0.5)
                )
                .disabled(isReadonly)
            if isReadonly {
                Text("이 템플릿은 번들 내장이라 직접 편집할 수 없습니다. \"복제\"로 사용자 영역에 사본을 만든 뒤 편집하세요.")
                    .font(.ui(size: 11))
                    .foregroundColor(p.accent2)
            }
        }
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack {
            if let cur = currentTemplate, !isCurrentBundled {
                Button(role: .destructive) {
                    deleteCurrent(cur)
                } label: {
                    Label("삭제", systemImage: "trash")
                }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            }
            Spacer()
            Button("닫기") { onClose() }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            if !isReadonly {
                Button {
                    saveCurrent()
                } label: {
                    Text("저장")
                }
                .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            }
        }
    }

    // MARK: - State helpers

    private var currentTemplate: PromptTemplate? {
        guard let id = selectedID else { return nil }
        return templates.first(where: { $0.id == id })
    }

    private var isCurrentBundled: Bool {
        guard let t = currentTemplate else { return false }
        return !PromptTemplateStore.isUserTemplate(t)
    }

    private var isReadonly: Bool { isCurrentBundled }

    private var isCurrentDefault: Bool {
        selectedID == defaultTemplateID
    }

    private func bind<T>(_ key: WritableKeyPath<TemplateDraft, T>) -> Binding<T> {
        Binding(
            get: { draft?[keyPath: key] ?? defaultValue(for: key) },
            set: { newVal in
                guard var d = draft else { return }
                d[keyPath: key] = newVal
                draft = d
                statusMessage = nil
                errorMessage = nil
            }
        )
    }

    private func defaultValue<T>(for key: WritableKeyPath<TemplateDraft, T>) -> T {
        let probe = TemplateDraft(id: "", title: "", description: "", body: "")
        return probe[keyPath: key]
    }

    // MARK: - Section <-> body sync

    private func refreshPromptFromSections() {
        guard var d = draft else { return }
        let header = "다음은 한국어로 진행된 회의의 전사본입니다. 이를 바탕으로 회의록을 작성해주세요.\n\n# 형식\n - 한국어 마크다운으로 출력\n - 결정사항은 명확히 번호 매기기\n - 액션 아이템은 [  ] 체크박스 + 담당자 + 기한 형식\n - 인용은 그대로 옮기지 말고 의미 단위로 요약\n\n# 섹션\n"
        let body = sections.enumerated()
            .map { idx, sec in "\(idx + 1). \(sec.name)" }
            .joined(separator: "\n")
        let footer = "\n\n# 입력\n{{transcript}}\n"
        d.body = header + body + footer
        draft = d
    }

    private func extractSections(from body: String) -> [TemplateSection] {
        // 본문에서 "# 섹션" 다음의 번호 매김 줄을 추출. 없으면 빈 배열.
        let lines = body.components(separatedBy: "\n")
        var inSection = false
        var result: [TemplateSection] = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t == "# 섹션" || t == "# Sections" {
                inSection = true
                continue
            }
            if inSection {
                if t.hasPrefix("#") { break }
                if let dot = t.range(of: ". ") {
                    let after = String(t[dot.upperBound...])
                    if !after.isEmpty {
                        result.append(.init(id: UUID(), name: after))
                    }
                }
            }
        }
        return result
    }

    // MARK: - CRUD

    private func reload(selecting id: String?) {
        templates = PromptTemplateStore.loadAll()
        if let id, let tpl = templates.first(where: { $0.id == id }) {
            select(tpl)
        } else if let first = templates.first {
            select(first)
        } else {
            selectedID = nil
            draft = nil
            sections = []
        }
    }

    private func select(_ tpl: PromptTemplate) {
        selectedID = tpl.id
        draft = TemplateDraft(from: tpl)
        sections = extractSections(from: tpl.body)
        statusMessage = nil
        errorMessage = nil
    }

    private func createNew() {
        let id = PromptTemplateStore.nextNewID(among: templates)
        let new = TemplateDraft(
            id: id,
            title: "새 템플릿",
            description: "",
            body: "회의록 작성 지침을 여기에 입력하세요."
        )
        selectedID = id
        draft = new
        sections = []
        statusMessage = "새 템플릿을 작성한 뒤 \"저장\"을 누르세요."
        errorMessage = nil
    }

    private func saveCurrent() {
        guard let d = draft else { return }
        do {
            _ = try PromptTemplateStore.write(draft: d)
            statusMessage = "저장됨 — \(d.id).md"
            errorMessage = nil
            reload(selecting: d.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
    }

    private func duplicateToUser(_ tpl: PromptTemplate) {
        var newID = tpl.id
        let userIDs = Set(templates.filter { PromptTemplateStore.isUserTemplate($0) }.map { $0.id })
        if userIDs.contains(newID) {
            var n = 1
            while userIDs.contains("\(tpl.id)-copy\(n > 1 ? "\(n)" : "")") { n += 1 }
            newID = "\(tpl.id)-copy\(n > 1 ? "\(n)" : "")"
        }
        let d = TemplateDraft(id: newID, title: tpl.title, description: tpl.description, body: tpl.body)
        do {
            _ = try PromptTemplateStore.write(draft: d)
            statusMessage = "사용자 영역에 복제됨 — \(newID).md"
            errorMessage = nil
            reload(selecting: newID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
    }

    private func deleteCurrent(_ tpl: PromptTemplate) {
        do {
            try PromptTemplateStore.delete(template: tpl)
            statusMessage = "삭제됨 — \(tpl.id).md"
            errorMessage = nil
            reload(selecting: nil)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
    }
}

struct TemplateSection: Identifiable, Hashable {
    let id: UUID
    var name: String
}
