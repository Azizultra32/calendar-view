import SwiftUI

struct AvatarGroupView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let containerSize: CGFloat
    let overlapAngle: Double
    let rotation: Angle
    let timeSpan: TimeSpan
    let currentDate: Date
    
    var body: some View {
        ForEach(Array(interaction.participants.enumerated()), id: \.element.id) { index, person in
            let baseAngle = avatarAngle(for: index)
            let rotatedAngle = baseAngle + rotation.radians
            let center = CGPoint(x: containerSize/2, y: containerSize/2)
            let x = center.x + cos(rotatedAngle) * radius
            let y = center.y + sin(rotatedAngle) * radius
            
            // Single avatar with both circle and text
            Text(person.initial)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(interaction.color)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                )
                .position(x: x, y: y)
                .opacity(shouldShowAvatar(for: interaction) ? 1.0 : 0.3)
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
        case .threeDays, .sevenDays:
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
