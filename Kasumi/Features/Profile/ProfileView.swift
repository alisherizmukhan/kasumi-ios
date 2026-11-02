import SwiftUI

struct ProfileView: View {
    let app: AppModel
    @State private var showStore = DemoScreen.current == .store

    var body: some View {
        NavigationStack {
            List {
                if let user = app.user {
                    Section {
                        HStack(spacing: Theme.Space.m) {
                            Text(user.initials)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 48, height: 48)
                                .background(Theme.raised, in: Circle())
                                .overlay(Circle().strokeBorder(Theme.hairline))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                                if let email = user.email {
                                    Text(email)
                                        .font(.footnote)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Space.xs)
                    }

                    Section {
                        row("Credits", value: "\(user.credits)", mono: true)
                        row("Plan", value: user.plan.title)
                        if app.config.storeEnabled {
                            Button {
                                showStore = true
                            } label: {
                                HStack {
                                    Text("Buy credits").foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                        }
                    } header: {
                        Text("Balance")
                    }
                    .textCase(nil)
                }

                Section {
                    row("Live Activities", value: app.config.liveActivitiesEnabled ? "On" : "Off")
                    row("Store", value: app.config.storeEnabled ? "On" : "Off")
                    row("Max prompt length", value: "\(app.config.maxPromptLength)", mono: true)
                } header: {
                    Text("Remote config")
                } footer: {
                    Text("Feature flags come from the server and change without an app update")
                }
                .textCase(nil)

                Section {
                    Button("Sign out") { app.signOut() }
                        .foregroundStyle(Theme.negative)
                }
            }
            .listStyle(.insetGrouped)
            .textCase(nil)
            .scrollContentBackground(.hidden)
            .listRowBackground(Theme.card)
            .screenBackground()
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showStore) {
                StoreView(app: app)
            }
        }
    }

    private func row(_ title: String, value: String, mono: Bool = false) -> some View {
        LabeledContent {
            Text(value)
                .font(mono ? .body.monospacedDigit() : .body)
                .foregroundStyle(Theme.textSecondary)
        } label: {
            Text(title).foregroundStyle(Theme.textPrimary)
        }
    }
}
