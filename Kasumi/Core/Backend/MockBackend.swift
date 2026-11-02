import Foundation

/// In-memory backend for the demo build and tests. Simulates network latency
/// and a generation that takes `generationDuration` seconds to render.
actor MockBackend: Backend {
    private let latency: Duration
    private let generationDuration: TimeInterval
    private var user: User
    private var generations: [Generation]
    private var startDates: [String: Date] = [:]

    init(latency: Duration = .milliseconds(500), generationDuration: TimeInterval = 20) {
        self.latency = latency
        self.generationDuration = generationDuration
        user = User(id: "user_demo", name: "Alex Rivera", email: "alex@kasumi.app", credits: 120, plan: .free)
        generations = Self.seedLibrary()
    }

    func signIn(with provider: AuthProvider) async throws -> AuthSession {
        try await delay()
        if case let .email(email, password) = provider {
            guard email.contains("@"), password.count >= 6 else { throw BackendError.invalidCredentials }
            user.email = email
        }
        return AuthSession(accessToken: "mock-access-\(UUID().uuidString)", refreshToken: "mock-refresh", user: user)
    }

    func currentUser() async throws -> User {
        try await delay()
        return user
    }

    func homeScreen() async throws -> HomeScreen {
        try await delay()
        return try Self.bundledHomeScreen()
    }

    func remoteConfig() async throws -> RemoteConfig {
        try await delay()
        return RemoteConfig()
    }

    func startGeneration(_ request: GenerationRequest) async throws -> Generation {
        try await delay()
        let preset = try? Self.bundledHomeScreen().allPresets.first { $0.id == request.presetID }
        let cost = preset?.cost ?? Pricing.promptOnlyCost
        guard user.credits >= cost else { throw BackendError.insufficientCredits }
        user.credits -= cost

        let generation = Generation(
            id: UUID().uuidString,
            prompt: request.prompt,
            presetTitle: preset?.title,
            status: .queued,
            progress: 0,
            thumbnailURL: nil,
            videoURL: nil,
            createdAt: .now
        )
        generations.insert(generation, at: 0)
        startDates[generation.id] = .now
        return generation
    }

    func generation(id: String) async throws -> Generation {
        guard let index = generations.firstIndex(where: { $0.id == id }) else { throw BackendError.notFound }
        generations[index] = advanced(generations[index])
        return generations[index]
    }

    func library() async throws -> [Generation] {
        try await delay()
        generations = generations.map { advanced($0) }
        return generations
    }

    func redeemPurchase(productID: String, transactionID: UInt64) async throws -> User {
        try await delay()
        switch productID {
        case "kasumi.credits.100": user.credits += 100
        case "kasumi.credits.500": user.credits += 500
        case "kasumi.pro.monthly":
            user.plan = .pro
            user.credits += 300
        default: throw BackendError.notFound
        }
        return user
    }

    // MARK: - Simulation

    private func delay() async throws {
        if latency > .zero { try await Task.sleep(for: latency) }
    }

    /// Moves a generation forward based on how long ago it was started.
    private func advanced(_ generation: Generation) -> Generation {
        guard !generation.isFinished, let start = startDates[generation.id] else { return generation }
        var updated = generation
        let progress = min(Date().timeIntervalSince(start) / generationDuration, 1)
        updated.progress = progress
        updated.status = progress < 0.1 ? .queued : (progress < 1 ? .processing : .completed)
        if updated.status == .completed {
            let index = generation.id.utf8.reduce(0) { $0 &+ Int($1) } % Self.samples.count
            let sample = Self.samples[index]
            updated.videoURL = sample.video
            updated.thumbnailURL = sample.thumbnail
        }
        return updated
    }

    private static func bundledHomeScreen() throws -> HomeScreen {
        guard let url = Bundle.main.url(forResource: "home", withExtension: "json") else {
            throw BackendError.notFound
        }
        return try JSONDecoder().decode(HomeScreen.self, from: Data(contentsOf: url))
    }

    // MARK: - Sample content

    private struct Sample: Sendable {
        let video: URL
        let thumbnail: URL
    }

    private static let samples: [Sample] = [
        sample(video: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4", seed: "blaze"),
        sample(video: "https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_2MB.mp4", seed: "escape"),
        sample(video: "https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4", seed: "fun"),
        sample(video: "https://download.samplelib.com/mp4/sample-10s.mp4", seed: "joyride"),
    ]

    private static func sample(video: String, seed: String) -> Sample {
        Sample(
            video: URL(string: video)!,
            thumbnail: URL(string: "https://picsum.photos/seed/\(seed)/600/800")!
        )
    }

    private static func seedLibrary() -> [Generation] {
        let seeds: [(preset: String, prompt: String)] = [
            ("Earth Zoom Out", "Pull back to orbit"),
            ("Neon Glow", "Night city, rain"),
            ("Dolly Zoom", ""),
        ]
        return seeds.indices.map { index in
            let sample = samples[index % samples.count]
            return Generation(
                id: "seed_\(index)",
                prompt: seeds[index].prompt,
                presetTitle: seeds[index].preset,
                status: .completed,
                progress: 1,
                thumbnailURL: sample.thumbnail,
                videoURL: sample.video,
                createdAt: Date().addingTimeInterval(TimeInterval(-3600 * (index + 1)))
            )
        }
    }
}
