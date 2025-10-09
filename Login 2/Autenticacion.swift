import Foundation
import Combine

// Este ViewModel actuará como nuestra "única fuente de verdad"
// para saber si el usuario está autenticado.
// Es un ObservableObject para que la UI pueda reaccionar a sus cambios.
class AuthenticationViewModel: ObservableObject {
    
    // @Published notifica a cualquier vista que observe este objeto
    // cuando el valor de isAuthenticated cambia.
    @Published var isAuthenticated = false
    
    // Simula un proceso de inicio de sesión.
    func login() {
        // En una app real, aquí verificarías las credenciales.
        // Para este ejemplo, simplemente cambiamos el estado.
        // Usamos una pequeña demora para simular una llamada de red.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = true
        }
    }
}

