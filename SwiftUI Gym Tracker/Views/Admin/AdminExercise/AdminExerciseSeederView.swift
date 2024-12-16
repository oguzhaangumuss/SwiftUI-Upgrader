import SwiftUI

struct AdminExerciseSeederView: View {
    @StateObject private var viewModel = AdminExerciseSeederViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        Task {
                            await viewModel.seedExercises()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Egzersizleri Yükle")
                        }
                    }
                    .disabled(viewModel.isLoading)
                } footer: {
                    Text("Bu işlem mevcut egzersizleri etkilemez, sadece yeni egzersizler ekler.")
                        .font(.caption)
                }
                
                if viewModel.successCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(viewModel.successCount) egzersiz başarıyla eklendi")
                        }
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(viewModel.errorMessage)
                        }
                    }
                }
            }
            .navigationTitle("Egzersiz Yükleyici")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
} 