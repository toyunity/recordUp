import SwiftUI

/// 상단 가로 막대. 좌측에 작은 라벨 + 큰 제목, 우측에 액션 슬롯.
struct TopBar: View {
    var breadcrumb: String
    var breadcrumbDetail: String? = nil
    var trailing: () -> AnyView = { AnyView(EmptyView()) }

    @Environment(\.palette) private var p

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                Text(breadcrumb)
                    .font(.ui(size: 13, weight: .semibold))
                    .foregroundColor(p.ink)
                if let detail = breadcrumbDetail {
                    Text(detail)
                        .font(.ui(size: 12))
                        .foregroundColor(p.ink50)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }
}

