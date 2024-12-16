import SwiftUI
import FirebaseFirestore

struct AdminUsersView: View {
    @StateObject private var viewModel = AdminUsersViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.users) { user in
                    NavigationLink(destination: AdminUserDetailView(user: user)) {
                        UserRowView(user: user)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Kullanıcılar")
            .onAppear {
                Task {
                    await viewModel.fetchUsers()
                }
            }
            .refreshable {
                await viewModel.fetchUsers()
            }
            .overlay(loadingOverlay)
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.users.isEmpty {
            Text("Henüz kullanıcı bulunmuyor")
                .foregroundColor(.secondary)
        }
    }
}

// Kullanıcı satırı için ayrı bir view
struct UserRowView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.fullName)
                .font(.headline)
            
            HStack {
                Label("\(user.age ?? 0) yaş", systemImage: "person")
                Spacer()
                Label("\(Int(user.weight ?? 0)) kg", systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 
