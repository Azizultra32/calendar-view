import SwiftUI

struct CalendarStripView: View {
    let currentDate: Date
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month and Year
            Text(monthYearFormatter.string(from: currentDate))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            // Week days
            HStack(spacing: 0) {
                ForEach(weekDays(), id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isToday(date) ? .blue : .gray)
                        
                        Text(dayFormatter.string(from: date))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isSameDay(date, as: selectedDate) ? Color.blue : Color.clear)
                                    .overlay(
                                        Circle()
                                            .stroke(isToday(date) ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        onDateSelected(date)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    private func weekDays() -> [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func isSameDay(_ date1: Date, as date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
}