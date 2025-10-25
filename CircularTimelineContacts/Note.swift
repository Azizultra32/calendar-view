import SwiftUI
import SwiftData
import Foundation

/// Custom notes attached to contacts for tracking important information
@Model
final class Note {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Content
    var title: String?
    var body: String
    var tags: [String]

    // MARK: - Metadata
    var isPinned: Bool
    var reminderDate: Date?
    var color: String?  // Hex color for note highlighting

    // MARK: - Relationships
    @Relationship var contact: Contact?

    // MARK: - Computed Properties
    var wordCount: Int {
        body.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    var characterCount: Int {
        body.count
    }

    var preview: String {
        let maxLength = 100
        if body.count > maxLength {
            return String(body.prefix(maxLength)) + "..."
        }
        return body
    }

    var hasReminder: Bool {
        reminderDate != nil
    }

    var isReminderDue: Bool {
        guard let reminderDate = reminderDate else { return false }
        return reminderDate <= Date()
    }

    var displayTitle: String {
        title ?? preview
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        title: String? = nil,
        body: String,
        tags: [String] = [],
        isPinned: Bool = false,
        color: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.body = body
        self.tags = tags
        self.isPinned = isPinned
        self.color = color
    }

    // MARK: - Methods
    func updateTimestamp() {
        self.updatedAt = Date()
    }

    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            updateTimestamp()
        }
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        updateTimestamp()
    }

    func setReminder(for date: Date) {
        reminderDate = date
        updateTimestamp()
    }

    func clearReminder() {
        reminderDate = nil
        updateTimestamp()
    }

    func togglePin() {
        isPinned.toggle()
        updateTimestamp()
    }
}

// MARK: - Formatting Extensions
extension Note {
    var formattedCreatedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedUpdatedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    var formattedReminderDate: String? {
        guard let date = reminderDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var noteColor: Color {
        if let hex = color {
            return Color(hex: hex) ?? .gray
        }
        return .gray
    }
}

// MARK: - Comparable for Sorting
extension Note: Comparable {
    static func < (lhs: Note, rhs: Note) -> Bool {
        // Pinned notes first
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned
        }

        // Then by reminder date (if any)
        if let lhsReminder = lhs.reminderDate, let rhsReminder = rhs.reminderDate {
            return lhsReminder < rhsReminder
        }
        if lhs.reminderDate != nil {
            return true
        }
        if rhs.reminderDate != nil {
            return false
        }

        // Finally by update date (most recent first)
        return lhs.updatedAt > rhs.updatedAt
    }
}
