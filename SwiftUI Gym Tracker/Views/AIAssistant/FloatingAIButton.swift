import SwiftUI

struct FloatingAIButton: View {
    @Binding var showingAIAssistant: Bool
    @State private var dragAmount = CGSize.zero
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 160)
    @State private var showingHideConfirmation = false
    @State private var showingLongPressMenu = false
    
    var body: some View {
        Button {
            showingAIAssistant = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 5)
                
                VStack(spacing: 0) {
                    // Robot head
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    // Dumbell
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 14, height: 4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .position(x: buttonPosition.x + dragAmount.width, y: buttonPosition.y + dragAmount.height)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.dragAmount = gesture.translation
                }
                .onEnded { gesture in
                    // Update position and reset drag amount
                    let screen = UIScreen.main.bounds
                    let newX = buttonPosition.x + gesture.translation.width
                    let newY = buttonPosition.y + gesture.translation.height
                    
                    // Keep button within screen bounds
                    let finalX = min(max(newX, 40), screen.width - 40)
                    let finalY = min(max(newY, 100), screen.height - 100)
                    
                    self.buttonPosition = CGPoint(x: finalX, y: finalY)
                    self.dragAmount = .zero
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    showingLongPressMenu = true
                }
        )
        .confirmationDialog("AI Asistanı", isPresented: $showingLongPressMenu) {
            Button("Gizle", role: .destructive) {
                showingHideConfirmation = true
            }
            Button("İptal", role: .cancel) {}
        }
        .alert("AI Asistanı Gizle", isPresented: $showingHideConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Gizle", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "showAIAssistant")
                NotificationCenter.default.post(name: NSNotification.Name("AIAssistantVisibilityChanged"), object: nil)
            }
        } message: {
            Text("AI asistanı gizlenecek. Tekrar görünür yapmak için Ayarlar > Gizlilik kısmından aktifleştirebilirsiniz.")
        }
    }
}

#Preview {
    FloatingAIButton(showingAIAssistant: .constant(false))
} 