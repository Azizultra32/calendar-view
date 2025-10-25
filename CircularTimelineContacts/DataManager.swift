import SwiftUI
import SwiftData
import Foundation

/// Main data management class for CRUD operations and business logic
@Observable
final class DataManager {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Contact Operations

    func createContact(_ contact: Contact) throws {
        modelContext.insert(contact)
        try modelContext.save()
    }

    func fetchAllContacts() -> [Contact] {
        let descriptor = FetchDescriptor<Contact>(sortBy: [SortDescriptor(\Contact.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchContacts(matching predicate: Predicate<Contact>?) -> [Contact] {
        var descriptor = FetchDescriptor<Contact>(sortBy: [SortDescriptor(\Contact.name)])
        descriptor.predicate = predicate
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchFavoriteContacts() -> [Contact] {
        fetchContacts(matching: #Predicate { $0.isFavorite == true })
    }

    func searchContacts(query: String) -> [Contact] {
        fetchContacts(matching: #Predicate { contact in
            contact.name.localizedStandardContains(query)
        })
    }

    func updateContact(_ contact: Contact) throws {
        contact.updateTimestamp()
        try modelContext.save()
    }

    func deleteContact(_ contact: Contact) throws {
        modelContext.delete(contact)
        try modelContext.save()
    }

    // MARK: - Interaction Operations

    func createInteraction(_ interaction: Interaction) throws {
        modelContext.insert(interaction)
        try modelContext.save()
    }

    func fetchAllInteractions() -> [Interaction] {
        let descriptor = FetchDescriptor<Interaction>(sortBy: [SortDescriptor(\Interaction.startTime)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchInteractions(from startDate: Date, to endDate: Date) -> [Interaction] {
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { interaction in
                interaction.startTime >= startDate && interaction.endTime <= endDate
            },
            sortBy: [SortDescriptor(\Interaction.startTime)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchInteractions(for contact: Contact) -> [Interaction] {
        // Filter interactions where this contact is a participant
        contact.interactions.sorted { $0.startTime < $1.startTime }
    }

    func fetchInteractions(at location: Location) -> [Interaction] {
        location.interactions.sorted { $0.startTime < $1.startTime }
    }

    func fetchInteractions(category: InteractionCategory) -> [Interaction] {
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\Interaction.startTime)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func updateInteraction(_ interaction: Interaction) throws {
        interaction.updateTimestamp()
        try modelContext.save()
    }

    func deleteInteraction(_ interaction: Interaction) throws {
        modelContext.delete(interaction)
        try modelContext.save()
    }

    // MARK: - Location Operations

    func createLocation(_ location: Location) throws {
        modelContext.insert(location)
        try modelContext.save()
    }

    func fetchAllLocations() -> [Location] {
        let descriptor = FetchDescriptor<Location>(sortBy: [SortDescriptor(\Location.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchFavoriteLocations() -> [Location] {
        let descriptor = FetchDescriptor<Location>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\Location.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func findOrCreateLocation(name: String, category: LocationCategory = .other) throws -> Location {
        // Try to find existing location
        let descriptor = FetchDescriptor<Location>(
            predicate: #Predicate { $0.name == name }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        // Create new location
        let location = Location(name: name, category: category)
        modelContext.insert(location)
        try modelContext.save()
        return location
    }

    func updateLocation(_ location: Location) throws {
        location.updateTimestamp()
        try modelContext.save()
    }

    func deleteLocation(_ location: Location) throws {
        modelContext.delete(location)
        try modelContext.save()
    }

    // MARK: - Note Operations

    func createNote(_ note: Note, for contact: Contact) throws {
        note.contact = contact
        modelContext.insert(note)
        try modelContext.save()
    }

    func fetchNotes(for contact: Contact) -> [Note] {
        contact.customNotes.sorted()
    }

    func fetchPinnedNotes() -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.isPinned == true }
        )
        return (try? modelContext.fetch(descriptor))?.sorted() ?? []
    }

    func updateNote(_ note: Note) throws {
        note.updateTimestamp()
        try modelContext.save()
    }

    func deleteNote(_ note: Note) throws {
        modelContext.delete(note)
        try modelContext.save()
    }

    // MARK: - Batch Operations

    func createInteractions(_ interactions: [Interaction]) throws {
        for interaction in interactions {
            modelContext.insert(interaction)
        }
        try modelContext.save()
    }

    func deleteAllData() throws {
        // Delete all interactions
        let interactions = fetchAllInteractions()
        for interaction in interactions {
            modelContext.delete(interaction)
        }

        // Delete all contacts
        let contacts = fetchAllContacts()
        for contact in contacts {
            modelContext.delete(contact)
        }

        // Delete all locations
        let locations = fetchAllLocations()
        for location in locations {
            modelContext.delete(location)
        }

        try modelContext.save()
    }

    // MARK: - Analytics & Statistics

    func totalInteractionCount() -> Int {
        let descriptor = FetchDescriptor<Interaction>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func totalContactCount() -> Int {
        let descriptor = FetchDescriptor<Contact>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func mostFrequentContacts(limit: Int = 10) -> [Contact] {
        fetchAllContacts()
            .sorted { $0.interactionCount > $1.interactionCount }
            .prefix(limit)
            .map { $0 }
    }

    func mostVisitedLocations(limit: Int = 10) -> [Location] {
        fetchAllLocations()
            .sorted { $0.visitCount > $1.visitCount }
            .prefix(limit)
            .map { $0 }
    }

    func totalTimeSpent(with contact: Contact) -> TimeInterval {
        contact.totalTimeSpent
    }

    func totalTimeSpent(at location: Location) -> TimeInterval {
        location.totalTimeSpent
    }

    func interactionCountByCategory() -> [InteractionCategory: Int] {
        let interactions = fetchAllInteractions()
        var counts: [InteractionCategory: Int] = [:]

        for interaction in interactions {
            counts[interaction.category, default: 0] += 1
        }

        return counts
    }

    // MARK: - Date Range Queries

    func interactionsToday() -> [Interaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return fetchInteractions(from: today, to: tomorrow)
    }

    func interactionsThisWeek() -> [Interaction] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        return fetchInteractions(from: weekStart, to: weekEnd)
    }

    func interactionsThisMonth() -> [Interaction] {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        return fetchInteractions(from: monthStart, to: monthEnd)
    }

    // MARK: - Upcoming & Recent

    func upcomingInteractions(limit: Int = 10) -> [Interaction] {
        let now = Date()
        var descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.startTime > now },
            sortBy: [SortDescriptor(\Interaction.startTime)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func recentInteractions(limit: Int = 10) -> [Interaction] {
        let now = Date()
        var descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.endTime < now },
            sortBy: [SortDescriptor(\Interaction.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Search & Filters

    func searchInteractions(query: String) -> [Interaction] {
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { interaction in
                interaction.title.localizedStandardContains(query) ||
                (interaction.notes?.localizedStandardContains(query) ?? false) ||
                (interaction.locationName?.localizedStandardContains(query) ?? false)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func interactionsWith(tag: String) -> [Interaction] {
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { interaction in
                interaction.tags.contains(tag)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Convenience Extensions
extension DataManager {
    /// Creates a contact and immediately adds interactions for them
    func createContactWithInteractions(
        name: String,
        interactions: [(startTime: Date, endTime: Date, title: String, category: InteractionCategory)]
    ) throws -> Contact {
        let contact = Contact(name: name)
        modelContext.insert(contact)

        for interactionData in interactions {
            let interaction = Interaction(
                startTime: interactionData.startTime,
                endTime: interactionData.endTime,
                title: interactionData.title,
                category: interactionData.category
            )
            interaction.addParticipant(contact)
            modelContext.insert(interaction)
        }

        try modelContext.save()
        return contact
    }

    /// Quick method to add an interaction between contacts
    func quickInteraction(
        with contacts: [Contact],
        title: String,
        from startTime: Date,
        duration: TimeInterval,
        category: InteractionCategory = .social,
        location: String? = nil
    ) throws -> Interaction {
        let endTime = startTime.addingTimeInterval(duration)

        let interaction = Interaction(
            startTime: startTime,
            endTime: endTime,
            title: title,
            category: category,
            locationName: location
        )

        for contact in contacts {
            interaction.addParticipant(contact)
        }

        modelContext.insert(interaction)
        try modelContext.save()

        return interaction
    }
}
