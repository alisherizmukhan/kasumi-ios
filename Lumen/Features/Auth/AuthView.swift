import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @State private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    init(app: AppModel) {
        _viewModel = State(initialValue: AuthViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                    .padding(.top, 48)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await viewModel.handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        Task { await viewModel.signInWithGoogle() }
                    } label: {
                        Label("Continue with Google", systemImage: "g.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                divider

                emailForm

                Text("One account for iOS and the web. Your credits and videos sync everywhere.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(backgroundGlow)
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView().controlSize(.large)
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.gradient)
            Text("Lumen")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("Turn any photo into a cinematic AI video")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Theme.cardBorder).frame(height: 1)
            Text("or").font(.footnote).foregroundStyle(.secondary)
            Rectangle().fill(Theme.cardBorder).frame(height: 1)
        }
    }

    private var emailForm: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .inputFieldStyle()

            SecureField("Password (6+ characters)", text: $viewModel.password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { Task { await viewModel.signInWithEmail() } }
                .inputFieldStyle()

            Button("Continue with email") {
                Task { await viewModel.signInWithEmail() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canSubmitEmail)
        }
    }

    private var backgroundGlow: some View {
        RadialGradient(
            colors: [Theme.accent.opacity(0.35), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 420
        )
        .ignoresSafeArea()
    }
}
