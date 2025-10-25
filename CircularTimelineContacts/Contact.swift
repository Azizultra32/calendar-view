import SwiftUI
import SwiftData
import Foundation

/// Main contact entity representing a person with comprehensive contact information
@Model
final class Contact {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Basic Info
    var name: String
    var nickname: String?
    var initial: String
    var avatarImageData: Data?

    // MARK: - Contact Details
    var phoneNumbers: [PhoneNumber]
    var emailAddresses: [EmailAddress]
    var physicalAddresses: [Address]

    // MARK: - Social Media Profiles
    var socialProfiles: [SocialProfile]

    // MARK: - Metadata
    var notes: String?
    var isFavorite: Bool
    var tags: [String]
    var customColor: String?  // Hex color for timeline arcs

    // MARK: - iOS Contacts Integration
    var contactIdentifier: String?  // CNContact.identifier for sync
    var lastSyncedAt: Date?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \Interaction.participants)
    var interactions: [Interaction]

    @Relationship(deleteRule: .cascade)
    var customNotes: [Note]

    // MARK: - Computed Properties
    var interactionCount: Int {
        interactions.count
    }

    var lastInteractionDate: Date? {
        interactions.max(by: { $0.startTime < $1.startTime })?.startTime
    }

    var totalTimeSpent: TimeInterval {
        interactions.reduce(0) { total, interaction in
            total + interaction.duration
        }
    }

    var primaryPhoneNumber: String? {
        phoneNumbers.first?.number
    }

    var primaryEmail: String? {
        emailAddresses.first?.email
    }

    // MARK: - Social Media Helpers
    var hasSocialProfiles: Bool {
        !socialProfiles.isEmpty
    }

    func socialProfile(for platform: SocialPlatform) -> SocialProfile? {
        socialProfiles.first { $0.platform == platform }
    }

    var instagramHandle: String? {
        socialProfile(for: .instagram)?.handle
    }

    var twitterHandle: String? {
        socialProfile(for: .twitter)?.handle
    }

    var linkedInURL: String? {
        socialProfile(for: .linkedIn)?.profileURL
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        nickname: String? = nil,
        initial: String? = nil,
        avatarImageData: Data? = nil,
        isFavorite: Bool = false,
        customColor: String? = nil,
        contactIdentifier: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.nickname = nickname

        // Auto-generate initial if not provided
        if let initial = initial {
            self.initial = initial
        } else {
            self.initial = String(name.prefix(1).uppercased())
        }

        self.avatarImageData = avatarImageData
        self.phoneNumbers = []
        self.emailAddresses = []
        self.physicalAddresses = []
        self.socialProfiles = []
        self.isFavorite = isFavorite
        self.tags = []
        self.customColor = customColor
        self.contactIdentifier = contactIdentifier
        self.interactions = []
        self.customNotes = []
    }

    // MARK: - Methods
    func updateTimestamp() {
        self.updatedAt = Date()
    }

    func addPhoneNumber(_ phoneNumber: PhoneNumber) {
        phoneNumbers.append(phoneNumber)
        updateTimestamp()
    }

    func addEmailAddress(_ email: EmailAddress) {
        emailAddresses.append(email)
        updateTimestamp()
    }

    func addSocialProfile(_ profile: SocialProfile) {
        // Remove existing profile for same platform
        socialProfiles.removeAll { $0.platform == profile.platform }
        socialProfiles.append(profile)
        updateTimestamp()
    }

    func removeSocialProfile(for platform: SocialPlatform) {
        socialProfiles.removeAll { $0.platform == platform }
        updateTimestamp()
    }
}

// MARK: - Convenience Extensions
extension Contact {
    /// Returns a formatted display name (nickname if available, otherwise name)
    var displayName: String {
        nickname ?? name
    }

    /// Returns initials (up to 2 characters) for avatar display
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        }
        return initial
    }

    /// Returns a Color from the customColor hex string
    var timelineColor: Color {
        if let hex = customColor {
            return Color(hex: hex) ?? .blue
        }
        return .blue
    }
}

// MARK: - Color Extension for Hex Strings
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
