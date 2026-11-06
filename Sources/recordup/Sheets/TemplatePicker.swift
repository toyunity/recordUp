import SwiftUI

/// 드롭 직후 표시되는 템플릿 선택 sheet. 시안 (sheet-template-picker.jsx) 기준.
struct TemplatePickerSheet: View {
    let sourceURL: URL
    let templates: [PromptTemplate]
    let onPick: (PromptTemplate) -> Void
    let onCancel: () -> Void

    @Environment(\.palette) private var p
    @AppStorage("defaultTemplateID") private var defaultTemplateID: String = "decision-action"
    @State private var selectedID: String?
    @State private var reviewTranscript: Bool = true

    private let samples: [String: String] = [
        "default": "• 요약\n• 논의\n• 결정 사항\n• 다음 단계",
        "decision-action": "• 한눈에 보기\n• 결정 사항\n• 액션 아이템\n• 논의 요약",
        "customer-interview": "• 핵심 인사이트\n• 인용구\n• 관찰\n• 후속 질문",
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(templates) { tpl in
                        templateCard(tpl)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
            }
            .frame(maxHeight: 320)
            estimateBar
            footer
        }
        .frame(width: 580)
        .background(p.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(p.lineStrong, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        .onAppear {
            if selectedID == nil {
                selectedID = preferredInitialID()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(p.brandGradient)
                    .frame(width: 38, height: 38)
                    .shadow(color: p.accent2.opacity(0.30), radius: 4, y: 2)
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("회의록 양식 선택")
                    .font(.display(size: 16, weight: .semibold))
                    .foregroundColor(p.ink)
                Text(sourceURL.lastPathComponent)
                    .font(.mono(size: 12))
                    .foregroundColor(p.ink50)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(p.ink50)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private func templateCard(_ tpl: PromptTemplate) -> some View {
        let active = selectedID == tpl.id
        let isDefault = tpl.id == defaultTemplateID
        let featured = isDefault || (defaultTemplateID == "decision-action" && tpl.id == "decision-action")
        return Button {
            selectedID = tpl.id
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(active ? AnyShapeStyle(p.brandGradient) : AnyShapeStyle(p.surface))
                        .frame(width: 36, height: 36)
                        .shadow(color: active ? p.accent2.opacity(0.30) : .clear, radius: 4, y: 2)
                    Image(systemName: icon(for: tpl.id))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(active ? .white : p.ink70)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(active ? Color.clear : p.line, lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(tpl.title)
                            .font(.ui(size: 13.5, weight: .semibold))
                            .foregroundColor(p.ink)
                        if featured {
                            Text(isDefault ? "기본" : "추천")
                                .font(.ui(size: 9.5, weight: .heavy))
                                .foregroundColor(p.accent)
                                .textCase(.uppercase)
                                .tracking(0.4)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3).fill(p.accentSoft)
                                )
                        }
                    }
                    Text(tpl.description.isEmpty ? "—" : tpl.description)
                        .font(.ui(size: 11.5))
                        .foregroundColor(p.ink50)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Text(samples[tpl.id] ?? defaultSample(for: tpl))
                    .font(.mono(size: 10.5))
                    .foregroundColor(p.ink50)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(p.line).frame(width: 0.5)
                    }
                    .frame(maxWidth: 140, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(active ? AnyShapeStyle(p.brandGradientSoft) : AnyShapeStyle(p.canvas))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(active ? p.accent : p.line, lineWidth: active ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func defaultSample(for tpl: PromptTemplate) -> String {
        let lines = tpl.body
            .split(separator: "\n")
            .compactMap { line -> String? in
                let t = line.trimmingCharacters(in: .whitespaces)
                if let r = t.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                    return "• \(String(t[r.upperBound...]))"
                }
                return nil
            }
            .prefix(4)
        return lines.joined(separator: "\n")
    }

    private func icon(for id: String) -> String {
        switch id {
        case "default": return "doc.text"
        case "decision-action": return "flag.fill"
        case "customer-interview": return "person.2"
        case "1on1", "one-on-one": return "person"
        default: return "doc"
        }
    }

    private var estimateBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11))
                .foregroundColor(p.accent)
            Text("예상 처리 시간 ")
                .font(.ui(size: 11.5))
                .foregroundColor(p.ink70)
            + Text("약 1분 30초")
                .font(.ui(size: 11.5, weight: .semibold))
                .foregroundColor(p.ink)
            + Text(" · 32:18 오디오 기준")
                .font(.ui(size: 11.5))
                .foregroundColor(p.ink50)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 9).fill(p.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9).stroke(p.line, lineWidth: 0.5)
        )
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                reviewTranscript.toggle()
            } label: {
                HStack(spacing: 7) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(reviewTranscript ? AnyShapeStyle(p.accent) : AnyShapeStyle(Color.clear))
                            .frame(width: 14, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(reviewTranscript ? p.accent : p.lineStrong, lineWidth: 1.4)
                            .frame(width: 14, height: 14)
                        if reviewTranscript {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("전사본 검토 단계 거치기")
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink70)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button("취소", action: onCancel)
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            Button {
                pickAndDismiss()
            } label: {
                Label("시작", systemImage: "arrow.right")
            }
            .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            .disabled(selectedID == nil)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private func pickAndDismiss() {
        guard let id = selectedID, let tpl = templates.first(where: { $0.id == id }) else { return }
        onPick(tpl)
    }

    private func preferredInitialID() -> String? {
        let candidates = [defaultTemplateID, "decision-action", "default"]
        for id in candidates {
            if let match = templates.first(where: { $0.id == id }) {
                return match.id
            }
        }
        return templates.first?.id
    }
}
