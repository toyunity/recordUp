import Foundation

struct ReleaseNote: Codable, Identifiable {
    let version: String
    let build: String?
    let date: String
    let highlight: String?
    let items: [String]

    var id: String { version }
}

enum ReleaseNotesStore {
    static func loadAll() -> [ReleaseNote] {
        guard let url = Bundle.main.url(forResource: "release-notes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let notes = try? decoder.decode([ReleaseNote].self, from: data) else {
            return []
        }
        return notes.sorted { lhs, rhs in
            lhs.version.compare(rhs.version, options: .numeric) == .orderedDescending
        }
    }
}
