import SwiftUI

/// Credit packs, plus a way into Kasumi Pro.
struct StoreView: View {
    let app: AppModel
    @State private var viewModel: StoreViewModel
    @State private var showPaywall = false
    @Environment(\.isWideLayout) private var isWide

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: StoreViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("\(viewModel.credits)")
                        .font(.system(size: 40, weight: .medium).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: Double(viewModel.credits)))
                    Text("Credits on your account")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.Space.l)
                .animation(Theme.ease(0.3), value: viewModel.credits)

                GroupedSection(
                    header: "Credit packs",
                    footer: "Payments go through Apple. Credits are added to your Kasumi account and work on the web too."
                ) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 96)
                    } else if viewModel.creditPacks.isEmpty {
                        ContentUnavailableView(
                            "Store unavailable",
                            systemImage: "cart",
                            description: Text("Run from Xcode with Products.storekit to test purchases")
                        )
                    } else {
                        ForEach(Array(viewModel.creditPacks.enumerated()), id: \.element.id) { index, pack in
                            if index > 0 { RowDivider() }
                            packRow(pack)
                        }
                    }
                }

                if !viewModel.isPro {
                    GroupedSection(header: "Subscription") {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: Theme.Space.m) {
                                KasumiMark()
                                    .fill(Theme.accent)
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Kasumi Pro").font(.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
                                    Text("\(StoreCatalog.proMonthlyCredits) credits every month and priority rendering")
                                        .font(.footnote)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(Theme.Space.l)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .readableWidth()
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.s)
        }
        .screenBackground()
        .navigationTitle("Buy credits")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            if DemoScreen.current == .purchased, viewModel.completedPurchase == nil, let pack = viewModel.creditPacks.first {
                await viewModel.buy(pack)
            }
        }
        .sheet(item: $viewModel.completedPurchase) { purchase in
            PurchaseSuccessView(purchase: purchase) {
                viewModel.completedPurchase = nil
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(app: app)
        }
        .errorAlert($viewModel.errorMessage)
    }

    private func packRow(_ pack: StoreProduct) -> some View {
        HStack(spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(pack.description)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                Task { await viewModel.buy(pack) }
            } label: {
                if viewModel.purchasingID == pack.id {
                    ProgressView()
                } else {
                    Text(pack.displayPrice).monospacedDigit()
                }
            }
            .buttonStyle(SecondaryButtonStyle(height: 36))
            .frame(width: 96)
            .disabled(viewModel.purchasingID != nil)
        }
        .padding(Theme.Space.l)
    }
}
