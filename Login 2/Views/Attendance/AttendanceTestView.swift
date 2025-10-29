import SwiftUI

/// Quick Test View to verify attendance functionality
/// This can be used for testing without running the full app
struct AttendanceTestView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Attendance System Test")
                    .font(.title)
                    .padding()
                
                // Test Group
                let testGroup = Grupo(
                    id: 1,
                    nombreMateria: "Programación Móvil",
                    codigoGrupo: "PM-101"
                )
                
                NavigationLink("View Group Detail") {
                    GroupDetailView(grupo: testGroup)
                        .environmentObject(authViewModel)
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink("View Attendance List") {
                    AttendanceListView(grupo: testGroup)
                        .environmentObject(authViewModel)
                }
                .buttonStyle(.borderedProminent)
                
                // Note about authentication
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note:")
                        .font(.headline)
                    Text("Make sure you're logged in before testing these views.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("The token needs to be set in authViewModel.authToken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
        }
    }
}

#Preview {
    AttendanceTestView()
}
