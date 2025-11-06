import UIKit
import SwiftUI
import Foundation

/// Handles opening social media profiles and deep linking to native apps
final class SocialMediaHandler {

    // MARK: - Open Profile Methods

    /// Opens a social media profile, preferring native app over web browser
    static func openProfile(_ profile: SocialProfile) {
        guard let url = profile.fullURL else {
            print("❌ Invalid URL for profile: \(profile.handle)")
            return
        }

        // Try native app first
        if let appURL = profile.platform.openProfile(handle: profile.handle) {
            if UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL) { success in
                    if !success {
                        // Fallback to web URL
                        UIApplication.shared.open(url)
                    }
                }
                return
            }
        }

        // Fallback to web browser
        UIApplication.shared.open(url)
    }

    /// Opens a specific social platform for a contact
    static func openSocial(platform: SocialPlatform, for contact: Contact) {
        guard let profile = contact.socialProfile(for: platform) else {
            print("❌ Contact \(contact.name) doesn't have \(platform.displayName)")
            return
        }

        openProfile(profile)
    }

    // MARK: - Bulk Actions

    /// Opens all social profiles for a contact (presents action sheet)
    static func presentSocialOptions(for contact: Contact, from viewController: UIViewController) {
        guard !contact.socialProfiles.isEmpty else {
            showAlert(title: "No Social Profiles", message: "This contact doesn't have any social media profiles.", from: viewController)
            return
        }

        let alert = UIAlertController(
            title: "Open Social Profile",
            message: "Choose a platform to open",
            preferredStyle: .actionSheet
        )

        for profile in contact.socialProfiles {
            let action = UIAlertAction(
                title: "\(profile.platform.emoji) \(profile.platform.displayName) (@\(profile.handle))",
                style: .default
            ) { _ in
                openProfile(profile)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        viewController.present(alert, animated: true)
    }

    // MARK: - Direct Actions (for quick actions)

    /// Opens Instagram profile
    static func openInstagram(handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")

        // Try Instagram app
        if let appURL = URL(string: "instagram://user?username=\(cleanHandle)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Fallback to web
            if let webURL = URL(string: "https://instagram.com/\(cleanHandle)") {
                UIApplication.shared.open(webURL)
            }
        }
    }

    /// Opens Twitter/X profile
    static func openTwitter(handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")

        // Try Twitter app
        if let appURL = URL(string: "twitter://user?screen_name=\(cleanHandle)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Fallback to web
            if let webURL = URL(string: "https://twitter.com/\(cleanHandle)") {
                UIApplication.shared.open(webURL)
            }
        }
    }

    /// Opens LinkedIn profile
    static func openLinkedIn(profileURL: String) {
        guard let url = URL(string: profileURL) else { return }
        UIApplication.shared.open(url)
    }

    /// Opens TikTok profile
    static func openTikTok(handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")

        // TikTok uses web URLs
        if let webURL = URL(string: "https://tiktok.com/@\(cleanHandle)") {
            UIApplication.shared.open(webURL)
        }
    }

    /// Opens Facebook profile
    static func openFacebook(profileURL: String) {
        guard let url = URL(string: profileURL) else { return }

        // Try Facebook app with fb:// scheme
        let fbScheme = profileURL.replacingOccurrences(of: "https://", with: "fb://")
        if let appURL = URL(string: fbScheme),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Fallback to web
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Messaging Apps

    /// Opens WhatsApp chat
    static func openWhatsApp(phoneNumber: String) {
        // Clean phone number (remove non-digits)
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        // WhatsApp URL format: https://wa.me/<number>
        if let url = URL(string: "https://wa.me/\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    /// Opens Telegram chat
    static func openTelegram(username: String) {
        let cleanUsername = username.replacingOccurrences(of: "@", with: "")

        // Try Telegram app
        if let appURL = URL(string: "tg://resolve?domain=\(cleanUsername)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Fallback to web
            if let webURL = URL(string: "https://t.me/\(cleanUsername)") {
                UIApplication.shared.open(webURL)
            }
        }
    }

    /// Opens Signal chat
    static func openSignal(phoneNumber: String) {
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let url = URL(string: "https://signal.me/#p/\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Validation

    /// Checks if a native app is installed for a platform
    static func isAppInstalled(for platform: SocialPlatform) -> Bool {
        guard let scheme = platform.appURLScheme,
              let url = URL(string: scheme + "test") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }

    /// Returns all platforms that have native apps installed
    static func installedApps() -> [SocialPlatform] {
        SocialPlatform.allCases.filter { isAppInstalled(for: $0) }
    }

    // MARK: - Share Actions

    /// Shares contact information via social media
    static func shareContact(_ contact: Contact, from viewController: UIViewController) {
        var items: [Any] = []

        // Create share text
        let shareText = "Connect with \(contact.name)"
        items.append(shareText)

        // Add social links
        for profile in contact.socialProfiles {
            if let url = profile.fullURL {
                items.append(url)
            }
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Helper Methods

    private static func showAlert(title: String, message: String, from viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

// MARK: - SwiftUI Wrapper
struct SocialMediaButton: View {
    let profile: SocialProfile
    let style: ButtonStyle

    enum ButtonStyle {
        case icon
        case iconWithLabel
        case full
    }

    var body: some View {
        Button(action: {
            SocialMediaHandler.openProfile(profile)
        }) {
            switch style {
            case .icon:
                Image(systemName: profile.platform.iconName)
                    .foregroundColor(.white)

            case .iconWithLabel:
                HStack(spacing: 6) {
                    Image(systemName: profile.platform.iconName)
                    Text(profile.platform.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)

            case .full:
                HStack(spacing: 8) {
                    Text(profile.platform.emoji)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.platform.displayName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(profile.displayHandle)
                            .font(.system(size: 14, weight: .medium))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Social Profiles List View
struct SocialProfilesList: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !contact.socialProfiles.isEmpty {
                Text("Social Media")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                ForEach(contact.socialProfiles) { profile in
                    SocialMediaButton(profile: profile, style: .full)
                }
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Quick Social Actions
struct QuickSocialActions: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(contact.socialProfiles.prefix(4))) { profile in
                Button(action: {
                    SocialMediaHandler.openProfile(profile)
                }) {
                    VStack(spacing: 4) {
                        Text(profile.platform.emoji)
                            .font(.system(size: 20))
                        Text(profile.platform.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            if contact.socialProfiles.count > 4 {
                Button(action: {
                    // Show all social profiles
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                        Text("More")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}
