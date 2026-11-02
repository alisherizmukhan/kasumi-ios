import Foundation

/// In-memory backend for the demo build and tests. Simulates network latency
/// and a generation that takes `generationDuration` seconds to render.
actor MockBackend: Backend {
    private let latency: Duration
    private let generationDuration: TimeInterval
    private var user: User
    private var generations: [Generation]
    private var startDates: [String: Date] = [:]
    private var billing: [BillingEntry]

    init(latency: Duration = .milliseconds(500), generationDuration: TimeInterval = 20) {
        self.latency = latency
        self.generationDuration = generationDuration
        user = User(id: "user_demo", name: "Alex Rivera", email: "alex@kasumi.app", credits: 120, plan: .free)
        generations = Self.seedLibrary()
        billing = Self.seedBilling()
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
        record(.generation, title: generation.title, credits: -cost)
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
        case "kasumi.credits.100":
            user.credits += 100
            record(.purchase, title: "100 credits", credits: 100, price: "$4.99")
        case "kasumi.credits.500":
            user.credits += 500
            record(.purchase, title: "500 credits", credits: 500, price: "$19.99")
        case "kasumi.pro.monthly":
            user.plan = .pro
            user.credits += 300
            record(.subscription, title: "Kasumi Pro, monthly", credits: 300, price: "$9.99")
        case "kasumi.pro.yearly":
            user.plan = .pro
            user.credits += 300
            record(.subscription, title: "Kasumi Pro, yearly", credits: 300, price: "$79.99")
        default:
            throw BackendError.notFound
        }
        return user
    }

    func billingHistory() async throws -> [BillingEntry] {
        try await delay()
        return billing
    }

    func deleteAccount() async throws {
        try await delay()
    }

    // MARK: - Simulation

    private func record(_ kind: BillingEntry.Kind, title: String, credits: Int, price: String? = nil) {
        let entry = BillingEntry(id: UUID().uuidString, date: .now, kind: kind, title: title, credits: credits, price: price)
        billing.insert(entry, at: 0)
    }

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

    /// Adds up to the starting balance of 120 credits.
    private static func seedBilling() -> [BillingEntry] {
        func entry(_ id: String, hoursAgo: Double, _ kind: BillingEntry.Kind, _ title: String, _ credits: Int, _ price: String? = nil) -> BillingEntry {
            BillingEntry(id: id, date: Date().addingTimeInterval(-hoursAgo * 3600), kind: kind, title: title, credits: credits, price: price)
        }
        return [
            entry("b5", hoursAgo: 1, .generation, "Earth Zoom Out", -20),
            entry("b4", hoursAgo: 2, .generation, "Neon Glow", -15),
            entry("b3", hoursAgo: 3, .generation, "Dolly Zoom", -15),
            entry("b2", hoursAgo: 30, .purchase, "100 credits", 100, "$4.99"),
            entry("b1", hoursAgo: 24 * 40, .bonus, "Welcome credits", 70),
        ]
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
