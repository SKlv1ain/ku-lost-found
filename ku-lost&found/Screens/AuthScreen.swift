import SwiftUI

struct AuthScreen: View {
    @Bindable var vm: AuthViewModel
    @FocusState private var focused: Field?

    private enum Field { case name, email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Hero ──
                VStack(spacing: 14) {
                    LostFoundLogo()
                        .scaleEffect(1.3)
                        .padding(.bottom, 4)

                    Text("KU Lost & Found")
                        .font(Font.Sarabun.bold(28))
                        .foregroundStyle(KUTheme.Palette.neutral900)

                    Rectangle()
                        .fill(KUTheme.Palette.accent500)
                        .frame(width: 48, height: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    Text("Report, search and reclaim\nyour belongings on campus.")
                        .font(Font.Sarabun.regular(15))
                        .foregroundStyle(KUTheme.Palette.neutral600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, 60)
                .padding(.bottom, 36)

                // ── Form card ──
                VStack(spacing: 16) {
                    // Tab toggle
                    modeToggle
                        .padding(.bottom, 4)

                    // Name (sign-up only)
                    if vm.isSignUp {
                        inputField(
                            icon: "person",
                            placeholder: "Full name",
                            text: $vm.fullName,
                            field: .name
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    inputField(
                        icon: "envelope",
                        placeholder: "Email address",
                        text: $vm.email,
                        field: .email,
                        keyboard: .emailAddress,
                        autocap: .never
                    )

                    inputField(
                        icon: "lock",
                        placeholder: "Password",
                        text: $vm.password,
                        field: .password,
                        isSecure: true
                    )

                    // Error
                    if let err = vm.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                            Text(err)
                                .font(Font.Sarabun.medium(13))
                        }
                        .foregroundStyle(KUTheme.Palette.accent500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                    }

                    // Submit
                    PrimaryButton(
                        label: vm.isBusy
                            ? "Please wait…"
                            : (vm.isSignUp ? "Create account" : "Sign in"),
                        icon: vm.isBusy ? nil : (vm.isSignUp ? "person.badge.plus" : "arrow.right"),
                        color: KUTheme.Palette.neutral900
                    ) {
                        focused = nil
                        Task {
                            if vm.isSignUp {
                                await vm.signUp()
                            } else {
                                await vm.signIn()
                            }
                        }
                    }
                    .disabled(vm.isBusy)
                    .opacity(vm.isBusy ? 0.6 : 1)
                }
                .padding(20)
                .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous)
                        .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.25), value: vm.isSignUp)
                .animation(.easeOut(duration: 0.2), value: vm.errorMessage)

                // ── Divider ──
                HStack(spacing: 12) {
                    Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
                    Text("or")
                        .font(Font.Sarabun.regular(13))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                    Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // ── Google button ──
                googleButton
                    .padding(.horizontal, 20)

                // ── Footer ──
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Circle().fill(KUTheme.Palette.primary700).frame(width: 6, height: 6)
                        Text("Kasetsart University")
                            .font(Font.Sarabun.medium(12))
                            .foregroundStyle(KUTheme.Palette.neutral400)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    // MARK: - Google button

    private var googleButton: some View {
        Button {
            Task { await vm.signInWithGoogle() }
        } label: {
            HStack(spacing: 10) {
                // Google "G" logo drawn with system shapes
                ZStack {
                    Circle()
                        .fill(KUTheme.Palette.white)
                        .frame(width: 24, height: 24)
                    Text("G")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0x4285F4))
                }
                Text("Continue with Google")
                    .font(Font.Sarabun.semibold(15))
                    .foregroundStyle(KUTheme.Palette.neutral900)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                    .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
            )
        }
        .buttonStyle(KUPressStyle())
        .disabled(vm.isBusy)
        .opacity(vm.isBusy ? 0.6 : 1)
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab(label: "Sign In",  active: !vm.isSignUp) { vm.isSignUp = false; vm.errorMessage = nil }
            modeTab(label: "Sign Up",  active:  vm.isSignUp) { vm.isSignUp = true;  vm.errorMessage = nil }
        }
        .background(KUTheme.Palette.neutral100, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
    }

    private func modeTab(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Font.Sarabun.semibold(14))
                .foregroundStyle(active ? KUTheme.Palette.white : KUTheme.Palette.neutral600)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if active {
                            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                                .fill(KUTheme.Palette.neutral900)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: active)
    }

    // MARK: - Input field

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType = .default,
        autocap: TextInputAutocapitalization = .words,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(KUTheme.Palette.neutral400)
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap)
                }
            }
            .font(Font.Sarabun.regular(15))
            .focused($focused, equals: field)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(KUTheme.Palette.neutral100, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                .stroke(focused == field ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral200, lineWidth: 1)
        )
        .autocorrectionDisabled()
    }
}

#Preview {
    AuthScreen(vm: AuthViewModel())
}
