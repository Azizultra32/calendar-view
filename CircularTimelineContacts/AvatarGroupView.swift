import SwiftUI

struct AvatarGroupView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let containerSize: CGFloat
    let overlapAngle: Double
    let rotation: Angle
    let timeSpan: TimeSpan
    let currentDate: Date
    let selectedInteractionID: UUID?
    let selectedPersonID: UUID?
    
    var body: some View {
        ForEach(Array(interaction.participants.enumerated()), id: \.element.id) { index, person in
            let baseAngle = avatarAngle(for: index)
            let rotatedAngle = baseAngle + rotation.radians
            let center = CGPoint(x: containerSize/2, y: containerSize/2)
            let x = center.x + cos(rotatedAngle) * radius
            let y = center.y + sin(rotatedAngle) * radius
            
            // Single avatar with both circle and text
            let isSelected = interaction.id == selectedInteractionID && person.id == selectedPersonID
            let isSelectionActive = selectedInteractionID != nil && selectedPersonID != nil
            let baseOpacity = shouldShowAvatar(for: interaction) ? 1.0 : 0.3
            let finalOpacity = isSelected ? 1.0 : (isSelectionActive ? baseOpacity * 0.45 : baseOpacity)
            let scale = isSelected ? 1.18 : 1.0

            Text(person.initial)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(interaction.color)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.7), lineWidth: isSelected ? 3 : 2)
                                .shadow(color: isSelected ? interaction.color.opacity(0.6) : Color.clear, radius: isSelected ? 12 : 0)
                        )
                        .shadow(color: interaction.color.opacity(isSelected ? 0.6 : 0.25), radius: isSelected ? 16 : 8)
                )
                .scaleEffect(scale)
                .position(x: x, y: y)
                .rotationEffect(-rotation) // Counter-rotate AFTER positioning to stay upright
                .opacity(finalOpacity)
        }
        .frame(width: containerSize, height: containerSize)
    }
    
    private func avatarAngle(for index: Int) -> Double {
        let baseAngle = angleFromTime(interaction.startTime)
        return baseAngle + Double(index) * overlapAngle * (.pi / 180)
    }
    
    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        switch timeSpan {
        case .sixHours:
            // Get the current 6-hour window
            let windowStart = getWindowStartHour()
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            // Get the current 12-hour window
            let windowStart = getWindowStartHour()
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .threeDays:
            // For 3-day view, calculate position across 72 hours
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(72 * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        case .sevenDays:
            // For multi-day views, we need to calculate based on the full span
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(timeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }
    
    private func getWindowStartHour() -> Int {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentDate)
        
        switch timeSpan {
        case .sixHours:
            return (currentHour / 6) * 6
        case .twelveHours:
            return (currentHour / 12) * 12
        default:
            return 0
        }
    }
    
    private func shouldShowAvatar(for interaction: TimeInteraction) -> Bool {
        // Show avatar only if the interaction is within the current time span
        let calendar = Calendar.current
        let startOfTimeSpan = calendar.startOfDay(for: currentDate)
        
        return interaction.startTime >= startOfTimeSpan
    }
}
