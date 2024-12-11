import SwiftUI
import Charts
import FirebaseFirestore

struct PerformanceView: View {
    @StateObject private var viewModel = PerformanceViewModel()
    
    var body: some View {
        List {
            personalBestsSection
            weightTrackingSection
            progressNotesSection
        }
        .navigationTitle("Performans")
        .onAppear {
            Task {
                await viewModel.fetchData()
            }
        }
    }
    
    private var personalBestsSection: some View {
        Section(header: Text("Kişisel Rekorlar")) {
            if let personalBests = viewModel.personalBests, !personalBests.isEmpty {
                ForEach(Array(personalBests.sorted(by: { $0.key < $1.key })), id: \.key) { exercise, weight in
                    PersonalBestRow(exercise: exercise, weight: weight)
                }
            } else {
                EmptyStateText(message: "Henüz kişisel rekor kaydedilmemiş")
            }
        }
    }
    
    private var weightTrackingSection: some View {
        Section(header: Text("Kilo Takibi")) {
            if !viewModel.weightHistory.isEmpty {
                WeightChart(data: viewModel.weightHistory)
            } else {
                EmptyStateText(message: "Henüz kilo kaydı bulunmuyor")
            }
        }
    }
    
    private var progressNotesSection: some View {
        Section(header: Text("İlerleme Notları")) {
            if let progressNotes = viewModel.progressNotes, !progressNotes.isEmpty {
                ForEach(progressNotes, id: \.id) { note in
                    ProgressNoteRow(note: note)
                }
            } else {
                EmptyStateText(message: "Henüz ilerleme notu eklenmemiş")
            }
        }
    }
}

// MARK: - Helper Views
private struct PersonalBestRow: View {
    let exercise: String
    let weight: Double
    
    var body: some View {
        HStack {
            Text(exercise)
            Spacer()
            Text("\(Int(weight)) kg")
                .bold()
        }
    }
}

private struct WeightChart: View {
    let data: [PerformanceViewModel.WeightDataPoint]
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Kilo", point.weight)
                )
            }
        }
        .frame(height: 200)
    }
}

private struct ProgressNoteRow: View {
    let note: User.ProgressNote
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(note.date.dateValue().formatted())
                .font(.caption)
            if let noteText = note.note {
                Text(noteText)
            }
        }
    }
}

private struct EmptyStateText: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.secondary)
    }
}

#Preview {
    NavigationView {
        PerformanceView()
    }
} 
