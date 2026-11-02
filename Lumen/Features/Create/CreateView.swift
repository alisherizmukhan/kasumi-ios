import PhotosUI
import SwiftUI

struct CreateView: View {
    let app: AppModel
    @State private var viewModel: CreateViewModel
    @State private var showCamera = false

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: CreateViewModel(app: app))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !app.generations.active.isEmpty {
                        inProgressSection
                    }
                    photoSection
                    presetSection
                    promptSection
                    generateButton
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
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

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "In progress")
            ForEach(app.generations.active) { generation in
                ActiveGenerationRow(generation: generation)
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let image = viewModel.image {
            Color.clear
                .frame(height: 320)
                .overlay {
                    Image(uiImage: image).resizable().scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Button { viewModel.removeImage() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding(10)
                    .accessibilityLabel("Remove photo")
                }
        } else {
            VStack(spacing: 16) {
                if viewModel.isLoadingImage {
                    ProgressView().controlSize(.large)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.gradient)
                }
                Text("Add a photo to animate")
                    .font(.headline)
                HStack(spacing: 12) {
                    PhotosPicker(selection: $viewModel.pickerItem, matching: .images) {
                        Label("Gallery", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    Button { showCamera = true } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!CameraPicker.isAvailable)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Preset")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.presets) { preset in
                        let isSelected = viewModel.selectedPreset == preset
                        Button { viewModel.toggle(preset) } label: {
                            PresetCard(preset: preset)
                                .frame(width: 96, height: 132)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Theme.accent, lineWidth: isSelected ? 3 : 0)
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Prompt")
            TextField("Describe the motion, light or mood…", text: $viewModel.prompt, axis: .vertical)
                .lineLimit(3...6)
                .inputFieldStyle()

            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.promptSuggestions, id: \.self) { suggestion in
                            Button(suggestion) { viewModel.prompt = suggestion }
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Theme.card, in: Capsule())
                                .buttonStyle(.plain)
                        }
                    }
                }
                Text("\(viewModel.prompt.count)/\(viewModel.maxPromptLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(viewModel.isPromptTooLong ? Color.red : Color.secondary)
            }
        }
    }

    private var generateButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.generate() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Generate")
                        Text("·").foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "bolt.fill").font(.subheadline)
                        Text("\(viewModel.cost)")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canGenerate)

            if let hint = viewModel.hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ActiveGenerationRow: View {
    let generation: Generation

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Theme.gradient)
                .symbolEffect(.pulse, isActive: !generation.isFinished)
                .frame(width: 44, height: 44)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(generation.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Text("\(Int(generation.progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: generation.progress)
                    .tint(Theme.accent)
                Text(generation.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
