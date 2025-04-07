import SwiftUI

struct AdminFoodSeederView: View {
    @StateObject private var viewModel = AdminFoodSeederViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        Task {
                            await viewModel.seedFoods()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Besinleri Yükle")
                        }
                    }
                    .disabled(viewModel.isLoading)
                } footer: {
                    Text("Bu işlem mevcut besinleri etkilemez, sadece yeni besinler ekler.")
                        .font(.caption)
                }
                
                if viewModel.successCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(viewModel.successCount) besin başarıyla eklendi")
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
            .navigationTitle("Besin Yükleyici")
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