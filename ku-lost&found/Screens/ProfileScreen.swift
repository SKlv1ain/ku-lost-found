import SwiftUI
import Supabase

struct ProfileScreen: View {
    var authVM: AuthViewModel
    var onItem: (Item) -> Void

    private var displayName: String {
        if let meta = authVM.user?.userMetadata,
           let name = meta["full_name"]?.stringValue, !name.isEmpty {
            return name
        }
        return authVM.user?.email?.components(separatedBy: "@").first ?? "User"
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    statRow
                    section(title: "My reports", action: "See all") {
                        VStack(spacing: 10) {
                            ForEach(SampleData.items.prefix(2)) { item in
                                ItemCard(item: item) { onItem(item) }
                            }
                        }
                    }
                    settingsList
                    signOutButton
                }
                .padding(16)
                .padding(.bottom, 80)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    private var navBar: some View {
        ZStack {
            Text("My Profile")
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
            HStack {
                Spacer()
                Button("Edit") {}
                    .font(Font.Sarabun.medium(15))
                    .foregroundStyle(KUTheme.Palette.primary700)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(KUTheme.Palette.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(KUTheme.Palette.neutral900)
                Text("👤").font(.system(size: 48))
            }
            .frame(width: 96, height: 96)
            .overlay(Circle().stroke(KUTheme.Palette.neutral200, lineWidth: 1))
            VStack(spacing: 4) {
                Text(displayName)
                    .font(Font.Sarabun.bold(20))
                    .foregroundStyle(KUTheme.Palette.neutral900)
                Text(authVM.user?.email ?? "—")
                    .font(Font.Sarabun.regular(13))
                    .foregroundStyle(KUTheme.Palette.neutral600)
            }
            HStack(spacing: 8) {
                tag("Engineering")
                tag("Year 4")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    private func tag(_ s: String) -> some View {
        Text(s)
            .font(Font.Sarabun.medium(12))
            .foregroundStyle(KUTheme.Palette.primary700)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(KUTheme.Palette.primary50, in: Capsule())
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            statCard(value: "5", label: "Reported", emoji: "📝")
            statCard(value: "3", label: "Returned", emoji: "✅")
            statCard(value: "8", label: "Helped",   emoji: "💚")
        }
    }

    private func statCard(value: String, label: String, emoji: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 22))
            Text(value)
                .font(Font.Sarabun.bold(20))
                .foregroundStyle(KUTheme.Palette.neutral900)
            Text(label)
                .font(Font.Sarabun.regular(11))
                .foregroundStyle(KUTheme.Palette.neutral600)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func section<C: View>(title: String, action: String? = nil, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, action: action) {}
            content()
        }
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell.fill", label: "Notifications")
            divider
            settingsRow(icon: "lock.fill", label: "Privacy")
            divider
            settingsRow(icon: "questionmark.circle.fill", label: "Help & Support")
            divider
            settingsRow(icon: "info.circle.fill", label: "About")
        }
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1).padding(.leading, 48)
    }

    private func settingsRow(icon: String, label: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.primary700)
                    .frame(width: 24)
                Text(label)
                    .font(Font.Sarabun.medium(15))
                    .foregroundStyle(KUTheme.Palette.neutral900)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.neutral300)
            }
            .padding(14)
        }
        .buttonStyle(KUTappableStyle())
    }

    private var signOutButton: some View {
        Button(action: { Task { await authVM.signOut() } }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.square")
                Text("Sign out")
                    .font(Font.Sarabun.semibold(15))
            }
            .foregroundStyle(KUTheme.Palette.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KUTheme.Palette.dangerBg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        }
        .buttonStyle(KUTappableStyle())
    }
}

#Preview { ProfileScreen(authVM: AuthViewModel(), onItem: { _ in }) }
