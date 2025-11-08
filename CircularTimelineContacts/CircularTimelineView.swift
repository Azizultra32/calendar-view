import SwiftUI
import SwiftData
import UIKit

// MARK: - Selection Overlay Views

private struct NorthIndicatorView: View {
    var body: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Color.white.opacity(0.95))
                .frame(width: 6, height: 24)
                .shadow(color: Color.white.opacity(0.25), radius: 6, y: 4)
            PointerTriangle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 18, height: 10)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                .frame(width: 36, height: 36)
                .offset(y: 34)
        )
        .offset(y: -6)
    }
}

private struct PointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum SelectionCardAction {
    case call
    case message
    case openDetails
    case editInteraction
    case deleteInteraction
}

private struct ActionError: Identifiable {
    let id = UUID()
    let message: String
}

private struct SelectionCardView: View {
    let contact: Contact
    let interaction: Interaction
    let isVisible: Bool
    let onAction: (SelectionCardAction) -> Void
    let contactDetail: String
    var socialProfiles: [SocialProfile] = []  // Optional social media

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    SelectionCardHalf(
                        title: contact.name,
                        subtitle: "Contact",
                        detail: contactDetail,
                        alignment: .leading,
                        isVisible: isVisible,
                        direction: .leading
                    )

                    HStack(spacing: 12) {
                        ActionPill(
                            systemName: "phone.fill",
                            title: "Call",
                            isVisible: isVisible,
                            action: { onAction(.call) }
                        )
                        ActionPill(
                            systemName: "message.fill",
                            title: "Message",
                            isVisible: isVisible,
                            action: { onAction(.message) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 10) {
                    SelectionCardHalf(
                        title: timeRangeText,
                        subtitle: interaction.location,
                        detail: dayFormatter.string(from: interaction.startTime),
                        alignment: .trailing,
                        isVisible: isVisible,
                        direction: .trailing
                    )

                    ActionPill(
                        systemName: "calendar.badge.plus",
                        title: "Open Day",
                        isVisible: isVisible,
                        action: { onAction(.openDetails) }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)

            // Social media row (bottom)
            if !socialProfiles.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(socialProfiles.prefix(6)) { profile in
                            Button(action: {
                                SocialMediaHandler.openProfile(profile)
                            }) {
                                HStack(spacing: 6) {
                                    Text(profile.platform.emoji)
                                        .font(.system(size: 16))
                                    Text(profile.displayHandle)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: isVisible)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .blur(radius: 30)
                )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: 12)
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
    }

    private var timeRangeText: String {
        let start = timeFormatter.string(from: interaction.startTime)
        let end = timeFormatter.string(from: interaction.endTime)
        return "\(start) – \(end)"
    }
}

private struct SelectionCardHalf: View {
    enum Direction {
        case leading
        case trailing
    }
    
    let title: String
    let subtitle: String
    let detail: String
    let alignment: HorizontalAlignment
    let isVisible: Bool
    let direction: Direction

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(subtitle.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.6))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
        .offset(x: isVisible ? 0 : hiddenOffset)
        .opacity(isVisible ? 1 : 0)
    }

    private var hiddenOffset: CGFloat {
        switch direction {
        case .leading:
            return -120
        case .trailing:
            return 120
        }
    }
}

private struct ActionPill: View {
    let systemName: String
    let title: String
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(isVisible ? 1 : 0.92)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isVisible)
    }
}

private struct InteractionDetailSheet: View {
    let interaction: Interaction
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d • h:mm a"
        return formatter
    }

    private var rangeFormatter: DateIntervalFormatter {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(interaction.locationName ?? interaction.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Text(rangeFormatter.string(from: interaction.startTime, to: interaction.endTime))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))

                    Text(timeFormatter.string(from: interaction.startTime))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.5))

                    Divider().background(Color.white.opacity(0.2))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Participants")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        ForEach(interaction.participants) { contact in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(interaction.color.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(contact.initial)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    if let phone = contact.primaryPhoneNumber {
                                        Text(formattedPhone(phone))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    if let email = contact.primaryEmail, contact.primaryPhoneNumber == nil {
                                        Text(email)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.2))

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onEdit()
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            dismiss()
                            onDelete()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formattedPhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count == 10 else { return phone }
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(middle)-\(last)"
    }
}


// MARK: - Time Span Options
enum TimeSpan: CaseIterable {
    case sixHours
    case twelveHours
    case twentyFourHours
    case threeDays
    case sevenDays
    
    var hours: Int {
        switch self {
        case .sixHours: return 6
        case .twelveHours: return 12
        case .twentyFourHours: return 24
        case .threeDays: return 72
        case .sevenDays: return 168
        }
    }
    
    var displayText: String {
        switch self {
        case .sixHours: return "6H"
        case .twelveHours: return "12H"
        case .twentyFourHours: return "1D"
        case .threeDays: return "3D"
        case .sevenDays: return "7D"
        }
    }
    
    var hourInterval: Int {
        switch self {
        case .sixHours: return 1
        case .twelveHours: return 2
        case .twentyFourHours: return 3
        case .threeDays: return 6
        case .sevenDays: return 12
        }
    }
}

// MARK: - Main Circular Timeline View
struct CircularTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allInteractions: [Interaction]

    @State private var rotationAngle: Angle = .zero
    @State private var lastAngle: Angle = .zero
    @State private var isDragging = false
    @State private var velocity: Double = 0
    
    // Time tracking
    @State private var currentTimeOffset: Double = 0 // Hours from start of current day
    
    // Zoom state
    @State private var currentTimeSpan: TimeSpan = .twentyFourHours
    @State private var zoomOffset: CGFloat = 0
    @State private var isZooming = false
    
    // Navigation state
    @State private var currentDate: Date = Date()
    @State private var horizontalOffset: CGFloat = 0
    @State private var isNavigating = false
    @State private var navigationDirection: NavigationDirection = .none

    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
    @State private var passbyHaptic = UIImpactFeedbackGenerator(style: .soft)
    @State private var lastPassbyAvatar: SelectedAvatar? = nil
    @State private var lastPassbyTime: Date = .distantPast

    private struct SelectedAvatar: Equatable {
        let interactionID: UUID
        let participantIndex: Int
    }
    
    enum NavigationDirection {
        case previous
        case next
        case none
    }
    
    // Your precise mathematical constants
    private let avatarDiameter: CGFloat = 28
    private let circleRadius: CGFloat = 120
    private let containerSize: CGFloat = 300  // Total size of the view
    private let snapVelocityThreshold: Double = 0.18
    private let snapAngleThreshold: Double = .pi / 72 // ~2.5° window to snap
    private let passbyAngleWindow: Double = .pi / 140 // ~1.29° window to lightly tap on pass-by
    private let passbyVelocityGuard: Double = 0.02
    private let passbyCooldown: TimeInterval = 0.11

    // Selection constants
    private let northAngle = -Double.pi / 2  // 12 o'clock position
    private let selectionThreshold: Double = .pi / 36  // ~5° threshold for selection
    private let selectionReleaseThreshold: Double = .pi / 18  // ~10° to release selection
    private let selectionHoldDuration: TimeInterval = 0.3  // Hold time to lock selection

    private var touchAngleDegrees: Double {
        (Double(avatarDiameter) / Double(circleRadius)) * (180 / .pi) // 13.4°
    }
    
    private var overlapAngle: Double {
        touchAngleDegrees * 0.9 // 12.06° for 10% overlap
    }
    
    // Current view data
    @State private var interactions: [Interaction] = []
    @State private var previousInteractions: [Interaction] = []
    @State private var nextInteractions: [Interaction] = []

    // Selection & feedback state
    @State private var selectedAvatar: AvatarCandidate?
    @State private var pendingCandidate: AvatarCandidate?
    @State private var candidateHoldStart: Date?
    @State private var cardVisible = false
    @State private var isSnappingToSelection = false
    @State private var lastTickIndex: Int?
    @State private var actionError: ActionError?
    @State private var detailInteraction: Interaction?
    @State private var showingContactsManagement = false
    @State private var interactionToEdit: Interaction?
    @State private var showingDeleteConfirmation = false
    @State private var interactionToDelete: Interaction?
    @State private var showingProximity = false
    @State private var bluetoothManager: BluetoothManager?
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let actionFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let tickFeedback = UIImpactFeedbackGenerator(style: .light)

    private struct AvatarCandidate: Equatable {
        let interaction: Interaction
        let contact: Contact
        let participantIndex: Int
        let baseAngle: Double

        static func == (lhs: AvatarCandidate, rhs: AvatarCandidate) -> Bool {
            lhs.interaction.id == rhs.interaction.id && lhs.contact.id == rhs.contact.id && lhs.participantIndex == rhs.participantIndex
        }
    }
    
    // Computed property for hour markers based on time span
    var hourMarkersForTimeSpan: [Int] {
        switch currentTimeSpan {
        case .sixHours:
            // Show current 6-hour window
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentDate)
            let startHour = (currentHour / 6) * 6  // Round down to nearest 6-hour block
            return Array(startHour..<(startHour + 6))
        case .twelveHours:
            // Show current 12-hour window
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentDate)
            let startHour = (currentHour / 12) * 12  // Round down to nearest 12-hour block
            return stride(from: startHour, to: startHour + 12, by: 2).map { $0 }
        case .twentyFourHours:
            return stride(from: 0, to: 24, by: 3).map { $0 }
        case .threeDays:
            return stride(from: 0, to: 72, by: 6).map { $0 }
        case .sevenDays:
            return stride(from: 0, to: 168, by: 12).map { $0 }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Calendar strip at the top
                    CalendarStripView(
                        currentDate: currentDate,
                        selectedDate: $currentDate,
                        onDateSelected: { date in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentDate = date
                                updateInteractionsForCurrentDate()
                            }
                        }
                    )
                    
                    ZStack {
                        // Background
                        Color.black.ignoresSafeArea()
                        
                        // Preview wheels positioned to align with upper third of main wheel
                        HStack(alignment: .top) {
                            // Previous interval preview
                            PreviewWheelView(
                                interactions: previousInteractions,
                                radius: 40,
                                timeSpan: currentTimeSpan,
                                date: getPreviousIntervalDate(),
                                opacity: navigationDirection == .next ? 0.8 : 0.5
                            )
                            .frame(width: 80, height: 80)
                            .padding(.leading, 5)
                            .padding(.top, 50)  // Moved higher
                            .scaleEffect(navigationDirection == .next ? 1.2 : 1.0)
                            .offset(x: navigationDirection == .next ? 20 : 0)
                            
                            Spacer()
                            
                            // Next interval preview
                            PreviewWheelView(
                                interactions: nextInteractions,
                                radius: 40,
                                timeSpan: currentTimeSpan,
                                date: getNextIntervalDate(),
                                opacity: navigationDirection == .previous ? 0.8 : 0.5
                            )
                            .frame(width: 80, height: 80)
                            .padding(.trailing, 5)
                            .padding(.top, 50)  // Moved higher
                            .scaleEffect(navigationDirection == .previous ? 1.2 : 1.0)
                            .offset(x: navigationDirection == .previous ? -20 : 0)
                        }
                        
                        // Main timeline pushed down much further
                        VStack {
                            Spacer(minLength: 280)  // Adjusted to move wheel higher
                            
                            // Main timeline container
                            ZStack {
                                // Base circle (doesn't rotate) - make it more visible
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: circleRadius * 2, height: circleRadius * 2)
                                
                                // North pole indicator (12 o'clock position)
                                NorthIndicatorView()
                                    .offset(y: -circleRadius - 24)
                                
                                // Minor tick marks (simplified to prevent compiler issues)
                                ForEach(0..<60, id: \.self) { minute in
                                    Rectangle()
                                        .fill(Color.white.opacity(minute % 5 == 0 ? 0.4 : 0.2))
                                        .frame(width: minute % 5 == 0 ? 1.5 : 0.5, 
                                              height: minute % 5 == 0 ? 8 : 4)
                                        .offset(y: -circleRadius + (minute % 5 == 0 ? 4 : 2))
                                        .rotationEffect(Angle(degrees: Double(minute) * 6))
                                }
                                .rotationEffect(rotationAngle) // Rotate ticks with the wheel
                                
                                // Rotating content group (only arcs)
                                ZStack {
                                    // Interaction arcs
                                    ForEach(interactions) { interaction in
                                        let isSelectedInteraction = selectedAvatar?.interactionID == interaction.id
                                        InteractionArcView(
                                            interaction: interaction,
                                            radius: circleRadius,
                                            center: CGPoint(x: containerSize/2, y: containerSize/2),
                                            timeSpan: currentTimeSpan,
                                            currentDate: currentDate,
                                            isHighlighted: isSelectedInteraction
                                        )
                                        .opacity(navigationDirection == .none ? 1.0 : 0.55)
                                        .scaleEffect(navigationDirection == .none ? (isSelectedInteraction ? 1.01 : 1.0) : 0.95)
                                    }
                                }
                                .frame(width: containerSize, height: containerSize)
                                .rotationEffect(rotationAngle)
                                
                                // Avatar components (positioned independently)
                                ForEach(interactions) { interaction in
                                    let isSelectedInteraction = selectedAvatar?.interactionID == interaction.id
                                    let selectedParticipantIndex = isSelectedInteraction ? selectedAvatar?.participantIndex : nil
                                    AvatarGroupView(
                                        interaction: interaction,
                                        radius: circleRadius,
                                        containerSize: containerSize,
                                        overlapAngle: overlapAngle,
                                        rotation: rotationAngle,
                                        timeSpan: currentTimeSpan,
                                        currentDate: currentDate,
                                        isInteractionSelected: isSelectedInteraction,
                                        selectedParticipantIndex: selectedParticipantIndex
                                    )
                                }
                                
                                // Hour markers (stay level) - dynamic based on time span
                                ForEach(hourMarkersForTimeSpan, id: \.self) { hour in
                                    HourMarkerView(
                                        hour: hour,
                                        radius: circleRadius,
                                        containerSize: containerSize,
                                        rotation: rotationAngle,
                                        timeSpan: currentTimeSpan
                                    )
                                }
                                
                                // Note: Center content moved outside to be above gradient
                                
                                // Per-circle fade: bottom half to full black at the very bottom
                                // This overlay is clipped to the main circle only and does not
                                // affect the rest of the UI.
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: .clear, location: 0.0),
                                                .init(color: .clear, location: 0.50), // upper half fully visible
                                                .init(color: .black.opacity(0.7), location: 0.85),
                                                .init(color: .black, location: 1.0)  // bottom edge reaches black
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: circleRadius * 2, height: circleRadius * 2)
                                    .allowsHitTesting(false)
                            }
                            .frame(width: containerSize, height: containerSize)
                            .background(
                                // Larger invisible hit area for easier grabbing
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: containerSize * 1.5, height: containerSize * 1.5)
                            )
                            .contentShape(Rectangle().size(width: containerSize * 1.5, height: containerSize * 1.5))
                            .offset(x: horizontalOffset)
                            .gesture(rotationGesture)
                            
                            Spacer(minLength: 50)  // Add some bottom spacing
                        }
                    }
                }
                
                // Bottom mask to create horizon effect
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.8),
                                    Color.black,
                                    Color.black,
                                    Color.black
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * 0.4) // 40% coverage
                        .allowsHitTesting(false)
                }
                
                // Center content above gradient (immune to fade)
                CenterContentView(
                    currentTimeSpan: $currentTimeSpan,
                    isZooming: $isZooming,
                    currentDate: currentDate,
                    currentTime: getCurrentTimeDisplay(),
                    onZoomChange: { newTimeSpan in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentTimeSpan = newTimeSpan
                            updateInteractionsForCurrentDate()
                        }
                    },
                    onNavigate: { isNext in
                        if isNext {
                            navigateToNextInterval()
                        } else {
                            navigateToPreviousInterval()
                        }
                    }
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.52) // Centered on wheel

                if let selection = selectedAvatar {
                    SelectionCardView(
                        contact: selection.contact,
                        interaction: selection.interaction,
                        isVisible: cardVisible,
                        onAction: handleSelectionAction,
                        contactDetail: contactDetail(for: selection.contact),
                        socialProfiles: selection.contact.socialProfiles
                    )
                    .frame(maxWidth: 320)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.32)
                    .allowsHitTesting(cardVisible)
                }

                // Bottom-left menu buttons
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Contacts button
                        Button(action: { showingContactsManagement = true }) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                        }

                        // Proximity button
                        Button(action: { showingProximity = true }) {
                            ZStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)

                                // Badge for nearby users
                                if let manager = bluetoothManager, !manager.nearbyUsers.isEmpty {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Text("\(manager.nearbyUsers.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 15, y: -15)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(bluetoothManager?.isEnabled == true ? Color.blue.opacity(0.3) : Color.white.opacity(0.15))
                                    .overlay(Circle().stroke(bluetoothManager?.isEnabled == true ? Color.blue.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1))
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                        }

                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            hapticGenerator.prepare()
            passbyHaptic.prepare()
            setupSampleData()
            updateTickIndex()
            evaluateSelectionCandidate()

            // Initialize Bluetooth manager
            if bluetoothManager == nil {
                let userID = UUID()
                let userName = "You" // TODO: Get from user settings
                bluetoothManager = BluetoothManager(userID: userID, userName: userName)
            }
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if !isDragging && !isZooming && !isNavigating && abs(velocity) > 0.01 {
                applyMomentum()
            }
        }
        .sheet(item: $detailInteraction) { interaction in
            InteractionDetailSheet(
                interaction: interaction,
                onEdit: {
                    interactionToEdit = interaction
                },
                onDelete: {
                    interactionToDelete = interaction
                    showingDeleteConfirmation = true
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $actionError) { error in
            Alert(
                title: Text("Action Unavailable"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showingContactsManagement) {
            ContactsManagementView()
        }
        .fullScreenCover(isPresented: $showingProximity) {
            if let manager = bluetoothManager {
                ProximityView(bluetoothManager: manager)
            }
        }
        .sheet(item: $interactionToEdit) { interaction in
            InteractionEditorView(interaction: interaction)
        }
        .alert("Delete Interaction", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                interactionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let interaction = interactionToDelete {
                    deleteInteraction(interaction)
                }
            }
        } message: {
            Text("Are you sure you want to delete this interaction? This action cannot be undone.")
        }
    }

    // MARK: - Interaction Management

    private func deleteInteraction(_ interaction: Interaction) {
        modelContext.delete(interaction)
        try? modelContext.save()

        // Refresh the timeline
        interactions = getInteractionsForDate(currentDate)
        interactionToDelete = nil

        // Clear selection if we deleted the selected interaction
        if selectedAvatar?.interaction.id == interaction.id {
            clearSelection()
        }
    }
    
    // MARK: - Gesture Handling
    var rotationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    selectedAvatar = nil
                }
                isDragging = true
                if cardVisible {
                    ensureSelectionCardVisible(false)
                }
                
                let center = CGPoint(x: containerSize/2, y: containerSize/2)
                let currentAngle = angle(from: center, to: value.location)
                
                if lastAngle == .zero {
                    lastAngle = Angle(radians: currentAngle)
                }
                
                let previousAngle = lastAngle.radians
                var delta = currentAngle - previousAngle
                
                // Handle angle wraparound
                if delta > .pi {
                    delta = delta - (2.0 * .pi)
                } else if delta < -.pi {
                    delta = delta + (2.0 * .pi)
                }
                
                applyRotationDelta(delta)
                maybeTriggerPassbyHaptic()
                
                velocity = delta * 60.0 // Convert to per-second
                lastAngle = Angle(radians: currentAngle)
                evaluateSelectionCandidate()
            }
            .onEnded { _ in
                isDragging = false
                lastAngle = .zero
                if abs(velocity) < snapVelocityThreshold {
                    attemptSnapToNearestInteraction()
                }
            }
    }
    
    private func angle(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dy, dx)
    }
    
    private func applyMomentum() {
        guard !isDragging && abs(velocity) > 0.01 else { return }
        
        // Apply friction (crisper glide)
        velocity *= 0.94

        // Continue rotating
        applyRotationDelta(velocity / 60)
        maybeTriggerPassbyHaptic()
        
        if abs(velocity) < snapVelocityThreshold {
            velocity = 0
            attemptSnapToNearestInteraction()
        }
    }

    // MARK: - Subtle pass-by haptic
    private func maybeTriggerPassbyHaptic() {
        // Only while rotating with enough movement; no zoom/nav animations
        guard !isNavigating && !isZooming && abs(velocity) > passbyVelocityGuard else { return }

        let rotationRadians = rotationAngle.radians
        let northAngle = -Double.pi / 2

        var best: (interaction: TimeInteraction, participantIndex: Int, delta: Double)?
        for interaction in interactions {
            for idx in interaction.participants.indices {
                let baseAngle = angleForAvatar(in: interaction, participantIndex: idx)
                let rotated = baseAngle + rotationRadians
                let delta = minimalAngleDifference(rotated, northAngle)
                if abs(delta) < abs(best?.delta ?? .pi) {
                    best = (interaction, idx, delta)
                }
            }
        }

        guard let candidate = best else { return }

        // Do not fire if we're in snap window or if this candidate is the currently selected avatar
        if abs(candidate.delta) <= snapAngleThreshold { return }
        if let sel = selectedAvatar,
           sel.interactionID == candidate.interaction.id && sel.participantIndex == candidate.participantIndex { return }

        // Only if within the pass-by window
        guard abs(candidate.delta) <= passbyAngleWindow else { return }

        // Throttle and avoid repeated taps for the same avatar without leaving the window
        let now = Date()
        if now.timeIntervalSince(lastPassbyTime) < passbyCooldown { return }
        if let last = lastPassbyAvatar,
           last.interactionID == candidate.interaction.id && last.participantIndex == candidate.participantIndex { return }

        passbyHaptic.impactOccurred(intensity: 0.25)
        passbyHaptic.prepare()
        lastPassbyAvatar = SelectedAvatar(interactionID: candidate.interaction.id, participantIndex: candidate.participantIndex)
        lastPassbyTime = now
    }
    
    private func applyRotationDelta(_ delta: Double, animation: Animation? = nil) {
        guard delta != 0 else { return }
        let newAngle = rotationAngle + Angle(radians: delta)
        let timeChange = -delta * (Double(currentTimeSpan.hours) / (2 * .pi))
        if let animation {
            withAnimation(animation) {
                rotationAngle = newAngle
            }
        } else {
            rotationAngle = newAngle
        }
        updateTime(by: timeChange)
    }
    
    private func attemptSnapToNearestInteraction() {
        guard !isDragging else { return }
        velocity = 0
        let rotationRadians = rotationAngle.radians
        let northAngle = -Double.pi / 2
        var closestMatch: (interaction: TimeInteraction, participantIndex: Int, delta: Double)?
        
        for interaction in interactions {
            for index in interaction.participants.indices {
                let baseAngle = angleForAvatar(in: interaction, participantIndex: index)
                let rotatedAngle = baseAngle + rotationRadians
                let delta = minimalAngleDifference(rotatedAngle, northAngle)
                if abs(delta) <= snapAngleThreshold {
                    if let current = closestMatch {
                        if abs(delta) < abs(current.delta) {
                            closestMatch = (interaction, index, delta)
                        }
                    } else {
                        closestMatch = (interaction, index, delta)
                    }
                }
            }
        }
        
        guard let match = closestMatch else {
            selectedAvatar = nil
            return
        }

        if let currentSelection = selectedAvatar,
           currentSelection.interactionID == match.interaction.id,
           currentSelection.participantIndex == match.participantIndex,
           abs(match.delta) < 0.001 {
            return
        }

        let deltaToApply = -match.delta
        if abs(deltaToApply) > 0.0001 {
            let snapAnimation = Animation.timingCurve(0.33, 0.0, 0.18, 1.0, duration: 0.11)
            applyRotationDelta(deltaToApply, animation: snapAnimation)
        }
        triggerSelectionHaptic()
    }
    
    private func angleForInteraction(_ interaction: TimeInteraction) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: interaction.startTime)
        let minute = calendar.component(.minute, from: interaction.startTime)
        
        switch currentTimeSpan {
        case .sixHours:
            let currentHour = calendar.component(.hour, from: currentDate)
            let windowStart = (currentHour / 6) * 6
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            let currentHour = calendar.component(.hour, from: currentDate)
            let windowStart = (currentHour / 12) * 12
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .threeDays, .sevenDays:
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(currentTimeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }

    private func angleForAvatar(in interaction: TimeInteraction, participantIndex: Int) -> Double {
        let baseAngle = angleForInteraction(interaction)
        let overlapRadians = overlapAngle * (.pi / 180)
        return baseAngle + Double(participantIndex) * overlapRadians
    }

    private func minimalAngleDifference(_ angle1: Double, _ angle2: Double) -> Double {
        let difference = angle1 - angle2
        return atan2(sin(difference), cos(difference))
    }

    private func triggerSelectionHaptic() {
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred(intensity: 0.85)
    }
    
    // MARK: - Time Management
    private func updateTime(by hours: Double, evaluateSelection: Bool = true) {
        currentTimeOffset += hours
        
        // Handle day transitions
        let calendar = Calendar.current
        
        // Moving forward past 24 hours
        while currentTimeOffset >= 24 {
            currentTimeOffset -= 24
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
                updateInteractionsForCurrentDate()
            }
        }
        
        // Moving backward past 0 hours
        while currentTimeOffset < 0 {
            currentTimeOffset += 24
            if let prevDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = prevDay
                updateInteractionsForCurrentDate()
            }
        }

        updateTickIndex()

        if evaluateSelection {
            evaluateSelectionCandidate()
        }
    }

    private func ensureSelectionCardVisible(_ visible: Bool) {
        guard cardVisible != visible else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            cardVisible = visible
        }
    }

    private func clearSelection() {
        ensureSelectionCardVisible(false)
        selectedAvatar = nil
        pendingCandidate = nil
        candidateHoldStart = nil
        detailInteraction = nil
    }

    private func evaluateSelectionCandidate() {
        guard !isSnappingToSelection else { return }
        guard !interactions.isEmpty else { return }

        if let selection = selectedAvatar {
            let currentAngle = normalizedAngle(selection.baseAngle + rotationAngle.radians)
            let delta = normalizedAngle(currentAngle - northAngle)
            if abs(delta) > selectionReleaseThreshold {
                clearSelection()
            }
        }

        guard let candidate = nearestAvatarCandidate() else { return }

        let adjustedAngle = normalizedAngle(candidate.baseAngle + rotationAngle.radians)
        let deltaToNorth = normalizedAngle(adjustedAngle - northAngle)

        if abs(deltaToNorth) <= selectionThreshold {
            if let pending = pendingCandidate, pending == candidate {
                if let start = candidateHoldStart {
                    if Date().timeIntervalSince(start) >= selectionHoldDuration {
                        if selectedAvatar != candidate {
                            lockSelection(for: candidate, deltaToNorth: deltaToNorth)
                        } else {
                            ensureSelectionCardVisible(true)
                        }
                    }
                } else {
                    candidateHoldStart = Date()
                }
            } else {
                pendingCandidate = candidate
                candidateHoldStart = Date()
            }
        } else {
            pendingCandidate = nil
            candidateHoldStart = nil
        }
    }

    private func lockSelection(for candidate: AvatarCandidate, deltaToNorth: Double) {
        isSnappingToSelection = true
        pendingCandidate = nil
        candidateHoldStart = nil
        selectedAvatar = candidate
        selectionFeedback.prepare()

        let adjustment = -deltaToNorth
        let timeChange = -adjustment * (Double(currentTimeSpan.hours) / (2 * .pi))

        withAnimation(.interpolatingSpring(stiffness: 90, damping: 14)) {
            rotationAngle = rotationAngle + Angle(radians: adjustment)
        }

        updateTime(by: timeChange, evaluateSelection: false)
        selectionFeedback.selectionChanged()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSnappingToSelection = false
            ensureSelectionCardVisible(true)
            evaluateSelectionCandidate()
        }
    }

    private func nearestAvatarCandidate() -> AvatarCandidate? {
        var closest: AvatarCandidate?
        var smallestDelta = Double.greatestFiniteMagnitude

        for interaction in interactions {
            for (index, contact) in interaction.participants.enumerated() {
                let angle = baseAngle(for: interaction, participantIndex: index)
                let adjusted = normalizedAngle(angle + rotationAngle.radians)
                let delta = abs(normalizedAngle(adjusted - northAngle))
                if delta < smallestDelta {
                    smallestDelta = delta
                    closest = AvatarCandidate(
                        interaction: interaction,
                        contact: contact,
                        participantIndex: index,
                        baseAngle: angle
                    )
                }
            }
        }

        return closest
    }

    private func handleSelectionAction(_ action: SelectionCardAction) {
        guard let selection = selectedAvatar else { return }
        actionFeedback.prepare()
        actionFeedback.impactOccurred(intensity: 0.8)
        switch action {
        case .call:
            attemptCall(to: selection.contact)
        case .message:
            attemptMessage(to: selection.contact)
        case .openDetails:
            detailInteraction = selection.interaction
        }
    }

    private func attemptCall(to contact: Contact) {
        guard let phone = contact.primaryPhoneNumber else {
            actionError = ActionError(message: "No phone number on file for \(contact.name).")
            return
        }
        let digits = sanitizedDigits(from: phone)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            actionError = ActionError(message: "Unable to start a call to \(formattedPhoneDisplay(from: phone)).")
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                actionError = ActionError(message: "Call failed to start for \(formattedPhoneDisplay(from: phone)).")
            }
        }
    }

    private func attemptMessage(to contact: Contact) {
        if let phone = contact.primaryPhoneNumber {
            let digits = sanitizedDigits(from: phone)
            if let smsURL = URL(string: "sms:\(digits)"), !digits.isEmpty {
                UIApplication.shared.open(smsURL, options: [:]) { success in
                    if !success {
                        actionError = ActionError(message: "Message could not be started for \(formattedPhoneDisplay(from: phone)).")
                    }
                }
                return
            }
        }

        if let email = contact.primaryEmail, let mailURL = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(mailURL, options: [:]) { success in
                if !success {
                    actionError = ActionError(message: "Unable to compose message for \(contact.name).")
                }
            }
        } else {
            actionError = ActionError(message: "No messaging info available for \(contact.name).")
        }
    }

    private func contactDetail(for contact: Contact) -> String {
        if let phone = contact.primaryPhoneNumber {
            return formattedPhoneDisplay(from: phone)
        }
        if let email = contact.primaryEmail {
            return email
        }
        return contact.initial
    }

    private func formattedPhoneDisplay(from phone: String) -> String {
        let digits = sanitizedDigits(from: phone)
        guard digits.count == 10 else { return phone }
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(middle)-\(last)"
    }

    private func sanitizedDigits(from string: String) -> String {
        string.filter { $0.isNumber }
    }

    private func updateTickIndex() {
        let currentIndex = currentTickIndex()
        if let previous = lastTickIndex {
            if previous != currentIndex {
                tickFeedback.prepare()
                tickFeedback.impactOccurred(intensity: 0.45)
                lastTickIndex = currentIndex
            }
        } else {
            lastTickIndex = currentIndex
        }
    }

    private func currentTickIndex() -> Int {
        let interval = max(1, currentTimeSpan.hourInterval)
        let normalizedOffset = normalizedTimeOffset()
        return Int(floor(normalizedOffset / Double(interval)))
    }

    private func normalizedTimeOffset() -> Double {
        let span = Double(currentTimeSpan.hours)
        var offset = currentTimeOffset
        while offset < 0 { offset += span }
        while offset >= span { offset -= span }
        return offset
    }

    private func baseAngle(for interaction: TimeInteraction, participantIndex: Int) -> Double {
        angleForInteraction(interaction) + Double(participantIndex) * overlapAngle * (.pi / 180)
    }

    private func angleForInteraction(_ interaction: TimeInteraction) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: interaction.startTime)
        let minute = calendar.component(.minute, from: interaction.startTime)

        switch currentTimeSpan {
        case .sixHours:
            let windowStart = windowStartHour(for: currentTimeSpan, relativeTo: currentDate)
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            let windowStart = windowStartHour(for: currentTimeSpan, relativeTo: currentDate)
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .threeDays:
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(72 * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        case .sevenDays:
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(currentTimeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }

    private func windowStartHour(for span: TimeSpan, relativeTo date: Date) -> Int {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)

        switch span {
        case .sixHours:
            return (currentHour / 6) * 6
        case .twelveHours:
            return (currentHour / 12) * 12
        default:
            return 0
        }
    }

    private func normalizedAngle(_ angle: Double) -> Double {
        var value = angle
        while value <= -Double.pi { value += 2 * Double.pi }
        while value > Double.pi { value -= 2 * Double.pi }
        return value
    }
    
    private func getCurrentTimeDisplay() -> String {
        let hour = Int(currentTimeOffset)
        let minute = Int((currentTimeOffset - Double(hour)) * 60)
        
        if hour == 0 {
            return String(format: "12:%02d AM", minute)
        } else if hour < 12 {
            return String(format: "%d:%02d AM", hour, minute)
        } else if hour == 12 {
            return String(format: "12:%02d PM", minute)
        } else {
            return String(format: "%d:%02d PM", hour - 12, minute)
        }
    }
    
    // MARK: - Navigation Methods
    private func navigateToPreviousInterval() {
        let calendar = Calendar.current
        
        print("Navigating backwards from: \(currentDate)")
        
        // Set navigation direction for animation
        navigationDirection = .previous
        
        // Animate the transition
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            horizontalOffset = 50 // Slide effect
        }
        
        // Delay the actual date change to sync with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch self.currentTimeSpan {
            case .sixHours:
                self.currentDate = calendar.date(byAdding: .hour, value: -6, to: self.currentDate) ?? self.currentDate
            case .twelveHours:
                self.currentDate = calendar.date(byAdding: .hour, value: -12, to: self.currentDate) ?? self.currentDate
            case .twentyFourHours:
                self.currentDate = calendar.date(byAdding: .day, value: -1, to: self.currentDate) ?? self.currentDate
            case .threeDays:
                self.currentDate = calendar.date(byAdding: .day, value: -3, to: self.currentDate) ?? self.currentDate
            case .sevenDays:
                self.currentDate = calendar.date(byAdding: .day, value: -7, to: self.currentDate) ?? self.currentDate
            }
            
            print("Navigated to: \(self.currentDate)")
            
            // Update interactions with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                self.updateInteractionsForCurrentDate()
            }
            
            // Reset offset
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.horizontalOffset = 0
            }
            
            // Reset navigation direction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.navigationDirection = .none
            }
        }
    }
    
    private func navigateToNextInterval() {
        let calendar = Calendar.current
        
        // Set navigation direction for animation
        navigationDirection = .next
        
        // Animate the transition
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            horizontalOffset = -50 // Slide effect opposite direction
        }
        
        // Delay the actual date change to sync with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch self.currentTimeSpan {
            case .sixHours:
                self.currentDate = calendar.date(byAdding: .hour, value: 6, to: self.currentDate) ?? self.currentDate
            case .twelveHours:
                self.currentDate = calendar.date(byAdding: .hour, value: 12, to: self.currentDate) ?? self.currentDate
            case .twentyFourHours:
                self.currentDate = calendar.date(byAdding: .day, value: 1, to: self.currentDate) ?? self.currentDate
            case .threeDays:
                self.currentDate = calendar.date(byAdding: .day, value: 3, to: self.currentDate) ?? self.currentDate
            case .sevenDays:
                self.currentDate = calendar.date(byAdding: .day, value: 7, to: self.currentDate) ?? self.currentDate
            }
            
            // Update interactions with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                self.updateInteractionsForCurrentDate()
            }
            
            // Reset offset
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.horizontalOffset = 0
            }
            
            // Reset navigation direction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.navigationDirection = .none
            }
        }
    }
    
    private func updateInteractionsForCurrentDate() {
        clearSelection()
        lastTickIndex = nil
        // This would typically fetch new data for the current date
        // For now, we'll just update the sample data
        setupSampleData()

        // Also update adjacent intervals
        updateAdjacentIntervals()
        evaluateSelectionCandidate()
        updateTickIndex()
    }
    
    private func updateAdjacentIntervals() {
        // Get previous interval data
        let previousDate = getPreviousIntervalDate()
        previousInteractions = getSampleDataForDate(previousDate)
        
        // Get next interval data
        let nextDate = getNextIntervalDate()
        nextInteractions = getSampleDataForDate(nextDate)
    }
    
    private func getPreviousIntervalDate() -> Date {
        let calendar = Calendar.current
        
        switch currentTimeSpan {
        case .sixHours:
            return calendar.date(byAdding: .hour, value: -6, to: currentDate) ?? currentDate
        case .twelveHours:
            return calendar.date(byAdding: .hour, value: -12, to: currentDate) ?? currentDate
        case .twentyFourHours:
            return calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .threeDays:
            return calendar.date(byAdding: .day, value: -3, to: currentDate) ?? currentDate
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
        }
    }
    
    private func getNextIntervalDate() -> Date {
        let calendar = Calendar.current
        
        switch currentTimeSpan {
        case .sixHours:
            return calendar.date(byAdding: .hour, value: 6, to: currentDate) ?? currentDate
        case .twelveHours:
            return calendar.date(byAdding: .hour, value: 12, to: currentDate) ?? currentDate
        case .twentyFourHours:
            return calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        case .threeDays:
            return calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate
        case .sevenDays:
            return calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
        }
    }
    
    // MARK: - Data Loading
    private func setupSampleData() {
        interactions = getInteractionsForDate(currentDate)
    }

    private func getInteractionsForDate(_ date: Date) -> [Interaction] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Filter interactions for the specific date
        let dayInteractions = allInteractions.filter { interaction in
            // Check if interaction overlaps with the day
            interaction.startTime < endOfDay && interaction.endTime > startOfDay
        }

        return dayInteractions.sorted { $0.startTime < $1.startTime }
    }
}
