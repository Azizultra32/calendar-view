import Foundation
import EventKit
import SwiftData

/// Manages iOS Calendar integration and syncing events to interactions
@Observable
final class CalendarManager {
    // MARK: - Properties

    private let eventStore = EKEventStore()
    var hasAccess = false
    var isSyncing = false
    var lastSyncDate: Date?
    var syncedEventCount = 0

    // MARK: - Calendar Access

    /// Request calendar access from the user
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            hasAccess = granted
            return granted
        } catch {
            print("❌ Calendar access error: \(error)")
            hasAccess = false
            return false
        }
    }

    /// Check if we already have calendar access
    func checkAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasAccess = (status == .fullAccess || status == .authorized)
        return hasAccess
    }

    // MARK: - Event Fetching

    /// Fetch calendar events for a date range
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard hasAccess else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil // All calendars
        )

        let events = eventStore.events(matching: predicate)
        return events
    }

    /// Fetch events for a specific date
    func fetchEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchEvents(from: startOfDay, to: endOfDay)
    }

    /// Fetch events for the next 30 days
    func fetchUpcomingEvents() -> [EKEvent] {
        let now = Date()
        let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        return fetchEvents(from: now, to: thirtyDaysLater)
    }

    // MARK: - Sync to Interactions

    /// Sync calendar events to SwiftData interactions
    func syncEvents(
        from startDate: Date,
        to endDate: Date,
        modelContext: ModelContext,
        contactMatcher: (String) -> Contact?
    ) async -> Int {
        guard hasAccess else { return 0 }

        isSyncing = true
        defer { isSyncing = false }

        let events = fetchEvents(from: startDate, to: endDate)
        var importedCount = 0

        // Get existing synced interactions to avoid duplicates
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.externalSource == "Calendar" }
        )
        let existingInteractions = (try? modelContext.fetch(descriptor)) ?? []
        let existingEventIDs = Set(existingInteractions.compactMap { $0.calendarEventIdentifier })

        for event in events {
            // Skip all-day events (optional)
            // if event.isAllDay { continue }

            // Skip already synced events
            if existingEventIDs.contains(event.eventIdentifier) {
                continue
            }

            // Create interaction from event
            let interaction = createInteraction(from: event, contactMatcher: contactMatcher)
            modelContext.insert(interaction)
            importedCount += 1
        }

        try? modelContext.save()

        lastSyncDate = Date()
        syncedEventCount = importedCount

        return importedCount
    }

    /// Quick sync for today's events
    func syncToday(modelContext: ModelContext, contactMatcher: (String) -> Contact?) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return await syncEvents(from: today, to: tomorrow, modelContext: modelContext, contactMatcher: contactMatcher)
    }

    /// Sync next 7 days
    func syncWeek(modelContext: ModelContext, contactMatcher: (String) -> Contact?) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        return await syncEvents(from: today, to: nextWeek, modelContext: modelContext, contactMatcher: contactMatcher)
    }

    /// Sync next 30 days
    func syncMonth(modelContext: ModelContext, contactMatcher: (String) -> Contact?) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextMonth = calendar.date(byAdding: .day, value: 30, to: today)!

        return await syncEvents(from: today, to: nextMonth, modelContext: modelContext, contactMatcher: contactMatcher)
    }

    // MARK: - Helper Methods

    /// Convert EKEvent to Interaction
    private func createInteraction(from event: EKEvent, contactMatcher: (String) -> Contact?) -> Interaction {
        let interaction = Interaction(
            startTime: event.startDate,
            endTime: event.endDate,
            title: event.title ?? "Untitled Event",
            category: categoryFromEvent(event),
            isAllDay: event.isAllDay,
            locationName: event.location
        )

        // Set calendar metadata
        interaction.externalSource = "Calendar"
        interaction.calendarEventIdentifier = event.eventIdentifier

        // Set color based on calendar
        if let calendarColor = event.calendar.cgColor {
            let uiColor = UIColor(cgColor: calendarColor)
            interaction.colorHex = uiColor.toHexString()
        } else {
            interaction.colorHex = InteractionCategory.meeting.defaultColor
        }

        // Add notes if available
        if let notes = event.notes, !notes.isEmpty {
            interaction.notes = notes
        }

        // Match attendees to contacts
        if let attendees = event.attendees {
            var participants: [Contact] = []

            for attendee in attendees {
                // Try to match by email
                if let email = attendee.emailAddress,
                   let contact = contactMatcher(email) {
                    participants.append(contact)
                }
                // Try to match by name
                else if let name = attendee.name,
                        let contact = contactMatcher(name) {
                    participants.append(contact)
                }
            }

            interaction.participants = participants
        }

        return interaction
    }

    /// Determine category from event properties
    private func categoryFromEvent(_ event: EKEvent) -> InteractionCategory {
        let title = event.title?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""

        // Work-related keywords
        if title.contains("meeting") || title.contains("standup") || title.contains("sync") {
            return .meeting
        }
        if title.contains("lunch") || title.contains("dinner") || title.contains("coffee") || title.contains("breakfast") {
            return .meal
        }
        if title.contains("workout") || title.contains("gym") || title.contains("run") || location.contains("gym") {
            return .exercise
        }
        if title.contains("call") || title.contains("phone") {
            return .call
        }
        if title.contains("birthday") || title.contains("party") || title.contains("celebration") {
            return .social
        }
        if title.contains("appointment") || title.contains("doctor") || title.contains("dentist") {
            return .other
        }

        return .meeting // Default
    }
}

// MARK: - UIColor Extension

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

// MARK: - Calendar Event Preview Model

struct CalendarEventPreview: Identifiable {
    let id = UUID()
    let event: EKEvent
    var isSelected: Bool = true
    var matchedContact: Contact?

    var title: String {
        event.title ?? "Untitled Event"
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if event.isAllDay {
            return "All day"
        } else {
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }
    }

    var location: String? {
        event.location
    }

    var attendeeCount: Int {
        event.attendees?.count ?? 0
    }
}
