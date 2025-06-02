//
//  ExerciseDetailView.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//


// Bu view egzersizin detaylarını gösterir.

import SwiftUI
import Firebase

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isLoading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var animateIcon = false
    
    @ObservedObject var firebaseManager = FirebaseManager.shared
    
    private var canEditExercise: Bool {
        if let userId = exercise.id {
            return userId == firebaseManager.currentUser?.id || firebaseManager.currentUser?.isAdmin == true
        }
        return firebaseManager.currentUser?.isAdmin == true
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section with Category Icon
                ZStack(alignment: .bottomTrailing) {
                    VStack {
                        Image(systemName: exercise.exerciseCategory.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        exercise.exerciseCategory.color.opacity(0.8),
                                        exercise.exerciseCategory.color.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: exercise.exerciseCategory.color.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 30)
                            .padding(.bottom, 16)
                            .scaleEffect(animateIcon ? 1.1 : 1.0)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    animateIcon = true
                                }
                            }
                        
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                    
                    if canEditExercise {
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(exercise.exerciseCategory.color))
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Category and Intensity Card
                CardView(title: "Egzersiz Bilgileri", systemImage: "tag") {
                    CategoryInfoRow(
                        label: "Kategori",
                        value: exercise.exerciseCategory.title,
                        color: exercise.exerciseCategory.color
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    CategoryInfoRow(
                        label: "Yoğunluk",
                        value: exercise.intensity,
                        color: intensityColor(for: exercise.intensity)
                    )
                    
                    if let metValue = exercise.metValue {
                        Divider()
                            .padding(.vertical, 8)
                        
                        DetailRow(label: "MET Değeri", value: String(format: "%.1f", metValue))
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Kas Grupları")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                    
                    if exercise.muscleGroups.isEmpty {
                        Text("Kas grubu belirtilmemiş")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscleGroup in
                                MuscleGroupTag(muscleGroup: muscleGroup)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                // Description Card
                if !exercise.description.isEmpty {
                    CardView(title: "Açıklama", systemImage: "text.alignleft") {
                        Text(exercise.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    if canEditExercise {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Sil")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                        }
                    }
                    
                    NavigationLink(destination: AddToWorkoutView(exercise: exercise)) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Antrenman Ekle")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(exercise.exerciseCategory.color)
                        )
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showingToast {
                    ToastView(message: toastMessage) {
                        withAnimation {
                            showingToast = false
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditExerciseView(exercise: exercise)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Egzersizi Sil"),
                message: Text("Bu egzersizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."),
                primaryButton: .destructive(Text("Sil")) {
                    deleteExercise()
                },
                secondaryButton: .cancel(Text("İptal"))
            )
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Hata"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    private func intensityColor(for intensity: String) -> Color {
        switch intensity {
        case "Düşük":
            return .green
        case "Orta":
            return .orange
        case "Yüksek":
            return .red
        default:
            return .gray
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    private func deleteExercise() {
        isLoading = true
        
        guard let id = exercise.id else {
            errorMessage = "Egzersiz ID'si bulunamadı"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("exercises").document(id).delete { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Egzersiz silinirken bir hata oluştu: \(error.localizedDescription)"
                showingErrorAlert = true
            } else {
                toastMessage = "Egzersiz başarıyla silindi"
                showingToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct CategoryInfoRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                .foregroundColor(color)
        }
    }
}

struct MuscleGroupTag: View {
    let muscleGroup: MuscleGroup
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForMuscleGroup(muscleGroup))
                .font(.system(size: 12))
            
            Text(muscleGroup.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorForMuscleGroup(muscleGroup).opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(colorForMuscleGroup(muscleGroup).opacity(0.5), lineWidth: 1)
        )
        .foregroundColor(colorForMuscleGroup(muscleGroup))
    }
    
    private func iconForMuscleGroup(_ group: MuscleGroup) -> String {
        switch group {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .legs: return "figure.run"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .cardio: return "heart.circle"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
    
    private func colorForMuscleGroup(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return .blue
        case .back: return .green
        case .legs: return .orange
        case .shoulders: return .purple
        case .arms: return .red
        case .core: return .yellow
        case .cardio: return .pink
        case .fullBody: return .indigo
        }
    }
}

struct CardView<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ToastView: View {
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 10) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var width: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowWidth + subviewSize.width + spacing > maxWidth {
                // Start a new row
                width = max(width, rowWidth - spacing)
                height += rowHeight + spacing
                rowWidth = subviewSize.width + spacing
                rowHeight = subviewSize.height
            } else {
                // Add to the current row
                rowWidth += subviewSize.width + spacing
                rowHeight = max(rowHeight, subviewSize.height)
            }
        }
        
        // Add the last row
        width = max(width, rowWidth - spacing)
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowX + subviewSize.width > bounds.maxX {
                // Start a new row
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height))
            
            rowX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExercise = Exercise(
            id: "1",
            name: "Bench Press",
            description: "Göğüs, omuz ve triceps kaslarını hedefleyen bileşik bir egzersiz.",
            muscleGroups: [.chest, .shoulders, .arms],
            createdBy: "admin",
            createdAt: Timestamp(),
            updatedAt: Timestamp(),
            averageRating: 4.5,
            totalRatings: 10,
            metValue: 3.8
        )
        
        ExerciseDetailView(exercise: sampleExercise)
            .preferredColorScheme(.dark)
    }
} 
