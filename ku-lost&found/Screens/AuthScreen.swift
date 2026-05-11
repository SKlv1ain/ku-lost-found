import SwiftUI

struct AuthScreen: View {
    @Bindable var vm: AuthViewModel
    @FocusState private var focused: Field?

    private enum Field { case name, email, password }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    formCard
                    divider
                    googleButton.padding(.horizontal, 20)
                    footer
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KUTheme.Palette.neutral100.ignoresSafeArea())

            // Success overlay
            if vm.showSignUpSuccess {
                SignUpSuccessOverlay(email: vm.signedUpEmail) {
                    vm.showSignUpSuccess = false
                    vm.isSignUp = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.showSignUpSuccess)
    }

    // MARK: - Hero

    private var hero: some View {
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
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(spacing: 16) {
            modeToggle.padding(.bottom, 4)

            if vm.isSignUp {
                inputField(icon: "person", placeholder: "Full name",
                           text: $vm.fullName, field: .name)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            inputField(icon: "envelope", placeholder: "Email address",
                       text: $vm.email, field: .email,
                       keyboard: .emailAddress, autocap: .never)

            inputField(icon: "lock", placeholder: "Password",
                       text: $vm.password, field: .password, isSecure: true)

            if let err = vm.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(err).font(Font.Sarabun.medium(13))
                }
                .foregroundStyle(KUTheme.Palette.accent500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            submitButton
        }
        .padding(20)
        .background(KUTheme.Palette.white,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.isSignUp)
        .animation(.easeOut(duration: 0.2), value: vm.errorMessage)
    }

    // MARK: - Submit button with animated loader

    private var submitButton: some View {
        Button {
            focused = nil
            Task {
                if vm.isSignUp { await vm.signUp() }
                else { await vm.signIn() }
            }
        } label: {
            ZStack {
                // Normal label
                HStack(spacing: 8) {
                    Image(systemName: vm.isSignUp ? "person.badge.plus" : "arrow.right")
                    Text(vm.isSignUp ? "Create account" : "Sign in")
                        .font(Font.Sarabun.semibold(16))
                        .tracking(0.2)
                }
                .opacity(vm.isBusy ? 0 : 1)

                // Animated dots loader
                if vm.isBusy {
                    LoadingDots()
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(
                KUTheme.Palette.neutral900,
                in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
            )
        }
        .buttonStyle(KUPressStyle())
        .disabled(vm.isBusy)
        .animation(.easeOut(duration: 0.18), value: vm.isBusy)
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
            Text("or")
                .font(Font.Sarabun.regular(13))
                .foregroundStyle(KUTheme.Palette.neutral400)
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Google button

    private var googleButton: some View {
        Button { Task { await vm.signInWithGoogle() } } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(KUTheme.Palette.white).frame(width: 24, height: 24)
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
            .background(KUTheme.Palette.white,
                        in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                    .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
            )
        }
        .buttonStyle(KUPressStyle())
        .disabled(vm.isBusy)
        .opacity(vm.isBusy ? 0.5 : 1)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Circle().fill(KUTheme.Palette.primary700).frame(width: 6, height: 6)
            Text("Kasetsart University")
                .font(Font.Sarabun.medium(12))
                .foregroundStyle(KUTheme.Palette.neutral400)
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab(label: "Sign In", active: !vm.isSignUp) {
                vm.isSignUp = false; vm.errorMessage = nil
            }
            modeTab(label: "Sign Up", active: vm.isSignUp) {
                vm.isSignUp = true; vm.errorMessage = nil
            }
        }
        .background(KUTheme.Palette.neutral100,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
    }

    private func modeTab(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Font.Sarabun.semibold(14))
                .foregroundStyle(active ? KUTheme.Palette.white : KUTheme.Palette.neutral600)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if active {
                        RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                            .fill(KUTheme.Palette.neutral900)
                    }
                }
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
                .foregroundStyle(focused == field ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral400)
                .frame(width: 20)
                .animation(.easeOut(duration: 0.15), value: focused == field)

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
        .background(KUTheme.Palette.neutral100,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                .stroke(
                    focused == field ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral200,
                    lineWidth: focused == field ? 1.5 : 1
                )
        )
        .autocorrectionDisabled()
        .animation(.easeOut(duration: 0.15), value: focused == field)
    }
}

// MARK: - Loading dots

struct LoadingDots: View {
    @State private var phase = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.35 : 0.8)
                    .opacity(phase == i ? 1 : 0.45)
                    .animation(.easeInOut(duration: 0.38), value: phase)
            }
        }
        .onAppear {
            phase = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.38, repeats: true) { _ in
                DispatchQueue.main.async { phase = (phase + 1) % 3 }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Sign Up Success Overlay

struct SignUpSuccessOverlay: View {
    let email: String
    let onContinue: () -> Void

    @State private var checkScale: CGFloat = 0
    @State private var checkOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    @State private var countdown = 5
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Animated checkmark
                    ZStack {
                        // Outer ring pulse
                        Circle()
                            .stroke(KUTheme.Palette.primary700.opacity(0.2), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        Circle()
                            .fill(KUTheme.Palette.primary50)
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(KUTheme.Palette.primary700)
                            .scaleEffect(checkScale)
                            .opacity(checkOpacity)
                    }
                    .padding(.top, 8)

                    // Text content
                    VStack(spacing: 10) {
                        Text("Account Created!")
                            .font(Font.Sarabun.bold(24))
                            .foregroundStyle(KUTheme.Palette.neutral900)

                        Rectangle()
                            .fill(KUTheme.Palette.accent500)
                            .frame(width: 40, height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 2))

                        Text("We sent a confirmation email to")
                            .font(Font.Sarabun.regular(14))
                            .foregroundStyle(KUTheme.Palette.neutral600)

                        Text(email)
                            .font(Font.Sarabun.semibold(14))
                            .foregroundStyle(KUTheme.Palette.neutral900)
                            .multilineTextAlignment(.center)

                        Text("Please check your inbox and tap the\nconfirmation link before signing in.")
                            .font(Font.Sarabun.regular(13))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }

                    // Countdown + button
                    VStack(spacing: 12) {
                        PrimaryButton(
                            label: "Go to Sign In  (\(countdown))",
                            color: KUTheme.Palette.neutral900,
                            action: finishAndDismiss
                        )

                        Button(action: openMail) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.open")
                                    .font(.system(size: 14))
                                Text("Open Mail app")
                                    .font(Font.Sarabun.medium(14))
                            }
                            .foregroundStyle(KUTheme.Palette.primary700)
                        }
                    }
                }
                .padding(28)
                .background(KUTheme.Palette.white,
                            in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 20)
                .offset(y: contentOffset)
                .opacity(contentOpacity)

                Spacer().frame(height: 40)
            }
        }
        .onAppear { startAnimations() }
        .onDisappear { timer?.invalidate() }
    }

    private func startAnimations() {
        // Checkmark springs in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            checkScale = 1
            checkOpacity = 1
        }
        // Ring expands
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            ringScale = 1.6
            ringOpacity = 0
        }
        // Card slides up
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(0.05)) {
            contentOffset = 0
            contentOpacity = 1
        }

        // Countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                finishAndDismiss()
            }
        }
    }

    private func finishAndDismiss() {
        timer?.invalidate()
        onContinue()
    }

    private func openMail() {
        if let url = URL(string: "message://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview { AuthScreen(vm: AuthViewModel()) }
