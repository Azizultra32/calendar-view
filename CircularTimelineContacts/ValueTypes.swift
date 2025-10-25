import Foundation

// MARK: - Phone Number
struct PhoneNumber: Codable, Hashable {
    var label: String  // "mobile", "work", "home", "iPhone", "main"
    var number: String

    init(label: String = "mobile", number: String) {
        self.label = label
        self.number = number
    }

    var formattedNumber: String {
        // Basic US phone number formatting
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if cleaned.count == 10 {
            let areaCode = cleaned.prefix(3)
            let prefix = cleaned.dropFirst(3).prefix(3)
            let suffix = cleaned.dropFirst(6)
            return "(\(areaCode)) \(prefix)-\(suffix)"
        } else if cleaned.count == 11 && cleaned.hasPrefix("1") {
            let areaCode = cleaned.dropFirst().prefix(3)
            let prefix = cleaned.dropFirst(4).prefix(3)
            let suffix = cleaned.dropFirst(7)
            return "+1 (\(areaCode)) \(prefix)-\(suffix)"
        }

        return number  // Return original if can't format
    }
}

// MARK: - Email Address
struct EmailAddress: Codable, Hashable {
    var label: String  // "work", "personal", "home", "iCloud"
    var email: String

    init(label: String = "personal", email: String) {
        self.label = label
        self.email = email
    }

    var isValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Physical Address
struct Address: Codable, Hashable {
    var label: String  // "home", "work", "other"
    var street: String?
    var city: String?
    var state: String?
    var postalCode: String?
    var country: String?

    init(
        label: String = "home",
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil
    ) {
        self.label = label
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }

    var formattedAddress: String {
        var components: [String] = []

        if let street = street {
            components.append(street)
        }

        var cityStateZip: [String] = []
        if let city = city {
            cityStateZip.append(city)
        }
        if let state = state {
            cityStateZip.append(state)
        }
        if let postalCode = postalCode {
            cityStateZip.append(postalCode)
        }
        if !cityStateZip.isEmpty {
            components.append(cityStateZip.joined(separator: ", "))
        }

        if let country = country {
            components.append(country)
        }

        return components.joined(separator: "\n")
    }

    var oneLine: String {
        formattedAddress.replacingOccurrences(of: "\n", with: ", ")
    }
}

// MARK: - Social Profile
struct SocialProfile: Codable, Hashable, Identifiable {
    var id = UUID()
    var platform: SocialPlatform
    var handle: String  // Username/handle without @ symbol
    var profileURL: String?
    var isVerified: Bool

    init(
        platform: SocialPlatform,
        handle: String,
        profileURL: String? = nil,
        isVerified: Bool = false
    ) {
        self.platform = platform
        self.handle = handle.replacingOccurrences(of: "@", with: "")  // Clean handle
        self.profileURL = profileURL ?? platform.buildURL(for: handle)
        self.isVerified = isVerified
    }

    var displayHandle: String {
        "@\(handle)"
    }

    var fullURL: URL? {
        if let urlString = profileURL {
            return URL(string: urlString)
        }
        return nil
    }
}

// MARK: - Social Platform Enum
enum SocialPlatform: String, Codable, CaseIterable {
    case twitter = "Twitter"
    case instagram = "Instagram"
    case facebook = "Facebook"
    case linkedIn = "LinkedIn"
    case tiktok = "TikTok"
    case snapchat = "Snapchat"
    case youtube = "YouTube"
    case threads = "Threads"
    case mastodon = "Mastodon"
    case bluesky = "Bluesky"
    case telegram = "Telegram"
    case whatsapp = "WhatsApp"
    case signal = "Signal"
    case discord = "Discord"
    case github = "GitHub"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    var iconName: String {
        // SF Symbols or custom icon names
        switch self {
        case .twitter: return "bird"
        case .instagram: return "camera"
        case .facebook: return "f.circle"
        case .linkedIn: return "briefcase"
        case .tiktok: return "music.note"
        case .snapchat: return "camera.viewfinder"
        case .youtube: return "play.rectangle"
        case .threads: return "text.bubble"
        case .mastodon: return "bubble.left.and.bubble.right"
        case .bluesky: return "cloud"
        case .telegram: return "paperplane"
        case .whatsapp: return "phone.bubble.left"
        case .signal: return "lock.shield"
        case .discord: return "gamecontroller"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .other: return "link"
        }
    }

    var emoji: String {
        switch self {
        case .twitter: return "🐦"
        case .instagram: return "📸"
        case .facebook: return "📘"
        case .linkedIn: return "💼"
        case .tiktok: return "🎵"
        case .snapchat: return "👻"
        case .youtube: return "▶️"
        case .threads: return "🧵"
        case .mastodon: return "🐘"
        case .bluesky: return "☁️"
        case .telegram: return "✈️"
        case .whatsapp: return "💬"
        case .signal: return "🔐"
        case .discord: return "🎮"
        case .github: return "🐙"
        case .other: return "🔗"
        }
    }

    var baseURL: String {
        switch self {
        case .twitter: return "https://twitter.com/"
        case .instagram: return "https://instagram.com/"
        case .facebook: return "https://facebook.com/"
        case .linkedIn: return "https://linkedin.com/in/"
        case .tiktok: return "https://tiktok.com/@"
        case .snapchat: return "https://snapchat.com/add/"
        case .youtube: return "https://youtube.com/@"
        case .threads: return "https://threads.net/@"
        case .mastodon: return "https://mastodon.social/@"
        case .bluesky: return "https://bsky.app/profile/"
        case .telegram: return "https://t.me/"
        case .whatsapp: return "https://wa.me/"
        case .signal: return "https://signal.me/#p/"
        case .discord: return "https://discord.com/users/"
        case .github: return "https://github.com/"
        case .other: return ""
        }
    }

    func buildURL(for handle: String) -> String {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        return baseURL + cleanHandle
    }

    var appURLScheme: String? {
        // Deep link URL schemes for opening native apps
        switch self {
        case .twitter: return "twitter://user?screen_name="
        case .instagram: return "instagram://user?username="
        case .facebook: return "fb://profile/"
        case .youtube: return "youtube://www.youtube.com/@"
        case .telegram: return "tg://resolve?domain="
        case .whatsapp: return "whatsapp://send?phone="
        default: return nil
        }
    }

    func openProfile(handle: String) -> URL? {
        // Try app URL scheme first, fallback to web URL
        if let appScheme = appURLScheme {
            let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
            return URL(string: appScheme + cleanHandle)
        }
        return URL(string: buildURL(for: handle))
    }
}

// MARK: - Social Platform Category
extension SocialPlatform {
    enum Category {
        case social       // General social networks
        case professional // LinkedIn, etc.
        case messaging    // WhatsApp, Signal, Telegram
        case media        // YouTube, TikTok
        case developer    // GitHub

        var platforms: [SocialPlatform] {
            switch self {
            case .social:
                return [.twitter, .instagram, .facebook, .threads, .mastodon, .bluesky, .snapchat]
            case .professional:
                return [.linkedIn]
            case .messaging:
                return [.whatsapp, .telegram, .signal, .discord]
            case .media:
                return [.youtube, .tiktok]
            case .developer:
                return [.github]
            }
        }
    }

    var category: Category {
        switch self {
        case .twitter, .instagram, .facebook, .threads, .mastodon, .bluesky, .snapchat:
            return .social
        case .linkedIn:
            return .professional
        case .whatsapp, .telegram, .signal, .discord:
            return .messaging
        case .youtube, .tiktok:
            return .media
        case .github:
            return .developer
        case .other:
            return .social
        }
    }
}
