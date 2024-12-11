import SwiftUI

struct DateSelectionHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button {
                showingDatePicker = true
            } label: {
                Text(selectedDate.formatted(date: .long, time: .omitted))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
} 