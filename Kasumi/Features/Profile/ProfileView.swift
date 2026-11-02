import SwiftUI

struct ProfileView: View {
    let app: AppModel
    @State private var showStore = DemoScreen.current == .store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.xl) {
                    if let user = app.user {
                        GroupedSection {
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
                                Spacer()
                            }
                            .padding(Theme.Space.l)
                        }

                        GroupedSection(header: "Balance") {
                            ValueRow(title: "Credits", value: "\(user.credits)", mono: true)
                            RowDivider()
                            ValueRow(title: "Plan", value: user.plan.title)
                            if app.config.storeEnabled {
                                RowDivider()
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
                                    .padding(.horizontal, Theme.Space.l)
                                    .frame(minHeight: 48)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    GroupedSection(
                        header: "Remote config",
                        footer: "Feature flags come from the server and change without an app update"
                    ) {
                        ValueRow(title: "Live Activities", value: app.config.liveActivitiesEnabled ? "On" : "Off")
                        RowDivider()
                        ValueRow(title: "Store", value: app.config.storeEnabled ? "On" : "Off")
                        RowDivider()
                        ValueRow(title: "Max prompt length", value: "\(app.config.maxPromptLength)", mono: true)
                    }

                    GroupedSection {
                        Button {
                            app.signOut()
                        } label: {
                            Text("Sign out")
                                .foregroundStyle(Theme.negative)
                                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                .padding(.horizontal, Theme.Space.l)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.s)
            }
            .screenBackground()
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showStore) {
                StoreView(app: app)
            }
        }
    }
}
