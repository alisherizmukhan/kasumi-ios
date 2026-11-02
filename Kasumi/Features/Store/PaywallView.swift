import SwiftUI

/// Kasumi Pro subscription offer.
struct PaywallView: View {
    @State private var viewModel: StoreViewModel
    @State private var selectedID: String?
    @Environment(\.dismiss) private var dismiss

    init(app: AppModel) {
        _viewModel = State(initialValue: StoreViewModel(app: app))
    }

    private var selected: StoreProduct? {
        viewModel.subscriptions.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            // Measures its own width: as a sheet it is narrower than the window.
            GeometryReader { proxy in
            let isWide = proxy.size.width >= LayoutMetrics.wideThreshold
            ScrollView {
                Group {
                    if isWide {
                        HStack(alignment: .top, spacing: Theme.Space.xxl * 1.5) {
                            pitch.frame(maxWidth: .infinity, alignment: .leading)
                            purchase.frame(width: 360)
                        }
                        .readableWidth(880)
                    } else {
                        VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                            pitch
                            purchase
                        }
                        .readableWidth()
                    }
                }
                .padding(Theme.Space.l)
            }
            }
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .task {
            await viewModel.load()
            if selectedID == nil {
                selectedID = viewModel.subscriptions.last?.id
            }
        }
        .sheet(item: $viewModel.completedPurchase) { purchase in
            PurchaseSuccessView(purchase: purchase) {
                viewModel.completedPurchase = nil
                dismiss()
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    // MARK: - Sections

    private var pitch: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            KasumiMark()
                .fill(Theme.accent)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Kasumi Pro")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("For people who post every week")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                benefit("\(StoreCatalog.proMonthlyCredits) credits every month", detail: "About 20 videos with presets", icon: "square.stack")
                benefit("Priority rendering", detail: "Your videos skip the free queue", icon: "clock")
                benefit("Export in 1080p", detail: "Free plan exports in 720p", icon: "film")
            }
        }
    }

    private var purchase: some View {
        VStack(spacing: Theme.Space.l) {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            } else if viewModel.subscriptions.isEmpty {
                GroupedSection {
                    ContentUnavailableView(
                        "Plans unavailable",
                        systemImage: "cart",
                        description: Text("Run from Xcode with Products.storekit to test purchases")
                    )
                }
            } else {
                VStack(spacing: Theme.Space.s) {
                    ForEach(viewModel.subscriptions) { plan in
                        PlanOption(
                            plan: plan,
                            savings: plan.kind == .subscription(.year) ? viewModel.yearlySavings : nil,
                            isSelected: plan.id == selectedID
                        ) {
                            selectedID = plan.id
                        }
                    }
                }

                Button {
                    guard let selected else { return }
                    Task { await viewModel.buy(selected) }
                } label: {
                    if viewModel.purchasingID != nil {
                        ProgressView().tint(Theme.background)
                    } else {
                        Text("Subscribe")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selected == nil || viewModel.purchasingID != nil || viewModel.isPro)

                Text(viewModel.isPro ? "You're already on Kasumi Pro" : "Renews automatically. Cancel anytime in Settings at least a day before renewal")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await viewModel.restorePurchases() }
                } label: {
                    if viewModel.isRestoring {
                        ProgressView()
                    } else {
                        Text("Restore purchases")
                    }
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func benefit(_ title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.footnote).foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PlanOption: View {
    let plan: StoreProduct
    let savings: Int?
    let isSelected: Bool
    let onSelect: @MainActor () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Space.m) {
                Circle()
                    .strokeBorder(isSelected ? Theme.accent : Theme.textMuted, lineWidth: isSelected ? 6 : 1.5)
                    .frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Space.s) {
                        Text(title).font(.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
                        if let savings {
                            Text("Save \(savings)%")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 6)
                                .frame(height: 20)
                                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    Text(caption)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(Theme.Space.l)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: String {
        plan.kind == .subscription(.year) ? "Yearly" : "Monthly"
    }

    private var caption: String {
        if plan.kind == .subscription(.year) {
            return "\(plan.displayPrice) a year, \(plan.formatted(plan.price / 12)) a month"
        }
        return "\(plan.displayPrice) a month"
    }
}
