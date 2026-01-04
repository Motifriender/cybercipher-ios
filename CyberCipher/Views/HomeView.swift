import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CreateProofView()
            }
            .tabItem { Label("Create", systemImage: "checkmark.seal") }

            NavigationStack {
                VerifyProofView()
            }
            .tabItem { Label("Verify", systemImage: "magnifyingglass") }

            NavigationStack {
                LockdownView()
            }
            .tabItem { Label("Lockdown", systemImage: "exclamationmark.shield") }

            NavigationStack {
                IncidentTimelineView()
            }
            .tabItem { Label("Incidents", systemImage: "clock") }

            NavigationStack {
                RecoveryAssistantView()
            }
            .tabItem { Label("Recovery", systemImage: "sparkles") }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppContainer())
}

