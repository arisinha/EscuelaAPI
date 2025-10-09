import SwiftUI
import Combine

@main
struct UniversityApp: App {
    // @StateObject crea y mantiene viva una única instancia
    // del AuthenticationViewModel durante todo el ciclo de vida de la app.
    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some Scene {
        WindowGroup {
            // Aquí está la lógica de navegación principal.
            // Si el usuario está autenticado, muestra la vista principal (MainView).
            // Si no, muestra la vista de inicio de sesión (LoginView).
            if authViewModel.isAuthenticated {
                // Inyectamos el ViewModel en el entorno para que las vistas hijas
                // puedan acceder a él si lo necesitan.
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
