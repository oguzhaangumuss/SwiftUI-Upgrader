import SwiftUI
import FirebaseFirestore

struct AdminUsersView: View {
    @StateObject private var viewModel = AdminUsersViewModel()
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        }
        return viewModel.users.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Arama çubuğu
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Kullanıcı Ara...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            List {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: AdminUserDetailView(user: user)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(user.fullName)
                                    .font(.headline)
                                if user.isAdmin {
                                    Text("Admin")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Label("\(user.age) yaş", systemImage: "person")
                                Spacer()
                                Label("\(Int(user.weight)) kg", systemImage: "scalemass")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Kullanıcılar")
        .onAppear {
            Task {
                await viewModel.fetchUsers()
            }
        }
        .refreshable {
            await viewModel.fetchUsers()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.users.isEmpty {
                Text("Henüz kullanıcı bulunmuyor")
                    .foregroundColor(.secondary)
            }
        }
    }
} 