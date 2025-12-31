import Foundation

/// Append-only incident logger persisted locally (MVP).
actor IncidentLogger {
    private let storageURL: URL
    private var cached: [IncidentEvent] = []

    init(filename: String = "incidents.json") throws {
        let base = try AppPaths.applicationSupportDirectory()
        self.storageURL = base.appendingPathComponent(filename, isDirectory: false)
        self.cached = (try? Self.load(from: storageURL)) ?? []
    }

    func append(_ event: IncidentEvent) throws {
        cached.append(event)
        try Self.save(cached, to: storageURL)
    }

    func listNewestFirst(limit: Int? = nil) -> [IncidentEvent] {
        let sorted = cached.sorted { $0.timestamp > $1.timestamp }
        if let limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }

    // MARK: - Persistence

    private static func load(from url: URL) throws -> [IncidentEvent] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([IncidentEvent].self, from: data)
    }

    private static func save(_ events: [IncidentEvent], to url: URL) throws {
        let data = try JSONEncoder().encode(events)
        try data.write(to: url, options: [.atomic])
    }
}

