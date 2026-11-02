import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    var canSubmitEmail: Bool {
        email.contains("@") && password.count >= 6 && !isLoading
    }

    func handleApple(_ result: Result<ASAuthorization, any Error>) async {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Sign in with Apple returned no identity token."
                return
            }
            await signIn(.apple(identityToken: token))
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = "Sign in with Apple needs a signed build with the capability enabled. Use email or Google in the demo."
            app.crashReporter.record(error, context: "apple-sign-in")
        }
    }

    func signInWithGoogle() async {
        // Production: GIDSignIn.sharedInstance.signIn(withPresenting:) returns an ID token for the backend.
        await signIn(.google(idToken: "demo-google-id-token"))
    }

    func signInWithEmail() async {
        guard canSubmitEmail else { return }
        await signIn(.email(email.trimmingCharacters(in: .whitespaces), password: password))
    }

    private func signIn(_ provider: AuthProvider) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await app.signIn(provider)
        } catch {
            errorMessage = error.localizedDescription
            app.crashReporter.record(error, context: "sign-in")
        }
    }
}
