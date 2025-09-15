import SwiftUI

struct PreviewWheelView: View {
    let interactions: [TimeInteraction]
    let radius: CGFloat
    let timeSpan: TimeSpan
    let date: Date
    let opacity: Double
    
    private let dotSize: CGFloat = 8
    private var enhancedDotSize: CGFloat {
        opacity > 0.5 ? 10 : 8
    }
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
            
            // Interaction dots with enhanced size during transition
            ForEach(interactions) { interaction in
                PreviewDotView(
                    interaction: interaction,
                    radius: radius,
                    dotSize: enhancedDotSize,
                    timeSpan: timeSpan,
                    date: date
                )
                .animation(.easeInOut(duration: 0.3), value: opacity)
            }
            
            // Date label
            VStack(spacing: 0) {
                Text(dayOfWeek(from: date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(dayOfMonth(from: date))
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .opacity(opacity)
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct PreviewDotView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let dotSize: CGFloat
    let timeSpan: TimeSpan
    let date: Date
    
    private var position: CGPoint {
        let angle = angleFromTime(interaction.startTime)
        let center = CGPoint(x: radius, y: radius)
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Circle()
            .fill(interaction.color.opacity(0.7))
            .frame(width: dotSize, height: dotSize)
            .position(position)
            .frame(width: radius * 2, height: radius * 2)
    }
    
    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        switch timeSpan {
        case .sixHours:
            let currentHour = calendar.component(.hour, from: date)
            let windowStart = (currentHour / 6) * 6
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            let currentHour = calendar.component(.hour, from: date)
            let windowStart = (currentHour / 12) * 12
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .sevenDays:
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(timeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }
}