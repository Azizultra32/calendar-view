import SwiftUI

struct InteractionArcView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let center: CGPoint
    let timeSpan: TimeSpan
    let currentDate: Date
    let isHighlighted: Bool

    // Always visible; selected arc is subtly emphasized
    private var lineWidth: CGFloat { isHighlighted ? 10 : 7 }
    private var arcOpacity: Double { 1.0 }  // Always visible at full opacity

    var body: some View {
        let startAngle = angleFromTime(interaction.startTime)
        let endAngle = angleFromTime(interaction.endTime)

        Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(radians: startAngle),
                endAngle: Angle(radians: endAngle),
                clockwise: false
            )
        }
        .stroke(interaction.color.opacity(arcOpacity), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .animation(.easeOut(duration: 0.12), value: isHighlighted)
    }

    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        switch timeSpan {
        case .sixHours:
            // Get the current 6-hour window
            let currentHour = calendar.component(.hour, from: currentDate)
            let windowStart = (currentHour / 6) * 6
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            // Get the current 12-hour window
            let currentHour = calendar.component(.hour, from: currentDate)
            let windowStart = (currentHour / 12) * 12
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
}
