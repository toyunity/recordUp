import AppKit
import SwiftUI

/// 회의록 검토 — 단일 toolbar + 템플릿 strip + 마크다운 편집/미리보기.
struct MinutesReviewView: View {
    enum Source: Equatable {
        case newRecord
        case library
    }

    let source: Source
    @Binding var minutesText: String
    let savedURL: URL?
    let createdAt: Date?
    let participantCount: Int?
    let onSave: () -> Void
    let onOpenExternal: () -> Void
    let onNew: () -> Void
    let onBack: (() -> Void)?
    let onRegenerate: (String, String) -> Void

    @Environment(\.palette) private var p
    @State private var mode: Mode = .split
    @State private var showExportMenu = false
    @State private var showRegenSheet = false
    @State private var actionStates: [String: Bool] = [:]
    @State private var statusBanner: String?

    enum Mode: String, CaseIterable, Identifiable {
        case edit, split, preview
        var id: String { rawValue }
        var label: String {
            switch self {
            case .edit: return "편집"
            case .split: return "나란히"
            case .preview: return "미리보기"
            }
        }
        var icon: String {
            switch self {
            case .edit: return "pencil"
            case .split: return "rectangle.split.2x1"
            case .preview: return "eye"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                singleToolbar
                templateInfoStrip
                content
                Divider().background(p.line)
                footer
            }
            if let banner = statusBanner {
                statusBannerView(banner)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if showRegenSheet {
                RegenSheet(
                    onCancel: { showRegenSheet = false },
                    onConfirm: { templateID, hint in
                        showRegenSheet = false
                        onRegenerate(templateID, hint)
                    }
                )
            }
        }
        .animation(.easeOut(duration: 0.2), value: statusBanner)
    }

    private func statusBannerView(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(p.success)
            Text(msg)
                .font(.ui(size: 12, weight: .medium))
                .foregroundColor(p.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(p.surface)
        )
        .overlay(
            Capsule().stroke(p.line, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(p.isDark ? 0.4 : 0.15), radius: 10, y: 4)
    }

    // MARK: - Single toolbar

    private var singleToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(breadcrumbText)
                    .font(.ui(size: 11))
                    .foregroundColor(p.ink50)
                HStack(spacing: 8) {
                    Text(parsedTitle)
                        .font(.display(size: 15, weight: .semibold))
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        metaText(displayDate())
                        if let count = participantCount {
                            metaSep()
                            metaText("참석자 \(count)명")
                        }
                        metaSep()
                        metaText("\(minutesText.split(whereSeparator: \.isNewline).count)줄")
                        if savedURL != nil {
                            metaSep()
                            metaText("자동 저장됨")
                                .foregroundColor(p.success)
                        }
                    }
                }
            }
            Spacer()

            modeSegmented

            if source == .newRecord {
                Button {
                    showRegenSheet = true
                } label: {
                    Label("다시 생성", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            }

            ZStack(alignment: .topTrailing) {
                Button {
                    showExportMenu.toggle()
                } label: {
                    Label("내보내기", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
                if showExportMenu {
                    exportMenuOverlay
                        .offset(y: 36)
                }
            }

            if let onBack {
                Button(action: onBack) {
                    Label(backLabel, systemImage: "chevron.left")
                }
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 60)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    private var breadcrumbText: String {
        switch source {
        case .newRecord: return "새 회의록 → 2단계"
        case .library:   return "라이브러리"
        }
    }

    private var backLabel: String {
        switch source {
        case .newRecord: return "전사본으로"
        case .library:   return "라이브러리로"
        }
    }

    private func metaText(_ s: String) -> some View {
        Text(s)
            .font(.mono(size: 11))
            .foregroundColor(p.ink50)
    }
    private func metaSep() -> some View {
        Text("·").font(.mono(size: 11)).foregroundColor(p.ink20)
    }

    private var modeSegmented: some View {
        HStack(spacing: 2) {
            ForEach(Mode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: m.icon)
                            .font(.system(size: 10))
                        Text(m.label)
                            .font(.ui(size: 11.5, weight: .medium))
                    }
                    .foregroundColor(mode == m ? p.ink : p.ink50)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(mode == m ? p.surface : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(mode == m ? p.lineStrong : Color.clear, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(p.line, lineWidth: 0.5)
        )
    }

    private var exportMenuOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            exportItem(icon: "doc.text", label: "Markdown 파일", sub: ".md", shortcut: "⌘S") {
                onSave()
                showExportMenu = false
            }
            exportItem(icon: "doc.richtext", label: "PDF 문서", sub: ".pdf", shortcut: nil) {
                showExportMenu = false
                exportPDF()
            }
            exportItem(icon: "doc", label: "Word 문서", sub: ".rtf", shortcut: nil) {
                showExportMenu = false
                exportRTF()
            }
            menuDivider()
            exportItem(icon: "square.and.arrow.up", label: "공유…", sub: nil, shortcut: "⌘⇧S") {
                showExportMenu = false
                shareCurrent()
            }
            menuDivider()
            exportItem(icon: "link", label: "Notion에 붙여넣기용 복사", sub: "beta", shortcut: nil) {
                showExportMenu = false
                copyForExternal(label: "Notion")
            }
            exportItem(icon: "link", label: "Slack에 붙여넣기용 복사", sub: "beta", shortcut: nil) {
                showExportMenu = false
                copyForExternal(label: "Slack")
            }
        }
        .padding(6)
        .frame(width: 240)
        .background(p.surface)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(p.lineStrong, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(p.isDark ? 0.5 : 0.18), radius: 12, y: 4)
        .zIndex(40)
    }

    private func exportItem(icon: String, label: String, sub: String?, shortcut: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(p.ink70)
                    .frame(width: 18)
                Text(label)
                    .font(.ui(size: 12.5))
                    .foregroundColor(p.ink)
                Spacer(minLength: 0)
                if let s = sub {
                    Text(s)
                        .font(.mono(size: 10))
                        .foregroundColor(p.ink50)
                }
                if let sc = shortcut {
                    Text(sc)
                        .font(.mono(size: 10))
                        .foregroundColor(p.ink35)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7).fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func menuDivider() -> some View {
        Rectangle()
            .fill(p.line)
            .frame(height: 1)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
    }

    // MARK: - Export actions

    private func exportPDF() {
        let name = ExportFormats.suggestedFilename(from: minutesText, fallback: parsedTitle)
        ExportFormats.runSavePanel(
            suggestedName: name,
            allowedExtension: "pdf",
            directoryURL: TranscriptExporter.outputDirectory(subdir: "minutes")
        ) { url in
            try ExportFormats.savePDF(markdown: minutesText, to: url)
            showStatus("PDF로 내보냈습니다 — \(url.lastPathComponent)")
        }
    }

    private func exportRTF() {
        let name = ExportFormats.suggestedFilename(from: minutesText, fallback: parsedTitle)
        ExportFormats.runSavePanel(
            suggestedName: name,
            allowedExtension: "rtf",
            directoryURL: TranscriptExporter.outputDirectory(subdir: "minutes")
        ) { url in
            try ExportFormats.saveRTF(markdown: minutesText, to: url)
            showStatus("RTF로 내보냈습니다 — Word에서 바로 열 수 있어요")
        }
    }

    private func shareCurrent() {
        ExportFormats.showShareSheet(text: minutesText, fileURL: savedURL, relativeTo: nil)
    }

    private func copyForExternal(label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(minutesText, forType: .string)
        showStatus("\(label)에 붙여넣기용으로 복사했습니다 (마크다운 그대로)")
    }

    private func showStatus(_ msg: String) {
        statusBanner = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            if statusBanner == msg { statusBanner = nil }
        }
    }

    // MARK: - Template strip

    private var templateInfoStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 11))
                .foregroundColor(p.accent)
            Text("Claude Code · ")
                .font(.ui(size: 11.5))
                .foregroundColor(p.ink50)
            + Text(parsedTemplate)
                .font(.ui(size: 11.5, weight: .semibold))
                .foregroundColor(p.ink70)
            + Text(" 템플릿으로 생성됨")
                .font(.ui(size: 11.5))
                .foregroundColor(p.ink50)
            Text("·").font(.mono(size: 11)).foregroundColor(p.ink20)
            Text(parsedDuration())
                .font(.mono(size: 11))
                .foregroundColor(p.ink50)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(p.surfaceMuted)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .edit:
            editPane
        case .preview:
            previewPane
        case .split:
            HStack(spacing: 0) {
                editPane
                Divider().background(p.line)
                previewPane
            }
        }
    }

    private var editPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 11))
                Text("마크다운")
                    .font(.ui(size: 10.5, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer()
            }
            .foregroundColor(p.ink50)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            TextEditor(text: $minutesText)
                .font(.mono(size: 12.5))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
                .background(p.canvas)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.canvas)
    }

    private var previewPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.canvas)
    }

    @ViewBuilder
    private func blockView(_ block: PreviewBlock) -> some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(.display(size: 26, weight: .semibold))
                .foregroundColor(p.ink)
                .padding(.bottom, 14)
        case .heading2(let text, let kind):
            HStack(spacing: 10) {
                if let color = kind.color(palette: p) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 4, height: 18)
                }
                Text(text)
                    .font(.display(size: 17, weight: .semibold))
                    .foregroundColor(p.ink)
            }
            .padding(.top, 24)
            .padding(.bottom, 10)
        case .heading3(let text):
            Text(text)
                .font(.display(size: 13.5, weight: .semibold))
                .foregroundColor(p.ink70)
                .padding(.top, 16)
                .padding(.bottom, 6)
        case .meta(let label, let value):
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.ui(size: 12, weight: .medium))
                    .foregroundColor(p.ink50)
                    .frame(minWidth: 60, alignment: .leading)
                Text(value)
                    .font(.ui(size: 12))
                    .foregroundColor(p.ink70)
            }
            .padding(.bottom, 4)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.ui(size: 13))
                    .foregroundColor(p.ink35)
                Text(inlineMarkdown(text))
                    .font(.ui(size: 13.5))
                    .foregroundColor(p.ink70)
                    .lineSpacing(4)
            }
            .padding(.leading, 4)
            .padding(.bottom, 2)
        case .decision(let n, let text):
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(p.decision)
                        .frame(width: 22, height: 22)
                    Text("\(n)")
                        .font(.mono(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(inlineMarkdown(text))
                    .font(.ui(size: 13.5))
                    .foregroundColor(p.ink)
                    .lineSpacing(4)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(p.surface)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(p.decision)
                    .frame(width: 3)
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(p.line, lineWidth: 0.5)
            )
            .padding(.bottom, 6)
        case .action(let id, let text):
            actionItem(id: id, text: text)
        case .paragraph(let text):
            Text(inlineMarkdown(text))
                .font(.ui(size: 13.5))
                .foregroundColor(p.ink70)
                .lineSpacing(4)
                .padding(.bottom, 8)
        case .blank:
            Color.clear.frame(height: 8)
        case .divider:
            Rectangle().fill(p.line).frame(height: 1).padding(.vertical, 8)
        }
    }

    private func actionItem(id: String, text: String) -> some View {
        let checked = actionStates[id] ?? text.contains("[x]") || text.contains("[X]")
        return HStack(alignment: .top, spacing: 10) {
            Button {
                actionStates[id] = !checked
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(checked ? AnyShapeStyle(p.action) : AnyShapeStyle(Color.clear))
                        .frame(width: 16, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(checked ? p.action : p.lineStrong, lineWidth: 1.4)
                        .frame(width: 16, height: 16)
                    if checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            Text(inlineMarkdown(text))
                .font(.ui(size: 13.5))
                .foregroundColor(checked ? p.ink50 : p.ink)
                .strikethrough(checked, color: p.ink50)
                .lineSpacing(3)
            Spacer()
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(checked ? Color.clear : p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(checked ? Color.clear : p.line, lineWidth: 0.5)
        )
        .padding(.bottom, 4)
    }

    private func inlineMarkdown(_ s: String) -> AttributedString {
        if let attr = try? AttributedString(markdown: s) {
            return attr
        }
        return AttributedString(s)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.system(size: 11))
                .foregroundColor(p.ink50)
            Text(savedURL?.path ?? "~/Documents/record-up/minutes/…")
                .font(.mono(size: 11))
                .foregroundColor(p.ink70)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(minutesText, forType: .string)
            } label: {
                Label("복사", systemImage: "doc.on.doc")
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                guard let url = savedURL else { return }
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } label: {
                Label("Finder에서 보기", systemImage: "folder")
            }
            .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            .disabled(savedURL == nil)
            Button {
                onNew()
            } label: {
                Label("새 회의록", systemImage: "plus")
            }
            .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(p.surface)
    }

    // MARK: - Parsing

    private var parsedTitle: String {
        let lines = minutesText.split(whereSeparator: \.isNewline).map(String.init)
        return lines.first(where: { $0.hasPrefix("# ") }).map { String($0.dropFirst(2)) } ?? "회의록"
    }

    private var parsedTemplate: String {
        if minutesText.contains("결정") && minutesText.contains("액션") { return "결정·액션 추출" }
        if minutesText.contains("인터뷰") { return "고객 인터뷰" }
        return "기본 회의록"
    }

    private func parsedDuration() -> String {
        if let body = frontmatterField("elapsed_seconds"),
           let v = Double(body) {
            return "\(TranscriptExporter.formatTime(v)) 회의"
        }
        return ""
    }

    private func frontmatterField(_ key: String) -> String? {
        guard minutesText.hasPrefix("---") else { return nil }
        let parts = minutesText.split(separator: "---", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count >= 3 else { return nil }
        for line in parts[1].split(whereSeparator: \.isNewline) {
            let kv = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if kv.count == 2 && kv[0] == key { return kv[1] }
        }
        return nil
    }

    private func displayDate() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 생성"
        return f.string(from: createdAt ?? Date())
    }

    private enum HeadingKind {
        case decision, action, normal
        func color(palette p: ThemePalette) -> Color? {
            switch self {
            case .decision: return p.decision
            case .action: return p.action
            case .normal: return nil
            }
        }
    }

    private enum PreviewBlock {
        case heading1(String)
        case heading2(String, HeadingKind)
        case heading3(String)
        case meta(String, String)
        case bullet(String)
        case decision(Int, String)
        case action(String, String)
        case paragraph(String)
        case blank
        case divider
    }

    private func parseBlocks() -> [PreviewBlock] {
        var result: [PreviewBlock] = []
        var inDecisions = false
        var decisionN = 0

        var body = minutesText
        if body.hasPrefix("---") {
            let parts = body.split(separator: "---", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count >= 3 {
                body = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        for (lineIdx, raw) in body.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(raw)
            let t = line.trimmingCharacters(in: .whitespaces)

            if t.isEmpty {
                result.append(.blank)
                continue
            }
            if t == "---" {
                result.append(.divider)
                continue
            }
            if t.hasPrefix("# ") {
                inDecisions = false
                result.append(.heading1(String(t.dropFirst(2))))
                continue
            }
            if t.hasPrefix("## ") {
                let h = String(t.dropFirst(3))
                let kind: HeadingKind = h.contains("결정") ? .decision : (h.contains("액션") ? .action : .normal)
                inDecisions = (kind == .decision)
                if inDecisions { decisionN = 0 }
                result.append(.heading2(h, kind))
                continue
            }
            if t.hasPrefix("### ") {
                inDecisions = false
                result.append(.heading3(String(t.dropFirst(4))))
                continue
            }
            // 메타라인 **label** value
            if t.hasPrefix("**"),
               let close = t.range(of: "**", range: t.index(t.startIndex, offsetBy: 2)..<t.endIndex) {
                let label = String(t[t.index(t.startIndex, offsetBy: 2)..<close.lowerBound])
                let rest = String(t[close.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty {
                    result.append(.meta(label, rest))
                    continue
                }
            }
            if t.hasPrefix("- [ ]") || t.hasPrefix("- [x]") || t.hasPrefix("- [X]") {
                let body = t.replacingOccurrences(of: "- [ ]", with: "")
                    .replacingOccurrences(of: "- [x]", with: "")
                    .replacingOccurrences(of: "- [X]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                let preChecked = t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                let id = "act-\(lineIdx)"
                if actionStates[id] == nil { actionStates[id] = preChecked }
                result.append(.action(id, body))
                continue
            }
            if let r = t.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let body = String(t[r.upperBound...])
                if inDecisions {
                    decisionN += 1
                    result.append(.decision(decisionN, body))
                } else {
                    result.append(.bullet(body))
                }
                continue
            }
            if t.hasPrefix("- ") {
                result.append(.bullet(String(t.dropFirst(2))))
                continue
            }
            result.append(.paragraph(t))
        }
        return result
    }
}

// MARK: - Regen sheet

private struct RegenSheet: View {
    let onCancel: () -> Void
    let onConfirm: (String, String) -> Void
    @Environment(\.palette) private var p
    @State private var selected: String = "decision-action"
    @State private var hint: String = ""

    private let templates: [(id: String, name: String, sub: String)] = [
        ("default", "기본 회의록", "요약·논의·다음 단계"),
        ("decision-action", "결정·액션 추출", "결정사항과 액션 아이템 강조"),
        ("customer-interview", "고객 인터뷰", "인사이트·인용·질문"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("회의록 다시 생성")
                        .font(.display(size: 16, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text("템플릿을 바꾸거나 추가 지시를 더해서 다시 만들 수 있어요. 전사본은 그대로 사용됩니다.")
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink50)
                        .lineSpacing(3)
                }
                VStack(spacing: 6) {
                    ForEach(templates, id: \.id) { tpl in
                        templateRow(tpl)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("추가 지시 (선택)")
                        .font(.ui(size: 11, weight: .semibold))
                        .foregroundColor(p.ink70)
                    TextEditor(text: $hint)
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(height: 70)
                        .background(p.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(p.lineStrong, lineWidth: 0.5)
                        )
                }
                HStack {
                    Spacer()
                    Button("취소", action: onCancel)
                        .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                    Button {
                        onConfirm(selected, hint)
                    } label: {
                        Label("다시 생성", systemImage: "sparkle")
                    }
                    .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
                }
            }
            .padding(20)
            .frame(width: 480)
            .background(p.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(p.lineStrong, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        }
    }

    private func templateRow(_ tpl: (id: String, name: String, sub: String)) -> some View {
        let active = selected == tpl.id
        return Button {
            selected = tpl.id
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(active ? p.accent : p.lineStrong, lineWidth: 1.4)
                        .frame(width: 14, height: 14)
                    Circle().fill(p.accent).frame(width: 7, height: 7).opacity(active ? 1 : 0)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(tpl.name)
                        .font(.ui(size: 13, weight: .semibold))
                        .foregroundColor(p.ink)
                    Text(tpl.sub)
                        .font(.ui(size: 11.5))
                        .foregroundColor(p.ink50)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(active ? p.accentSoft : p.canvas)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(active ? p.accent : p.line, lineWidth: active ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
