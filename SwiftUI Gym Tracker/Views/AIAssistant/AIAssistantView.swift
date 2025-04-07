import SwiftUI

struct AIAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AIAssistantViewModel.shared
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if viewModel.messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.accentColor)
                                    
                                    Text("Antrenman Asistanın")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Text("Size nasıl yardımcı olabilirim?")
                                        .font(.headline)
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        SuggestionButton("Yeni başlayanlar için bir antrenman öner") {
                                            viewModel.query = "Yeni başlayanlar için bir antrenman öner"
                                            viewModel.askGemini()
                                        }
                                        
                                        SuggestionButton("Kilo vermek için beslenme önerileri") {
                                            viewModel.query = "Kilo vermek için beslenme önerileri"
                                            viewModel.askGemini()
                                        }
                                        
                                        SuggestionButton("Protein alımını nasıl artırabilirim?") {
                                            viewModel.query = "Protein alımını nasıl artırabilirim?"
                                            viewModel.askGemini()
                                        }
                                        
                                        SuggestionButton("Kardiyo ve ağırlık antrenmanı nasıl birleştirilir?") {
                                            viewModel.query = "Kardiyo ve ağırlık antrenmanı nasıl birleştirilir?"
                                            viewModel.askGemini()
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemBackground))
                            }
                            
                            // Chat messages
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { loading in
                        if loading {
                            withAnimation {
                                scrollView.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        TextField("Bir soru sor veya istekte bulun...", text: $viewModel.query)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .focused($isFieldFocused)
                            .disabled(viewModel.isLoading)
                        
                        Button {
                            isFieldFocused = false
                            viewModel.askGemini()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(viewModel.query.isEmpty || viewModel.isLoading ? .gray : .accentColor)
                        }
                        .disabled(viewModel.query.isEmpty || viewModel.isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Fitness Asistanı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
        }
    }
}

// Chat message bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUserMessage ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(message.isUserMessage ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUserMessage {
                Spacer()
            }
        }
    }
}

// Quick suggestion button
struct SuggestionButton: View {
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    AIAssistantView()
} 