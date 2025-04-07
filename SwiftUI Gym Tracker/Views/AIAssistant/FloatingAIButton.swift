import SwiftUI

struct FloatingAIButton: View {
    @Binding var showingAIAssistant: Bool
    @State private var dragAmount = CGSize.zero
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 160)
    
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
    }
}

#Preview {
    FloatingAIButton(showingAIAssistant: .constant(false))
} 