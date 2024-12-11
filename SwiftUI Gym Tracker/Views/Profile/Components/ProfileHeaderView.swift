import SwiftUI
struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        HStack(spacing: 20) {
            // Profil Resmi
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            // Kullanıcı Bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.fullName ?? "Kullanıcı")
                    .font(.title2)
                    .bold()
                
                if let email = user?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Fiziksel Bilgiler
                HStack(spacing: 12) {
                    if let height = user?.height {
                        Label("\(Int(height)) cm", systemImage: "ruler")
                            .font(.caption)
                    }
                    if let weight = user?.weight {
                        Label("\(Int(weight)) kg", systemImage: "scalemass")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
} 
