import SwiftUI

struct DateSelectionHeader: View {
    @Binding var selectedDate: Date
    @Binding var isDatePickerVisible: Bool
    private let calendar = Calendar.current
    var onDateSelected: ((Date) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            // Current month and year with date picker button
            HStack {
                Text(monthYearFormatter.string(from: selectedDate))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    isDatePickerVisible = true
                }) {
                    HStack(spacing: 6) {
                        Text("Tarih Seç")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.primaryColor)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill((AppTheme.primaryColor as SwiftUI.Color).opacity(0.12))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Days of week selector with improved scrolling
            ScrollViewReader { scrollView in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(-15...15, id: \.self) { offset in
                            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                            
                            dayButton(for: date)
                                .id(offset)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    // Scroll to current date (offset 0)
                    withAnimation {
                        scrollView.scrollTo(0, anchor: .center)
                    }
                }
            }
        }
        .sheet(isPresented: $isDatePickerVisible) {
            DatePickerSheet(selectedDate: $selectedDate, isPresented: $isDatePickerVisible, onDateConfirmed: {
                onDateSelected?(selectedDate)
            })
                .presentationDetents([.medium])
        }
    }
    
    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
                onDateSelected?(date)
            }
        }) {
            VStack(spacing: 6) {
                Text(dayNumberFormatter.string(from: date))
                    .font(.system(size: 20, weight: .semibold))
                
                Text(dayNameFormatter.string(from: date))
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(width: 50, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? AppTheme.primaryColor :
                        isToday ? (AppTheme.primaryColor as SwiftUI.Color).opacity(0.15) : Color(.systemGray6)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear :
                        isToday ? (AppTheme.primaryColor as SwiftUI.Color).opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected ? .white : isToday ? AppTheme.primaryColor : .primary)
            .shadow(
                color: isSelected ? (AppTheme.primaryColor as SwiftUI.Color).opacity(0.3) : Color.clear,
                radius: 4, x: 0, y: 2
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Date formatters
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var dayNameFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }
}

// Custom button style with scale effect for better feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(SwiftUI.Animation.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Date picker sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    var onDateConfirmed: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Tarih Seçin",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                        onDateConfirmed?()
                    }
                }) {
                    Text("Tarihi Onayla")
                        .font(SwiftUI.Font.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryColor)
                        .cornerRadius(16)
                        .shadow(color: (AppTheme.primaryColor as SwiftUI.Color).opacity(0.3), radius: 5, x: 0, y: 3)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Tarih Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

