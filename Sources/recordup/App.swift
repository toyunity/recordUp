import SwiftUI

extension Notification.Name {
    static let openSidebarNewRecord = Notification.Name("recordup.openSidebar.newRecord")
    static let openSidebarLibrary = Notification.Name("recordup.openSidebar.library")
    static let openSidebarSettings = Notification.Name("recordup.openSidebar.settings")
}

@main
struct RecordUpApp: App {
    @AppStorage(AppTheme.storageKey) private var themeRaw: String = AppTheme.warm.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .warm
    }

    init() {
        // 구 claudeBinaryPath → aiToolPath.claude 마이그레이션 (locate 호출 전에 1회).
        AIToolLocator.migrateLegacyClaudePathIfNeeded()
    }

    var body: some Scene {
        WindowGroup("record-up") {
            RootView()
                .frame(minWidth: 1100, minHeight: 720)
                .preferredColorScheme(theme == .dark ? .dark : .light)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("새 회의록") {
                    NotificationCenter.default.post(name: .openSidebarNewRecord, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("검색") {
                    NotificationCenter.default.post(name: .openSidebarLibrary, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("설정…") {
                    NotificationCenter.default.post(name: .openSidebarSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
