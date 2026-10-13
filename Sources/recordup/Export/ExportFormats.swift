import AppKit
import Foundation

/// 회의록 마크다운을 다양한 포맷으로 내보내는 헬퍼.
enum ExportFormats {

    enum ExportError: LocalizedError {
        case attributedConversionFailed
        case pdfContextFailed
        case rtfEncodingFailed

        var errorDescription: String? {
            switch self {
            case .attributedConversionFailed: return "마크다운을 변환할 수 없습니다."
            case .pdfContextFailed: return "PDF 컨텍스트를 만들 수 없습니다."
            case .rtfEncodingFailed: return "RTF로 인코딩할 수 없습니다."
            }
        }
    }

    // MARK: - Attributed document (미리보기 형태 서식)

    // PDF/RTF는 흰 종이에 raw CGContext로 그려지고 appearance 컨텍스트가 없어, 동적색
    // (labelColor 등)이 다크 모드에서 흰색으로 풀려 글자가 안 보인다. 고정 색으로 그린다.
    private static let cInk = NSColor(calibratedWhite: 0.13, alpha: 1)
    private static let cInk60 = NSColor(calibratedWhite: 0.42, alpha: 1)
    private static let cInk40 = NSColor(calibratedWhite: 0.62, alpha: 1)
    private static let cLine = NSColor(calibratedWhite: 0.80, alpha: 1)

    /// 회의록 마크다운을 미리보기와 유사하게 **서식화된** NSAttributedString으로 변환.
    /// frontmatter·HTML 주석(`<!-- ... -->`)을 제거하고 헤더 크기·굵기·메타라인·불릿·
    /// 결정(번호)·액션(체크박스)을 스타일링한다. (`MinutesReviewView.parseBlocks` 미러링)
    /// 표 등 미리보기가 처리하지 않는 구문은 동일하게 문단으로 떨어뜨려 미리보기와 형태를 맞춘다.
    /// PDF/RTF 공통 경로.
    static func attributedDocument(from markdown: String) -> NSAttributedString {
        let body = strippedBody(markdown)
        let out = NSMutableAttributedString()
        var inDecisions = false
        var decisionN = 0

        for raw in body.components(separatedBy: "\n") {
            let t = raw.trimmingCharacters(in: .whitespaces)

            if t.isEmpty { out.append(spacer(6)); continue }
            if t == "---" { out.append(divider()); continue }

            if t.hasPrefix("# ") {
                inDecisions = false
                out.append(line(String(t.dropFirst(2)),
                                font: .systemFont(ofSize: 22, weight: .bold), color: cInk,
                                paragraph: para(before: 6, after: 10, lineSpacing: 2)))
                continue
            }
            if t.hasPrefix("## ") {
                let h = String(t.dropFirst(3))
                inDecisions = h.contains("결정")
                if inDecisions { decisionN = 0 }
                out.append(line(h,
                                font: .systemFont(ofSize: 16, weight: .semibold), color: cInk,
                                paragraph: para(before: 16, after: 6, lineSpacing: 2)))
                continue
            }
            if t.hasPrefix("### ") {
                inDecisions = false
                out.append(line(String(t.dropFirst(4)),
                                font: .systemFont(ofSize: 13.5, weight: .semibold), color: cInk60,
                                paragraph: para(before: 10, after: 4, lineSpacing: 2)))
                continue
            }

            // 메타라인 **label** value
            if t.hasPrefix("**"),
               let close = t.range(of: "**", range: t.index(t.startIndex, offsetBy: 2)..<t.endIndex) {
                let label = String(t[t.index(t.startIndex, offsetBy: 2)..<close.lowerBound])
                let rest = String(t[close.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty {
                    let m = NSMutableAttributedString()
                    m.append(NSAttributedString(string: "\(label)   ", attributes: [
                        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: cInk60,
                    ]))
                    m.append(inlineStyled(rest, baseFont: .systemFont(ofSize: 12), color: cInk))
                    m.append(NSAttributedString(string: "\n"))
                    m.addAttribute(.paragraphStyle, value: para(before: 1, after: 3, lineSpacing: 2),
                                   range: NSRange(location: 0, length: m.length))
                    out.append(m)
                    continue
                }
            }

            // 액션 아이템 (- [ ] / - [x])
            if t.hasPrefix("- [ ]") || t.hasPrefix("- [x]") || t.hasPrefix("- [X]") {
                let checked = t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                let txt = t.replacingOccurrences(of: "- [ ]", with: "")
                    .replacingOccurrences(of: "- [x]", with: "")
                    .replacingOccurrences(of: "- [X]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                out.append(line(txt,
                                font: .systemFont(ofSize: 13),
                                color: checked ? cInk60 : cInk,
                                paragraph: para(before: 1, after: 3, lineSpacing: 3, headIndent: 16),
                                prefix: NSAttributedString(string: checked ? "☑  " : "☐  ", attributes: [
                                    .font: NSFont.systemFont(ofSize: 13),
                                    .foregroundColor: checked ? cInk60 : cInk,
                                ]),
                                strikethrough: checked))
                continue
            }

            // 번호 목록 (결정 섹션이면 번호 카드, 아니면 불릿)
            if let r = t.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let txt = String(t[r.upperBound...])
                if inDecisions {
                    decisionN += 1
                    out.append(line(txt,
                                    font: .systemFont(ofSize: 13), color: cInk,
                                    paragraph: para(before: 3, after: 3, lineSpacing: 3, headIndent: 22),
                                    prefix: NSAttributedString(string: "\(decisionN).   ", attributes: [
                                        .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                                        .foregroundColor: cInk,
                                    ])))
                } else {
                    out.append(bullet(txt))
                }
                continue
            }
            if t.hasPrefix("- ") { out.append(bullet(String(t.dropFirst(2)))); continue }

            out.append(line(t, font: .systemFont(ofSize: 13), color: cInk,
                            paragraph: para(before: 2, after: 6, lineSpacing: 4)))
        }
        return out
    }

    private static func bullet(_ s: String) -> NSAttributedString {
        line(s, font: .systemFont(ofSize: 13), color: cInk,
             paragraph: para(before: 1, after: 2, lineSpacing: 3, headIndent: 14),
             prefix: NSAttributedString(string: "•   ", attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: cInk40,
             ]))
    }

    /// 접두(불릿/번호/체크박스) + 인라인 서식 본문 + 줄바꿈을 한 문단으로 조립.
    private static func line(
        _ inline: String,
        font: NSFont,
        color: NSColor,
        paragraph: NSParagraphStyle,
        prefix: NSAttributedString? = nil,
        strikethrough: Bool = false
    ) -> NSAttributedString {
        let m = NSMutableAttributedString()
        if let prefix { m.append(prefix) }
        m.append(inlineStyled(inline, baseFont: font, color: color))
        m.append(NSAttributedString(string: "\n"))
        let full = NSRange(location: 0, length: m.length)
        m.addAttribute(.paragraphStyle, value: paragraph, range: full)
        if strikethrough {
            m.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: full)
        }
        return m
    }

    /// `**bold**` 구간만 굵게 처리. `**`로 split해 홀수 인덱스를 굵게 — 한글 멀티바이트 안전.
    private static func inlineStyled(_ s: String, baseFont: NSFont, color: NSColor) -> NSAttributedString {
        let bold = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        let m = NSMutableAttributedString()
        for (i, part) in s.components(separatedBy: "**").enumerated() where !part.isEmpty {
            m.append(NSAttributedString(string: part, attributes: [
                .font: (i % 2 == 1) ? bold : baseFont,
                .foregroundColor: color,
            ]))
        }
        return m
    }

    private static func para(
        before: CGFloat = 0, after: CGFloat = 0, lineSpacing: CGFloat = 0, headIndent: CGFloat = 0
    ) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = before
        p.paragraphSpacing = after
        p.lineSpacing = lineSpacing
        p.headIndent = headIndent
        return p
    }

    private static func spacer(_ height: CGFloat) -> NSAttributedString {
        NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: height)])
    }

    private static func divider() -> NSAttributedString {
        NSAttributedString(string: "────────────────────\n", attributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: cLine,
            .paragraphStyle: para(before: 8, after: 8),
        ])
    }

    /// frontmatter(첫 `---`…다음 `---`)와 HTML 주석(`<!-- ... -->`)을 제거한 본문.
    private static func strippedBody(_ md: String) -> String {
        var lines = md.components(separatedBy: "\n")
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            if let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
                lines = Array(lines[(end + 1)...])
            }
        }
        var text = lines.joined(separator: "\n")
        if let re = try? NSRegularExpression(pattern: "<!--[\\s\\S]*?-->") {
            text = re.stringByReplacingMatches(
                in: text, options: [], range: NSRange(text.startIndex..., in: text), withTemplate: ""
            )
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - PDF

    /// 마크다운 본문을 PDF로 저장. 자동 페이지 분할.
    static func savePDF(markdown: String, to url: URL) throws {
        let attr = attributedDocument(from: markdown)
        let pageSize = NSSize(width: 612, height: 792) // US Letter
        let margin: CGFloat = 54
        let textRect = NSRect(
            x: margin,
            y: margin,
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            throw ExportError.pdfContextFailed
        }
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ExportError.pdfContextFailed
        }

        let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        var currentRange = CFRange(location: 0, length: 0)
        let totalLength = attr.length

        repeat {
            ctx.beginPDFPage(nil)
            let path = CGPath(rect: CGRect(origin: .zero, size: textRect.size), transform: nil)

            // CoreText는 좌하단 원점. PDF context도 동일하므로 텍스트 박스를 페이지 위쪽으로 이동.
            ctx.saveGState()
            ctx.translateBy(x: textRect.origin.x, y: textRect.origin.y)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, ctx)
            let visible = CTFrameGetVisibleStringRange(frame)
            currentRange = CFRange(location: visible.location + visible.length, length: 0)
            ctx.restoreGState()
            ctx.endPDFPage()

            if visible.length == 0 { break } // 안전 가드
        } while currentRange.location < totalLength

        ctx.closePDF()
        try (pdfData as Data).write(to: url)
    }

    // MARK: - RTF (Word 호환)

    /// 마크다운을 RTF로 저장. .docx는 아니지만 Word에서 그대로 열림.
    static func saveRTF(markdown: String, to url: URL) throws {
        let attr = attributedDocument(from: markdown)
        guard let data = try? attr.data(
            from: NSRange(location: 0, length: attr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            throw ExportError.rtfEncodingFailed
        }
        try data.write(to: url)
    }

    // MARK: - Save panel

    /// NSSavePanel을 띄워 사용자가 저장 위치를 고르도록 한 뒤 작업 실행.
    /// - Parameter directoryURL: 패널이 처음 열릴 기본 폴더. 미지정 시 NSSavePanel은
    ///   앱이 마지막으로 연 패널 위치를 기억하는데, 음성 메모 불러오기가 TCC 보호 폴더
    ///   (Voice Memos Recordings)를 열어두면 저장 패널도 그 폴더를 기본값으로 띄워 쓰기
    ///   권한 거부(NSCocoaError 513 / EPERM)가 난다. 쓰기 가능한 폴더를 명시해 회피한다.
    static func runSavePanel(
        suggestedName: String,
        allowedExtension: String,
        directoryURL: URL? = nil,
        save: (URL) throws -> Void
    ) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = []
        panel.canCreateDirectories = true
        panel.title = "내보내기"
        panel.prompt = "저장"
        if let directoryURL {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            panel.directoryURL = directoryURL
        }

        if panel.runModal() == .OK, var url = panel.url {
            if url.pathExtension.lowercased() != allowedExtension {
                url = url.appendingPathExtension(allowedExtension)
            }
            do {
                try save(url)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                let alert = NSAlert()
                alert.messageText = "내보내기 실패"
                alert.informativeText = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    // MARK: - Share picker

    /// 시스템 공유 시트를 표시. 본문 텍스트 + 저장된 파일 URL이 있으면 둘 다 공유.
    static func showShareSheet(text: String, fileURL: URL?, relativeTo view: NSView?) {
        var items: [Any] = [text]
        if let fileURL { items.append(fileURL) }
        let picker = NSSharingServicePicker(items: items)
        if let view {
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        } else if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }

    // MARK: - Filename suggestion

    static func suggestedFilename(from markdown: String, fallback: String = "회의록") -> String {
        let lines = markdown.split(whereSeparator: \.isNewline).map(String.init)
        if let title = lines.first(where: { $0.hasPrefix("# ") }) {
            let stripped = title.dropFirst(2).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty { return stripped }
        }
        return fallback
    }
}
