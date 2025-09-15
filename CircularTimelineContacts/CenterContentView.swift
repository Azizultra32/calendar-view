import SwiftUI

struct CenterContentView: View {
    @Binding var currentTimeSpan: TimeSpan
    @Binding var isZooming: Bool
    let currentDate: Date
    let currentTime: String
    let onZoomChange: (TimeSpan) -> Void
    let onNavigate: (Bool) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isNavigating = false
    
    private var dayOfWeekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Short day name like "SUN"
        return formatter
    }
    
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy" // Full date like "September 3, 2025"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(currentTime)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(dayOfWeekFormatter.string(from: currentDate).uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Text(currentTimeSpan.displayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .offset(y: dragOffset)
        .scaleEffect(isZooming || isNavigating ? 0.95 : 1.0)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Determine if it's primarily vertical or horizontal
                    if abs(value.translation.height) > abs(value.translation.width) {
                        // Vertical swipe - zoom
                        isZooming = true
                        dragOffset = value.translation.height * 0.2
                    } else {
                        // Horizontal swipe - navigate
                        isNavigating = true
                        dragOffset = value.translation.width * 0.2
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    
                    if abs(value.translation.height) > abs(value.translation.width) {
                        // Vertical swipe
                        if value.translation.height > threshold {
                            switchToShorterTimeSpan()
                        } else if value.translation.height < -threshold {
                            switchToLongerTimeSpan()
                        }
                    } else {
                        // Horizontal swipe
                        if value.translation.width > threshold {
                            navigateToPreviousInterval()
                        } else if value.translation.width < -threshold {
                            navigateToNextInterval()
                        }
                    }
                    
                    withAnimation(.spring()) {
                        dragOffset = 0
                        isZooming = false
                        isNavigating = false
                    }
                }
        )
    }
    
    private func getTimeRangeText() -> String {
        let calendar = Calendar.current
        
        switch currentTimeSpan {
        case .sixHours:
            let currentHour = calendar.component(.hour, from: currentDate)
            let startHour = (currentHour / 6) * 6
            let endHour = startHour + 6
            return formatTimeRange(startHour, endHour)
        case .twelveHours:
            let currentHour = calendar.component(.hour, from: currentDate)
            let startHour = (currentHour / 12) * 12
            let endHour = startHour + 12
            return formatTimeRange(startHour, endHour)
        case .twentyFourHours:
            return "1D"
        case .sevenDays:
            return "7D"
        }
    }
    
    private func formatTimeRange(_ startHour: Int, _ endHour: Int) -> String {
        let startStr: String
        let endStr: String
        
        // Format start hour
        if startHour == 0 {
            startStr = "12AM"
        } else if startHour < 12 {
            startStr = "\(startHour)AM"
        } else if startHour == 12 {
            startStr = "12PM"
        } else {
            startStr = "\(startHour - 12)PM"
        }
        
        // Format end hour
        if endHour == 24 || endHour == 0 {
            endStr = "12AM"
        } else if endHour < 12 {
            endStr = "\(endHour)AM"
        } else if endHour == 12 {
            endStr = "12PM"
        } else {
            endStr = "\(endHour - 12)PM"
        }
        
        return "\(startStr) - \(endStr)"
    }
    
    private func switchToShorterTimeSpan() {
        let allCases = TimeSpan.allCases
        if let currentIndex = allCases.firstIndex(of: currentTimeSpan),
           currentIndex > 0 {
            let newTimeSpan = allCases[currentIndex - 1]
            withAnimation(.easeInOut(duration: 0.4)) {
                currentTimeSpan = newTimeSpan
                onZoomChange(newTimeSpan)
            }
        }
    }
    
    private func switchToLongerTimeSpan() {
        let allCases = TimeSpan.allCases
        if let currentIndex = allCases.firstIndex(of: currentTimeSpan),
           currentIndex < allCases.count - 1 {
            let newTimeSpan = allCases[currentIndex + 1]
            withAnimation(.easeInOut(duration: 0.4)) {
                currentTimeSpan = newTimeSpan
                onZoomChange(newTimeSpan)
            }
        }
    }
    
    private func navigateToPreviousInterval() {
        onNavigate(false)
    }
    
    private func navigateToNextInterval() {
        onNavigate(true)
    }
}