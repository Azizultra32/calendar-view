import SwiftUI
import SwiftData
import EventKit

/// View for syncing iOS Calendar events to the timeline
struct CalendarSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]

    @State private var calendarManager: CalendarManager
    @State private var syncStatus: SyncStatus = .idle
    @State private var previewEvents: [CalendarEventPreview] = []
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingAccessDenied = false
    @State private var importedCount = 0

    enum SyncStatus {
        case idle
        case requestingAccess
        case loading
        case previewing
        case syncing
        case completed
        case error(String)
    }

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Next 7 Days"
        case month = "Next 30 Days"

        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }

    init(calendarManager: CalendarManager) {
        _calendarManager = State(initialValue: calendarManager)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status header
                    statusHeader

                    // Main content
                    switch syncStatus {
                    case .idle:
                        idleStateView
                    case .requestingAccess, .loading:
                        loadingView
                    case .previewing:
                        previewListView
                    case .syncing:
                        syncingView
                    case .completed:
                        completedView
                    case .error(let message):
                        errorView(message: message)
                    }
                }
            }
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }

                if case .previewing = syncStatus {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Import") {
                            performSync()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Calendar Access Required", isPresented: $showingAccessDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable Calendar access in Settings to sync events to your timeline.")
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        VStack(spacing: 12) {
            if let lastSync = calendarManager.lastSyncDate {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Last synced \(timeAgo(from: lastSync))")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Idle State

    private var idleStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Sync Your Calendar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Import meetings and events from your iOS Calendar to see them on your timeline.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Time range picker
            VStack(spacing: 16) {
                Text("Select Time Range")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 12) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(action: {
                            selectedTimeRange = range
                        }) {
                            Text(range.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTimeRange == range ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTimeRange == range ? Color.blue : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }

            Button(action: requestAccessAndPreview) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Preview Events")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            Text("Loading calendar events...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview List

    private var previewListView: some View {
        VStack(spacing: 0) {
            // Summary
            HStack {
                Text("\(previewEvents.filter(\.isSelected).count) of \(previewEvents.count) events selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button(action: toggleAllEvents) {
                    Text(allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))

            // Event list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($previewEvents) { $preview in
                        CalendarEventPreviewCard(preview: $preview)
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Syncing View

    private var syncingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            Text("Importing \(previewEvents.filter(\.isSelected).count) events...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Sync Complete!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Imported \(importedCount) event\(importedCount == 1 ? "" : "s") to your timeline.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Text("Sync Failed")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: { syncStatus = .idle }) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Actions

    private func requestAccessAndPreview() {
        syncStatus = .requestingAccess

        Task {
            let hasAccess = calendarManager.checkAccess() || await calendarManager.requestAccess()

            if hasAccess {
                await loadPreview()
            } else {
                showingAccessDenied = true
                syncStatus = .idle
            }
        }
    }

    private func loadPreview() async {
        syncStatus = .loading

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: selectedTimeRange.days, to: startDate)!

        let events = calendarManager.fetchEvents(from: startDate, to: endDate)

        previewEvents = events.map { event in
            var preview = CalendarEventPreview(event: event)

            // Try to match attendees to contacts
            if let attendees = event.attendees {
                for attendee in attendees {
                    if let email = attendee.emailAddress,
                       let contact = contacts.first(where: { contact in
                           contact.emailAddresses.contains(where: { $0.email == email })
                       }) {
                        preview.matchedContact = contact
                        break
                    }
                }
            }

            return preview
        }

        syncStatus = .previewing
    }

    private func performSync() {
        syncStatus = .syncing

        Task {
            let selectedEvents = previewEvents.filter(\.isSelected)

            var imported = 0
            for preview in selectedEvents {
                let interaction = createInteraction(from: preview.event, matchedContact: preview.matchedContact)
                modelContext.insert(interaction)
                imported += 1
            }

            try? modelContext.save()

            importedCount = imported
            calendarManager.lastSyncDate = Date()

            syncStatus = .completed
        }
    }

    private func createInteraction(from event: EKEvent, matchedContact: Contact?) -> Interaction {
        let interaction = Interaction(
            startTime: event.startDate,
            endTime: event.endDate,
            title: event.title ?? "Untitled Event",
            category: categoryFromEvent(event),
            isAllDay: event.isAllDay,
            locationName: event.location
        )

        interaction.externalSource = "Calendar"
        interaction.calendarEventIdentifier = event.eventIdentifier
        interaction.notes = event.notes

        // Set color from calendar
        if let calendarColor = event.calendar.cgColor {
            let uiColor = UIColor(cgColor: calendarColor)
            interaction.colorHex = uiColor.toHexString()
        }

        // Add matched contact as participant
        if let contact = matchedContact {
            interaction.participants = [contact]
        }

        return interaction
    }

    private func categoryFromEvent(_ event: EKEvent) -> InteractionCategory {
        let title = event.title?.lowercased() ?? ""

        if title.contains("lunch") || title.contains("dinner") || title.contains("coffee") {
            return .meal
        }
        if title.contains("workout") || title.contains("gym") {
            return .exercise
        }
        if title.contains("call") {
            return .call
        }

        return .meeting
    }

    // MARK: - Helpers

    private var allSelected: Bool {
        previewEvents.allSatisfy(\.isSelected)
    }

    private func toggleAllEvents() {
        let newValue = !allSelected
        for index in previewEvents.indices {
            previewEvents[index].isSelected = newValue
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Calendar Event Preview Card

private struct CalendarEventPreviewCard: View {
    @Binding var preview: CalendarEventPreview

    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox
            Button(action: { preview.isSelected.toggle() }) {
                Image(systemName: preview.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(preview.isSelected ? .blue : .white.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(preview.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(preview.timeRange)
                            .font(.system(size: 14))
                    }

                    if let location = preview.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(location)
                                .font(.system(size: 14))
                                .lineLimit(1)
                        }
                    }
                }
                .foregroundColor(.white.opacity(0.6))

                if let contact = preview.matchedContact {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text("with \(contact.name)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
