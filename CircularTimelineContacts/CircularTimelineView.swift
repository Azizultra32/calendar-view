import SwiftUI

// MARK: - Data Models
struct TimeInteraction: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let participants: [Person]
    let color: Color
    let location: String
}

struct Person: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
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
                                // Base circle (doesn't rotate) - make it more visible for debugging
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 3)
                                    .frame(width: circleRadius * 2, height: circleRadius * 2)
                                
                                // North pole indicator (12 o'clock position)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 2, height: 15)
                                    .offset(y: -circleRadius - 7.5)
                                
                                // Minor tick marks based on time span
                                ZStack {
                                    let tickCount = timeSpan == .sixHours || timeSpan == .twelveHours ? 60 : 
                                                   timeSpan == .twentyFourHours ? 96 : 60
                                    let tickInterval = 360.0 / Double(tickCount)
                                    
                                    ForEach(0..<tickCount, id: \.self) { tick in
                                        Rectangle()
                                            .fill(Color.white.opacity(tick % 4 == 0 ? 0.5 : 0.2))
                                            .frame(width: tick % 4 == 0 ? 1.5 : 0.5, 
                                                  height: tick % 4 == 0 ? 8 : 4)
                                            .offset(y: -circleRadius + (tick % 4 == 0 ? 4 : 2))
                                            .rotationEffect(Angle(degrees: Double(tick) * tickInterval))
                                    }
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
                                        currentDate: currentDate
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
                .position(x: geometry.size.width / 2, y: geometry.size.height - 150) // Position in visible area
            }
        }
        .onAppear {
            setupSampleData()
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if !isDragging && !isZooming && !isNavigating && abs(velocity) > 0.01 {
                applyMomentum()
            }
        }
    }
    
    // MARK: - Gesture Handling
    var rotationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                
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
            }
            .onEnded { _ in
                isDragging = false
                lastAngle = .zero
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
        
        if abs(velocity) < 0.01 {
            velocity = 0
        }
    }
    
    // MARK: - Time Management
    private func updateTime(by hours: Double) {
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
        // This would typically fetch new data for the current date
        // For now, we'll just update the sample data
        setupSampleData()
        
        // Also update adjacent intervals
        updateAdjacentIntervals()
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
        
        // Create people
        let sarah = Person(name: "Sarah", initial: "S")
        let mike = Person(name: "Mike", initial: "M")
        let alex = Person(name: "Alex", initial: "A")
        let emma = Person(name: "Emma", initial: "E")
        let jake = Person(name: "Jake", initial: "J")
        let lisa = Person(name: "Lisa", initial: "L")
        let david = Person(name: "David", initial: "D")
        let chris = Person(name: "Chris", initial: "C")
        let maya = Person(name: "Maya", initial: "Y")
        let tom = Person(name: "Tom", initial: "T")
        let nina = Person(name: "Nina", initial: "N")
        let sam = Person(name: "Sam", initial: "R")
        let kate = Person(name: "Kate", initial: "K")
        let ben = Person(name: "Ben", initial: "B")
        let olivia = Person(name: "Olivia", initial: "O")
        
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
