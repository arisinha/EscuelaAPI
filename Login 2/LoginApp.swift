import SwiftUI
import Combine

@main
struct UniversityApp: App {
    // Creamos una única instancia del ViewModel de autenticación
    // y la pasamos a través del entorno de la app.
    @StateObject private var authViewModel = AuthenticationViewModel.shared

    var body: some Scene {
        WindowGroup {
            // Si hay un usuario autenticado, muestra la vista principal.
            // Si no, muestra la vista de login.
            if authViewModel.usuarioAutenticado != nil {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
