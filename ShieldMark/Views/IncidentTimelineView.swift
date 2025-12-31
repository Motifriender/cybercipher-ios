import SwiftUI

struct IncidentTimelineView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var events: [IncidentEvent] = []

    var body: some View {
        List {
            Section("Incident Timeline") {
                if events.isEmpty {
                    Text("No incidents yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.kind.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text(event.timestamp.formatted(date: .numeric, time: .standard))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.message)
                                .font(.subheadline)

                            if !event.metadata.isEmpty {
                                Text(event.metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " • "))
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Timeline")
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        events = await container.incidentLogger.listNewestFirst()
    }
}

#Preview {
    NavigationStack { IncidentTimelineView() }
        .environmentObject(AppContainer())
}

