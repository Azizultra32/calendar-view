import SwiftUI
import SwiftData
import Foundation

/// Represents a time-based event/interaction with one or more participants
@Model
final class Interaction {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Time
    var startTime: Date
    var endTime: Date
    var isAllDay: Bool
    private var timeZoneIdentifier: String

    // MARK: - Details
    var title: String
    var notes: String?
    var colorHex: String
    var category: InteractionCategory

    // MARK: - Location
    var locationName: String?
    @Relationship(deleteRule: .nullify)
    var location: Location?

    // MARK: - Participants
    var participants: [Contact]

    // MARK: - Recurrence
    var isRecurring: Bool
    var recurrenceRule: String?  // iCalendar RRULE format (e.g., "FREQ=WEEKLY;BYDAY=MO,WE,FR")
    var parentInteractionID: UUID?  // For recurring instances

    // MARK: - Attachments & Media
    var attachmentData: [Data]  // Photos, documents
    var attachmentTypes: [String]  // MIME types or file extensions

    // MARK: - Tags & Metadata
    var tags: [String]
    var mood: String?  // Optional mood indicator

    // MARK: - External Integration
    var calendarEventIdentifier: String?  // EKEvent.eventIdentifier
    var externalSource: String?  // "Calendar", "Manual", "Import", "Social"
    var socialPlatformSource: SocialPlatform?  // If synced from social media

    // MARK: - Computed Properties
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationHours: Double {
        duration / 3600
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var participantCount: Int {
        participants.count
    }

    var participantNames: String {
        participants.map { $0.name }.joined(separator: ", ")
    }

    var timeZone: TimeZone {
        get { TimeZone(identifier: timeZoneIdentifier) ?? .current }
        set { timeZoneIdentifier = newValue.identifier }
    }

    var color: Color {
        Color(hex: colorHex) ?? category.color
    }

    var isInPast: Bool {
        endTime < Date()
    }

    var isOngoing: Bool {
        let now = Date()
        return startTime <= now && endTime >= now
    }

    var isUpcoming: Bool {
        startTime > Date()
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        title: String,
        colorHex: String? = nil,
        category: InteractionCategory = .other,
        isAllDay: Bool = false,
        timeZone: TimeZone = .current,
        locationName: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.colorHex = colorHex ?? category.defaultColor
        self.category = category
        self.isAllDay = isAllDay
        self.timeZoneIdentifier = timeZone.identifier
        self.locationName = locationName
        self.participants = []
        self.isRecurring = false
        self.attachmentData = []
        self.attachmentTypes = []
        self.tags = []
    }

    // MARK: - Methods
    func updateTimestamp() {
        self.updatedAt = Date()
    }

    func addParticipant(_ contact: Contact) {
        if !participants.contains(where: { $0.id == contact.id }) {
            participants.append(contact)
            updateTimestamp()
        }
    }

    func removeParticipant(_ contact: Contact) {
        participants.removeAll { $0.id == contact.id }
        updateTimestamp()
    }

    func addAttachment(data: Data, type: String) {
        attachmentData.append(data)
        attachmentTypes.append(type)
        updateTimestamp()
    }

    func hasParticipant(_ contact: Contact) -> Bool {
        participants.contains { $0.id == contact.id }
    }

    func overlaps(with other: Interaction) -> Bool {
        (startTime < other.endTime) && (endTime > other.startTime)
    }
}

// MARK: - Time Formatting Extensions
extension Interaction {
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startTime)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: startTime)
    }

    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: startTime)
    }

    var fullDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

// MARK: - Comparable for Sorting
extension Interaction: Comparable {
    static func < (lhs: Interaction, rhs: Interaction) -> Bool {
        lhs.startTime < rhs.startTime
    }
}
