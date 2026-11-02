import SwiftUI

struct ProfileView: View {
    let app: AppModel
    @State private var showStore = DemoScreen.current == .store

    var body: some View {
        NavigationStack {
            List {
                if let user = app.user {
                    Section {
                        HStack(spacing: 14) {
                            Text(user.initials)
                                .font(.title3.bold())
                                .frame(width: 56, height: 56)
                                .background(Theme.gradient, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name).font(.headline)
                                if let email = user.email {
                                    Text(email).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Balance") {
                        LabeledContent("Credits") { CreditsBadge(credits: user.credits) }
                        LabeledContent("Plan", value: user.plan.title)
                        if app.config.storeEnabled {
                            Button {
                                showStore = true
                            } label: {
                                Label("Get more credits", systemImage: "bolt.badge.plus")
                            }
                        }
                    }
                }

                Section {
                    LabeledContent("Live Activities", value: app.config.liveActivitiesEnabled ? "On" : "Off")
                    LabeledContent("Store", value: app.config.storeEnabled ? "On" : "Off")
                    LabeledContent("Max prompt length", value: "\(app.config.maxPromptLength)")
                } header: {
                    Text("Remote config")
                } footer: {
                    Text("Feature flags come from the server and can change without an app update.")
                }

                Section {
                    Button("Sign out", role: .destructive) { app.signOut() }
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showStore) {
                StoreView(app: app)
            }
        }
    }
}
