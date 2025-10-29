import SwiftUI
import Combine
struct MainView: View {
    // Escucha los cambios del ViewModel de autenticación.
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        // Después de iniciar sesión, mostramos la lista de grupos.
        if authViewModel.usuarioAutenticado != nil {
            NavigationStack {
                GroupsListView()
            }
            .environmentObject(authViewModel)
        } else {
            LoginView()
                .environmentObject(authViewModel)
        }
    }
}
