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

    @Environment(\.isWideLayout) private var isWide

    var body: some View {
        Group {
            if isWide {
                // iPhone Duo inner display: the pitch on the left, the sign-in form on the right.
                GeometryReader { proxy in
                    ScrollView {
                        HStack(alignment: .center, spacing: 64) {
                            header.frame(maxWidth: .infinity, alignment: .leading)
                            signInForm.frame(width: 380)
                        }
                        .padding(.horizontal, Theme.Space.xxl)
                        .frame(minHeight: proxy.size.height)
                        .readableWidth(1000)
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                        header
                            .padding(.top, 64)
                        signInForm
                    }
                    .padding(.horizontal, Theme.Space.xl)
                    .padding(.bottom, Theme.Space.xl)
                    .readableWidth()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView().controlSize(.large)
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxl) {
            VStack(spacing: Theme.Space.m) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await viewModel.handleApple(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                Button("Continue with Google") {
                    Task { await viewModel.signInWithGoogle() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            divider

            emailForm

            Text("One account for iOS and the web, with the same credits and videos")
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            KasumiLogo(markSize: 56)
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Turn a photo into a short video with a camera move")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Pick a preset like Dolly Zoom or describe the motion yourself")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var divider: some View {
        HStack(spacing: Theme.Space.m) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            Text("or").font(.footnote).foregroundStyle(Theme.textMuted)
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private var emailForm: some View {
        VStack(spacing: Theme.Space.m) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .inputFieldStyle()

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { Task { await viewModel.signInWithEmail() } }
                .inputFieldStyle()

            Button("Continue with email") {
                Task { await viewModel.signInWithEmail() }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!viewModel.canSubmitEmail)
        }
    }
}
