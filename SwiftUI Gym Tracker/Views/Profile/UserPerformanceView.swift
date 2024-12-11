import SwiftUI
import Charts
import FirebaseFirestore

struct UserPerformanceView: View {
    @StateObject private var viewModel = PerformanceViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Kişisel Rekorlar")) {
                if let personalBests = viewModel.personalBests, !personalBests.isEmpty {
                    ForEach(Array(personalBests.sorted(by: { $0.key < $1.key })), id: \.key) { exercise, weight in
                        HStack {
                            Text(exercise)
                            Spacer()
                            Text("\(Int(weight)) kg")
                                .bold()
                        }
                    }
                } else {
                    Text("Henüz kişisel rekor kaydedilmemiş")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Kilo Takibi")) {
                if !viewModel.weightHistory.isEmpty {
                    Chart {
                        ForEach(viewModel.weightHistory) { point in
                            LineMark(
                                x: .value("Tarih", point.date),
                                y: .value("Kilo", point.weight)
                            )
                        }
                    }
                    .frame(height: 200)
                } else {
                    Text("Henüz kilo kaydı bulunmuyor")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("İlerleme Notları")) {
                if let progressNotes = viewModel.progressNotes, !progressNotes.isEmpty {
                    ForEach(progressNotes, id: \.id) { note in
                        VStack(alignment: .leading) {
                            Text(note.date.dateValue().formatted())
                                .font(.caption)
                            if let noteText = note.note {
                                Text(noteText)
                            }
                        }
                    }
                } else {
                    Text("Henüz ilerleme notu eklenmemiş")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Performans")
        .onAppear {
            Task {
                await viewModel.fetchData()
            }
        }
    }
} 