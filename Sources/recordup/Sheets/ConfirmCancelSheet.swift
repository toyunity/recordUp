import SwiftUI

/// 진행 중인 작업을 취소할지 묻는 모달.
/// 시안 톤(NewTemplateSheet 백드롭 + 카드)으로 만든 작은 컨펌 시트.
struct ConfirmCancelSheet: View {
    var title: String = "진행 중인 작업을 취소할까요?"
    let message: String
    let confirmLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    /// 있으면 "저장하고 나가기" 같은 3번째 버튼(브랜드 강조)을 노출한다.
    var saveLabel: String? = nil
    var onSave: (() -> Void)? = nil

    @Environment(\.palette) private var p

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(p.line)
                body_
                Divider().background(p.line)
                footer
            }
            .frame(width: onSave != nil ? 480 : 420)
            .background(p.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(p.lineStrong, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(p.accentSoft)
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(p.accent)
            }
            Text(title)
                .font(.display(size: 15, weight: .semibold))
                .foregroundColor(p.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var body_: some View {
        Text(message)
            .font(.ui(size: 12.5))
            .foregroundColor(p.ink70)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Spacer()
            Button("계속 진행", action: onCancel)
                .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
            if let saveLabel, let onSave {
                // 3지선다: 저장 없이 나가기(보조) + 저장하고 나가기(강조)
                Button(confirmLabel, action: onConfirm)
                    .buttonStyle(GhostButtonStyle(palette: p, size: .sm))
                Button(action: onSave) {
                    Label(saveLabel, systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            } else {
                Button(action: onConfirm) {
                    Label(confirmLabel, systemImage: "stop.circle")
                }
                .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(p.surface)
    }
}
