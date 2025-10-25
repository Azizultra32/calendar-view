import SwiftUI
import UIKit

// MARK: - Data Models
struct TimeInteraction: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let participants: [Person]
    let color: Color
    let location: String
}

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
}

private struct ActionError: Identifiable {
    let id = UUID()
    let message: String
}

private struct SelectionCardView: View {
    let person: Person
    let interaction: TimeInteraction
    let isVisible: Bool
    let onAction: (SelectionCardAction) -> Void
    let contactDetail: String

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
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                SelectionCardHalf(
                    title: person.name,
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
    let interaction: TimeInteraction

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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(interaction.location)
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

                    ForEach(interaction.participants) { person in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(interaction.color.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(person.initial)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                if let phone = person.phoneNumber {
                                    Text(formattedPhone(phone))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                if let handle = person.messageHandle, person.phoneNumber == nil {
                                    Text(handle)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(Color.black.ignoresSafeArea())
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

struct Person: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let phoneNumber: String?
    let messageHandle: String?

    init(name: String, initial: String, phoneNumber: String? = nil, messageHandle: String? = nil) {
        self.name = name
        self.initial = initial
        self.phoneNumber = phoneNumber
        self.messageHandle = messageHandle
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
    
    enum NavigationDirection {
        case previous
        case next
        case none
    }
    
    // Your precise mathematical constants
    private let avatarDiameter: CGFloat = 28
    private let circleRadius: CGFloat = 120
    private let containerSize: CGFloat = 300  // Total size of the view

    private let northAngle = -Double.pi / 2
    private let selectionThreshold = Double.pi / 18 // ~10° window for snap candidate
    private let selectionReleaseThreshold = Double.pi / 8 // ~22.5° before deselection
    private let selectionHoldDuration: TimeInterval = 1.0
    
    private var touchAngleDegrees: Double {
        (Double(avatarDiameter) / Double(circleRadius)) * (180 / .pi) // 13.4°
    }
    
    private var overlapAngle: Double {
        touchAngleDegrees * 0.9 // 12.06° for 10% overlap
    }
    
    // Sample data
    @State private var interactions: [TimeInteraction] = []
    @State private var previousInteractions: [TimeInteraction] = []
    @State private var nextInteractions: [TimeInteraction] = []

    // Selection & feedback state
    @State private var pendingCandidate: AvatarCandidate?
    @State private var candidateHoldStart: Date?
    @State private var selectedAvatar: AvatarCandidate?
    @State private var cardVisible = false
    @State private var isSnappingToSelection = false
    @State private var lastTickIndex: Int?
    @State private var actionError: ActionError?
    @State private var detailInteraction: TimeInteraction?
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let actionFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let tickFeedback = UIImpactFeedbackGenerator(style: .light)

    private struct AvatarCandidate: Equatable {
        let interaction: TimeInteraction
        let person: Person
        let participantIndex: Int
        let baseAngle: Double

        static func == (lhs: AvatarCandidate, rhs: AvatarCandidate) -> Bool {
            lhs.interaction.id == rhs.interaction.id && lhs.person.id == rhs.person.id && lhs.participantIndex == rhs.participantIndex
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
                            .padding(.top, 80)  // Much higher
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
                            .padding(.top, 80)  // Much higher
                            .scaleEffect(navigationDirection == .previous ? 1.2 : 1.0)
                            .offset(x: navigationDirection == .previous ? -20 : 0)
                        }
                        
                        // Main timeline pushed down much further
                        VStack {
                            Spacer(minLength: 350)  // Increased significantly to push wheel much lower
                            
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
                                        InteractionArcView(
                                            interaction: interaction,
                                            radius: circleRadius,
                                            center: CGPoint(x: containerSize/2, y: containerSize/2),
                                            timeSpan: currentTimeSpan,
                                            currentDate: currentDate
                                        )
                                        .opacity(navigationDirection == .none ? 1.0 : 0.5)
                                        .scaleEffect(navigationDirection == .none ? 1.0 : 0.95)
                                    }
                                }
                                .frame(width: containerSize, height: containerSize)
                                .rotationEffect(rotationAngle)
                                
                                // Avatar components (positioned independently)
                                ForEach(interactions) { interaction in
                                    AvatarGroupView(
                                        interaction: interaction,
                                        radius: circleRadius,
                                        containerSize: containerSize,
                                        overlapAngle: overlapAngle,
                                        rotation: rotationAngle,
                                        timeSpan: currentTimeSpan,
                                        currentDate: currentDate,
                                        selectedInteractionID: selectedAvatar?.interaction.id,
                                        selectedPersonID: selectedAvatar?.person.id
                                    )
                                    .opacity(navigationDirection == .none ? 1.0 : 0.3)
                                    .scaleEffect(navigationDirection == .none ? 1.0 : 0.9)
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
                .position(x: geometry.size.width / 2, y: geometry.size.height - 250) // Move higher away from gradient

                if let selection = selectedAvatar {
                    SelectionCardView(
                        person: selection.person,
                        interaction: selection.interaction,
                        isVisible: cardVisible,
                        onAction: handleSelectionAction,
                        contactDetail: contactDetail(for: selection.person)
                    )
                    .frame(maxWidth: 320)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.32)
                    .allowsHitTesting(cardVisible)
                }
            }
        }
        .onAppear {
            selectionFeedback.prepare()
            actionFeedback.prepare()
            tickFeedback.prepare()
            setupSampleData()
            updateTickIndex()
            evaluateSelectionCandidate()
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if !isDragging && !isZooming && !isNavigating && abs(velocity) > 0.01 {
                applyMomentum()
            }
        }
        .sheet(item: $detailInteraction) { interaction in
            InteractionDetailSheet(interaction: interaction)
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
    }
    
    // MARK: - Gesture Handling
    var rotationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
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
                
                let deltaAngle = Angle(radians: delta)
                rotationAngle = rotationAngle + deltaAngle
                
                // Convert rotation to time change
                // Clockwise (negative delta) = backwards in time
                // Counterclockwise (positive delta) = forwards in time
                let timeChange = -delta * (Double(currentTimeSpan.hours) / (2 * .pi))
                updateTime(by: timeChange)
                
                velocity = delta * 60.0 // Convert to per-second
                lastAngle = Angle(radians: currentAngle)
                evaluateSelectionCandidate()
            }
            .onEnded { _ in
                isDragging = false
                lastAngle = .zero
                candidateHoldStart = nil
            }
    }
    
    private func angle(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dy, dx)
    }
    
    private func applyMomentum() {
        guard !isDragging && abs(velocity) > 0.01 else { return }
        
        // Apply friction
        velocity *= 0.95
        
        // Continue rotating
        let deltaAngle = Angle(radians: velocity / 60)
        rotationAngle = rotationAngle + deltaAngle
        
        // Continue time updates
        let timeChange = -(velocity / 60) * (Double(currentTimeSpan.hours) / (2 * .pi))
        updateTime(by: timeChange)
        evaluateSelectionCandidate()
        
        if abs(velocity) < 0.01 {
            velocity = 0
        }
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
            for (index, person) in interaction.participants.enumerated() {
                let angle = baseAngle(for: interaction, participantIndex: index)
                let adjusted = normalizedAngle(angle + rotationAngle.radians)
                let delta = abs(normalizedAngle(adjusted - northAngle))
                if delta < smallestDelta {
                    smallestDelta = delta
                    closest = AvatarCandidate(
                        interaction: interaction,
                        person: person,
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
            attemptCall(to: selection.person)
        case .message:
            attemptMessage(to: selection.person)
        case .openDetails:
            detailInteraction = selection.interaction
        }
    }

    private func attemptCall(to person: Person) {
        guard let phone = person.phoneNumber else {
            actionError = ActionError(message: "No phone number on file for \(person.name).")
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

    private func attemptMessage(to person: Person) {
        if let phone = person.phoneNumber {
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

        if let handle = person.messageHandle, let mailURL = URL(string: "mailto:\(handle)") {
            UIApplication.shared.open(mailURL, options: [:]) { success in
                if !success {
                    actionError = ActionError(message: "Unable to compose message for \(person.name).")
                }
            }
        } else {
            actionError = ActionError(message: "No messaging info available for \(person.name).")
        }
    }

    private func contactDetail(for person: Person) -> String {
        if let phone = person.phoneNumber {
            return formattedPhoneDisplay(from: phone)
        }
        if let handle = person.messageHandle {
            return handle
        }
        return person.initial
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
    
    // MARK: - Sample Data
    private func setupSampleData() {
        interactions = getSampleDataForDate(currentDate)
    }
    
    private func getSampleDataForDate(_ date: Date) -> [TimeInteraction] {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayOfMonth = calendar.component(.day, from: date)

        func samplePerson(_ name: String, initial: String, index: Int) -> Person {
            let digits = String(format: "55501%05d", index)
            let handleBase = name.lowercased().replacingOccurrences(of: " ", with: "")
            return Person(
                name: name,
                initial: initial,
                phoneNumber: digits,
                messageHandle: "\(handleBase)@timeline.app"
            )
        }

        // Create people
        let sarah = samplePerson("Sarah", initial: "S", index: 1)
        let mike = samplePerson("Mike", initial: "M", index: 2)
        let alex = samplePerson("Alex", initial: "A", index: 3)
        let emma = samplePerson("Emma", initial: "E", index: 4)
        let jake = samplePerson("Jake", initial: "J", index: 5)
        let lisa = samplePerson("Lisa", initial: "L", index: 6)
        let david = samplePerson("David", initial: "D", index: 7)
        let chris = samplePerson("Chris", initial: "C", index: 8)
        let maya = samplePerson("Maya", initial: "Y", index: 9)
        let tom = samplePerson("Tom", initial: "T", index: 10)
        let nina = samplePerson("Nina", initial: "N", index: 11)
        let sam = samplePerson("Sam", initial: "R", index: 12)
        let kate = samplePerson("Kate", initial: "K", index: 13)
        let ben = samplePerson("Ben", initial: "B", index: 14)
        let olivia = samplePerson("Olivia", initial: "O", index: 15)
        
        var interactions: [TimeInteraction] = []
        
        // Different events based on day of week
        switch dayOfWeek {
        case 1: // Sunday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!,
                participants: [sarah, mike, emma],
                color: Color.blue,
                location: "Brunch at Marina"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!,
                participants: [alex, jake],
                color: Color.purple,
                location: "Basketball Game"
            ))
            
        case 2: // Monday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                participants: [david, lisa],
                color: Color.green,
                location: "Team Standup"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date)!,
                participants: [chris],
                color: Color.orange,
                location: "Client Call"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: date)!,
                participants: [maya, tom, nina],
                color: Color.red,
                location: "Project Review"
            ))
            
        case 3: // Tuesday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date)!,
                participants: [ben],
                color: Color.cyan,
                location: "Morning Run"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!,
                participants: [kate, olivia],
                color: Color.pink,
                location: "Design Review"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!,
                participants: [sarah, alex, emma, jake],
                color: Color.green.opacity(0.7),
                location: "Team Dinner"
            ))
            
        case 4: // Wednesday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date)!,
                participants: [mike, david, chris],
                color: Color.indigo,
                location: "Strategy Meeting"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: date)!,
                participants: [lisa],
                color: Color.yellow,
                location: "Doctor Appointment"
            ))
            
        case 5: // Thursday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: date)!,
                participants: [sarah, mike],
                color: Color.green,
                location: "Coffee Chat"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!,
                participants: [alex, emma, jake, lisa],
                color: Color.green.opacity(0.8),
                location: "Team Lunch"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!,
                participants: [tom, nina, sam],
                color: Color.purple.opacity(0.8),
                location: "Code Review"
            ))
            
        case 6: // Friday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date)!,
                participants: [david],
                color: Color.blue,
                location: "1:1 with Manager"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date)!,
                participants: [chris, maya],
                color: Color.orange.opacity(0.7),
                location: "Sprint Planning"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date)!,
                participants: [sarah, mike, alex, emma, jake],
                color: Color.green.opacity(0.6),
                location: "Happy Hour"
            ))
            
        case 7: // Saturday
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date)!,
                participants: [kate, ben, olivia],
                color: Color.mint,
                location: "Farmers Market"
            ))
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date)!,
                participants: [chris, maya, tom, nina, sam],
                color: Color.red.opacity(0.8),
                location: "Birthday Party"
            ))
            
        default:
            break
        }
        
        // Add some variation based on day of month
        if dayOfMonth % 5 == 0 {
            // Every 5th day, add a morning workout
            interactions.append(TimeInteraction(
                startTime: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date)!,
                endTime: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date)!,
                participants: [ben, jake],
                color: Color.teal,
                location: "Gym"
            ))
        }
        
        return interactions
    }
}
