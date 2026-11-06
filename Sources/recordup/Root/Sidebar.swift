import SwiftUI

struct Sidebar: View {
    @Binding var selected: SidebarItem
    let recents: [MinutesEntry]
    let onPickRecent: (MinutesEntry) -> Void

    @Environment(\.palette) private var p
    @ObservedObject private var pinned = PinnedStore.shared

    var body: some View {
        ZStack {
            p.sidebar
            VStack(spacing: 0) {
                logo
                navList
                recentsList
                Spacer(minLength: 0)
                statusFooter
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(p.line).frame(width: 0.5)
        }
    }

    // MARK: - Logo

    private var logo: some View {
        HStack(alignment: .center, spacing: 10) {
            BrandMark(palette: p, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                BrandWordmark(palette: p, baseSize: 14)
                Text("온디바이스 전사 회의록")
                    .font(.ui(size: 9.5, weight: .semibold))
                    .foregroundColor(p.ink50)
                    .tracking(1.5)
                    .textCase(.uppercase)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Nav

    private var navList: some View {
        VStack(spacing: 1) {
            ForEach(SidebarItem.allCases) { item in
                navRow(item)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func navRow(_ item: SidebarItem) -> some View {
        let isActive = selected == item
        return Button {
            selected = item
        } label: {
            HStack(spacing: 9) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? p.accent : p.ink70)
                    .frame(width: 18)
                Text(item.label)
                    .font(.ui(size: 12.5, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? p.accent : p.ink70)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isActive ? p.accentSoft : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recents

    private var recentsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("최근 회의록")
                    .font(.ui(size: 11, weight: .semibold))
                    .foregroundColor(p.ink50)
                Spacer()
                Text("\(recents.count)")
                    .font(.mono(size: 11))
                    .foregroundColor(p.ink35)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 4)

            if recents.isEmpty {
                Text("아직 처리한 회의록이 없습니다")
                    .font(.ui(size: 11))
                    .foregroundColor(p.ink35)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 2) {
                    ForEach(recents) { entry in
                        recentRow(entry)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    private func recentRow(_ entry: MinutesEntry) -> some View {
        let isPinned = pinned.isPinned(entry.id)
        return Button {
            onPickRecent(entry)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(p.accent)
                        .frame(width: 4, height: 4)
                        .opacity(isPinned ? 1 : 0)
                    Text(entry.title)
                        .font(.ui(size: 12, weight: .semibold))
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    Text(DateFormatters.compact(entry.createdAt))
                        .font(.mono(size: 10))
                        .foregroundColor(p.ink50)
                    if let elapsed = entry.elapsedSeconds {
                        Text("·").foregroundColor(p.ink35)
                        Text(TranscriptExporter.formatTime(elapsed))
                            .font(.mono(size: 10))
                            .foregroundColor(p.ink50)
                    }
                    if let count = entry.speakerCount {
                        Text("·").foregroundColor(p.ink35)
                        Text("\(count)명")
                            .font(.ui(size: 10))
                            .foregroundColor(p.ink50)
                    }
                }
                .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status footer

    private var statusFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(p.success)
                .frame(width: 7, height: 7)
            Text("Claude Max · 전사 온디바이스")
                .font(.ui(size: 11))
                .foregroundColor(p.ink50)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
