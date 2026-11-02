import PhotosUI
import SwiftUI

struct CreateView: View {
    let app: AppModel
    @State private var viewModel: CreateViewModel
    @State private var showCamera = false
    @Environment(\.isWideLayout) private var isWide

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: CreateViewModel(app: app))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isWide {
                    // iPhone Duo inner display: the photo on the left, the controls on the right.
                    HStack(alignment: .top, spacing: Theme.Space.xl) {
                        photoSection
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        ScrollView {
                            controls
                        }
                        .frame(width: 380)
                    }
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, Theme.Space.s)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                            if !app.generations.active.isEmpty {
                                inProgressSection
                            }
                            photoSection
                            presetSection
                            promptSection
                            generateButton
                        }
                        .padding(.horizontal, Theme.Space.l)
                        .padding(.vertical, Theme.Space.s)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .navigationTitle("Create")
            .creditsToolbar(app.user?.credits)
        }
        .task {
            await viewModel.loadPresets()
            if DemoScreen.current == .create { await viewModel.prepareDemo() }
        }
        .task(id: app.draftPreset) {
            guard let preset = app.draftPreset else { return }
            viewModel.selectedPreset = preset
            app.draftPreset = nil
        }
        .onChange(of: viewModel.pickerItem) {
            Task { await viewModel.loadPickedImage() }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { viewModel.image = $0 }
                .ignoresSafeArea()
        }
        .errorAlert($viewModel.errorMessage)
    }

    // MARK: - Sections

    private var controls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxl) {
            if !app.generations.active.isEmpty {
                inProgressSection
            }
            presetSection
            promptSection
            generateButton
        }
        .padding(.bottom, Theme.Space.l)
    }

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            SectionHeader(title: "Rendering")
            VStack(spacing: Theme.Space.s) {
                ForEach(app.generations.active) { generation in
                    ActiveGenerationRow(generation: generation)
                }
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let image = viewModel.image {
            Color.clear
                .frame(height: isWide ? nil : 320)
                .overlay {
                    Image(uiImage: image).resizable().scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
                .overlay { ViewfinderMarks() }
                .overlay(alignment: .bottom) {
                    Button { viewModel.removeImage() } label: {
                        Text("Replace")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, Theme.Space.m)
                            .frame(height: 32)
                            .background(Theme.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, Theme.Space.l)
                }
        } else {
            VStack(spacing: Theme.Space.l) {
                if viewModel.isLoadingImage {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Theme.textMuted)
                }
                VStack(spacing: Theme.Space.xs) {
                    Text("Add a photo")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Portraits and landscapes work best")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: Theme.Space.m) {
                    PhotosPicker(selection: $viewModel.pickerItem, matching: .images) {
                        Text("Choose photo")
                    }
                    .buttonStyle(SecondaryButtonStyle(height: 40))

                    Button("Take photo") { showCamera = true }
                        .buttonStyle(SecondaryButtonStyle(height: 40))
                        .disabled(!CameraPicker.isAvailable)
                }
            }
            .padding(Theme.Space.xl)
            .frame(maxWidth: .infinity, minHeight: 240, maxHeight: isWide ? .infinity : nil)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Camera move")
                if let preset = viewModel.selectedPreset {
                    Text("\(preset.cost) credits")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Space.s) {
                    ForEach(viewModel.presets) { preset in
                        let isSelected = viewModel.selectedPreset == preset
                        Button { viewModel.toggle(preset) } label: {
                            PresetCard(preset: preset, showsDetails: false)
                                .frame(width: 96, height: 128)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                        .strokeBorder(Theme.accent, lineWidth: isSelected ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Prompt")
                Text("\(viewModel.prompt.count) / \(viewModel.maxPromptLength)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(viewModel.isPromptTooLong ? Theme.negative : Theme.textMuted)
            }
            TextField("Describe the motion or light", text: $viewModel.prompt, axis: .vertical)
                .lineLimit(3...6)
                .inputFieldStyle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.s) {
                    ForEach(viewModel.promptSuggestions, id: \.self) { suggestion in
                        Button(suggestion) { viewModel.prompt = suggestion }
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, Theme.Space.m)
                            .frame(height: 32)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.hairline))
                            .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var generateButton: some View {
        VStack(spacing: Theme.Space.s) {
            Button {
                Task { await viewModel.generate() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView().tint(Theme.background)
                } else {
                    HStack(spacing: Theme.Space.s) {
                        Text("Generate")
                        Text("\(viewModel.cost) credits")
                            .monospacedDigit()
                            .opacity(0.6)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canGenerate)

            if let hint = viewModel.hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

struct ActiveGenerationRow: View {
    let generation: Generation

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            ProgressRing(progress: generation.progress)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(generation.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(generation.status.label)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text("\(Int(generation.progress * 100))%")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText(value: generation.progress))
                .animation(Theme.ease(0.3), value: generation.progress)
        }
        .padding(Theme.Space.m)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))
        .accessibilityElement(children: .combine)
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Theme.raised, lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.ease(0.4), value: progress)
        }
    }
}
