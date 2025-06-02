import SwiftUI

struct MuscleGroupSelector: View {
    @Binding var selectedGroup: MuscleGroup?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    MuscleGroupButton(
                        group: group,
                        isSelected: selectedGroup == group,
                        action: { selectedGroup = selectedGroup == group ? nil : group }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}

struct MuscleGroupButton: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(group.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.blue : Color.blue.opacity(0.1)
                )
                .foregroundColor(isSelected ? .white : .blue)
                .cornerRadius(20)
        }
    }
} 