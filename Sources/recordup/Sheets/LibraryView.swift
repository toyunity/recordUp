import AppKit
import SwiftUI

struct LibraryView: View {
    @ObservedObject var index: MinutesIndex
    @Binding var selected: MinutesEntry?
    let onNewRecord: () -> Void

    @Environment(\.palette) private var p
    @ObservedObject private var pinned = PinnedStore.shared
    @State private var search: String = ""
    @State private var filter: LibraryFilter = .all
    @State private var hoverID: String?

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                breadcrumb: "라이브러리",
                breadcrumbDetail: "이전에 처리한 회의록",
                trailing: {
                    AnyView(
                        Button {
                            onNewRecord()
                        } label: {
                            Label("새 회의록", systemImage: "plus")
                        }
                        .buttonStyle(BrandButtonStyle(size: .sm, palette: p))
                    )
                }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    filters
                    table
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 22)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { index.reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("이전 회의록")
                .font(.display(size: 26, weight: .bold))
                .foregroundColor(p.ink)
            Spacer()
            searchField
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(p.ink50)
            TextField("회의록 검색…", text: $search)
                .textFieldStyle(.plain)
                .font(.ui(size: 13))
                .foregroundColor(p.ink)
            Text("⌘F")
                .font(.mono(size: 11))
                .foregroundColor(p.ink50)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(p.ink10)
                )
        }
        .padding(.horizontal, 12)
        .frame(width: 280, height: 34)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(p.line, lineWidth: 0.5)
        )
    }

    // MARK: - Filters

    private var filters: some View {
        HStack(spacing: 8) {
            ForEach(LibraryFilter.allCases) { f in
                filterChip(f)
            }
        }
    }

    private func filterChip(_ f: LibraryFilter) -> some View {
        let active = filter == f
        let count = countFor(f)
        return Button {
            filter = f
        } label: {
            HStack(spacing: 6) {
                Text(f.label)
                    .font(.ui(size: 12, weight: active ? .semibold : .medium))
                    .foregroundColor(active ? .white : p.ink70)
                Text("\(count)")
                    .font(.mono(size: 11, weight: .semibold))
                    .foregroundColor(active ? .white.opacity(0.85) : p.ink50)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(active ? Color.white.opacity(0.18) : p.ink10)
                    )
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(
                Capsule()
                    .fill(active ? AnyShapeStyle(p.brandGradient) : AnyShapeStyle(p.surface))
            )
            .overlay(
                Capsule()
                    .strokeBorder(active ? Color.clear : p.line, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func entries(for filter: LibraryFilter) -> [MinutesEntry] {
        let pool = index.entries
        switch filter {
        case .all: return pool
        case .decisionAction: return pool.filter { matchesTemplate($0, "decision-action", "결정") }
        case .basic: return pool.filter { matchesTemplate($0, "default", "기본") }
        case .interview: return pool.filter { matchesTemplate($0, "customer-interview", "인터뷰") }
        case .pinned: return pool.filter { pinned.isPinned($0.id) }
        }
    }

    private func countFor(_ f: LibraryFilter) -> Int {
        entries(for: f).count
    }

    private func matchesTemplate(_ entry: MinutesEntry, _ id: String, _ keyword: String) -> Bool {
        if let tid = entry.templateID, tid == id { return true }
        return (entry.templateLabel ?? "").contains(keyword)
    }

    private var filtered: [MinutesEntry] {
        let pool = entries(for: filter)
        if search.isEmpty { return pool }
        let q = search.lowercased()
        return pool.filter { entry in
            entry.title.lowercased().contains(q)
                || (entry.sourceFileName ?? "").lowercased().contains(q)
        }
    }

    // MARK: - Table

    private var table: some View {
        VStack(spacing: 0) {
            tableHeader
            if filtered.isEmpty {
                emptyState
            } else {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, entry in
                    rowView(entry: entry, isAlt: idx.isMultiple(of: 2))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(p.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(p.line, lineWidth: 0.5)
        )
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 36)
            colLabel("제목", width: nil, align: .leading)
            colLabel("날짜", width: 130, align: .leading)
            colLabel("길이", width: 90, align: .leading)
            colLabel("화자", width: 110, align: .leading)
            colLabel("결정/액션", width: 110, align: .leading)
            Color.clear.frame(width: 16)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 14, topTrailing: 14))
                .fill(p.surfaceMuted)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    private func colLabel(_ s: String, width: CGFloat?, align: Alignment) -> some View {
        Text(s)
            .font(.ui(size: 11, weight: .semibold))
            .foregroundColor(p.ink50)
            .textCase(.uppercase)
            .tracking(0.4)
            .frame(maxWidth: width.map { _ in nil } ?? .infinity, alignment: align)
            .frame(width: width, alignment: align)
    }

    private func rowView(entry: MinutesEntry, isAlt: Bool) -> some View {
        let isPinned = pinned.isPinned(entry.id)
        let hover = hoverID == entry.id
        return Button {
            selected = entry
        } label: {
            HStack(spacing: 0) {
                Button {
                    pinned.toggle(entry.id)
                } label: {
                    Image(systemName: isPinned ? "star.fill" : "star")
                        .font(.system(size: 12, weight: isPinned ? .bold : .regular))
                        .foregroundColor(isPinned ? p.accent : p.ink35)
                }
                .buttonStyle(.plain)
                .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.ui(size: 13, weight: .semibold))
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let label = entry.templateLabel {
                            Text(label)
                                .font(.ui(size: 10, weight: .semibold))
                                .foregroundColor(p.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(p.accentSoft)
                                )
                        }
                        if let src = entry.sourceFileName {
                            Text(src)
                                .font(.mono(size: 11))
                                .foregroundColor(p.ink50)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(DateFormatters.long(entry.createdAt))
                    .font(.ui(size: 12))
                    .foregroundColor(p.ink70)
                    .frame(width: 130, alignment: .leading)

                Text(entry.elapsedSeconds.map { TranscriptExporter.formatTime($0) } ?? "—")
                    .font(.mono(size: 12))
                    .foregroundColor(p.ink70)
                    .frame(width: 90, alignment: .leading)

                speakerCluster(entry)
                    .frame(width: 110, alignment: .leading)

                HStack(spacing: 6) {
                    Text("\(entry.decisionCount)")
                        .font(.ui(size: 12, weight: .semibold))
                        .foregroundColor(p.decision)
                    Text("·")
                        .foregroundColor(p.ink35)
                    Text("\(entry.actionCount)")
                        .font(.ui(size: 12, weight: .semibold))
                        .foregroundColor(p.action)
                }
                .frame(width: 110, alignment: .leading)

                rowMoreMenu(entry: entry, hover: hover)
                    .frame(width: 16)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(hover ? p.surface : (isAlt ? p.surfaceMuted.opacity(0.4) : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { h in hoverID = h ? entry.id : (hoverID == entry.id ? nil : hoverID) }
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 0.5)
        }
    }

    private func rowMoreMenu(entry: MinutesEntry, hover: Bool) -> some View {
        Menu {
            Button("외부 앱으로 열기") {
                NSWorkspace.shared.open(entry.url)
            }
            Button("Finder에서 보기") {
                NSWorkspace.shared.activateFileViewerSelecting([entry.url])
            }
            Divider()
            Button(pinned.isPinned(entry.id) ? "고정 해제" : "고정") {
                pinned.toggle(entry.id)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(p.ink50)
                .frame(width: 22, height: 22)
                .opacity(hover ? 1 : 0)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func speakerCluster(_ entry: MinutesEntry) -> some View {
        let count = entry.speakerCount ?? estimatedSpeakerCount(for: entry)
        let display = min(count, 4)
        return HStack(spacing: -6) {
            ForEach(0..<display, id: \.self) { i in
                speakerAvatar(id: i)
            }
            if count > display {
                Text("+\(count - display)")
                    .font(.mono(size: 10, weight: .semibold))
                    .foregroundColor(p.ink70)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(p.surfaceMuted)
                    )
                    .overlay(Circle().stroke(p.line, lineWidth: 0.5))
            }
        }
    }

    private func speakerAvatar(id: Int) -> some View {
        ZStack {
            Circle()
                .fill(SpeakerPalette.color(for: id))
                .frame(width: 22, height: 22)
            Text(initialFor(id))
                .font(.ui(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .overlay(Circle().stroke(p.surface, lineWidth: 1.5))
    }

    private func estimatedSpeakerCount(for entry: MinutesEntry) -> Int {
        // 메타데이터에 정보가 없으면 결정·액션 수에 비례한 보조 추정 (단순)
        max(1, min(6, (entry.decisionCount + entry.actionCount) / 4))
    }

    private func initialFor(_ id: Int) -> String {
        // 라이브러리는 실제 화자 이름을 모르므로 알파벳 이니셜
        let chars = ["김", "박", "이", "정", "최", "윤", "장", "한"]
        return chars[id % chars.count]
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(p.ink35)
            Text("처리된 회의록이 없습니다")
                .font(.ui(size: 14, weight: .semibold))
                .foregroundColor(p.ink70)
            Text("음성 메모를 끌어다 놓으면 여기에서 한 번에 볼 수 있어요")
                .font(.ui(size: 12))
                .foregroundColor(p.ink50)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, decisionAction, basic, interview, pinned
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "전체"
        case .decisionAction: return "결정·액션"
        case .basic: return "기본"
        case .interview: return "고객 인터뷰"
        case .pinned: return "고정됨"
        }
    }
}
