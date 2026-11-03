import SwiftUI

struct SettingsView: View {
    let app: AppModel

    @AppStorage(AppSettings.notifyWhenReadyKey) private var notifyWhenReady = true
    @AppStorage(AppSettings.liveActivitiesKey) private var liveActivities = true
    @AppStorage(AppSettings.autoSaveKey) private var autoSave = false
    @AppStorage(AppSettings.exportQualityKey) private var exportQuality = "720p"
    @State private var confirmDelete = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var isPro: Bool { app.user?.plan == .pro }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                GroupedSection(
                    header: "While a video renders",
                    footer: "Rendering takes a few minutes, so you can leave the app and come back"
                ) {
                    ToggleRow(title: "Notify when ready", isOn: $notifyWhenReady)
                    RowDivider()
                    ToggleRow(title: "Live Activity on the Lock Screen", isOn: $liveActivities)
                        .disabled(!app.config.liveActivitiesEnabled)
                }

                GroupedSection(
                    header: "Videos",
                    footer: isPro ? nil : "1080p export comes with Kasumi Pro"
                ) {
                    HStack {
                        Text("Export quality").foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Menu {
                            Button("720p") { exportQuality = "720p" }
                            Button("1080p") { exportQuality = "1080p" }
                                .disabled(!isPro)
                        } label: {
                            HStack(spacing: Theme.Space.xs) {
                                Text(exportQuality).monospacedDigit()
                                Image(systemName: "chevron.up.chevron.down").font(.caption)
                            }
                            .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, Theme.Space.l)
                    .frame(minHeight: 48)
                    RowDivider()
                    ToggleRow(title: "Save new videos to Photos", isOn: $autoSave)
                }

                GroupedSection(header: "About") {
                    ValueRow(title: "Version", value: Self.version, mono: true)
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

                GroupedSection(footer: "Deletes your videos, credits and account data. Active subscriptions are managed by Apple and need to be cancelled in Settings") {
                    Button {
                        confirmDelete = true
                    } label: {
                        HStack {
                            Text("Delete account").foregroundStyle(Theme.negative)
                            Spacer()
                            if isDeleting { ProgressView() }
                        }
                        .padding(.horizontal, Theme.Space.l)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                }
            }
            .readableWidth()
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.s)
        }
        .screenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your Kasumi account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Your videos and remaining credits will be removed. This can't be undone")
        }
        .errorAlert($errorMessage)
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await app.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}
