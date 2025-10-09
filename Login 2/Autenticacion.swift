import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()
    
    @Published var usuarioAutenticado: Usuario?
    @Published private(set) var authToken: String?
    
    @Published var estadoDeCarga = false
    @Published var error: String?

    private let apiService = APIService.shared

    func login(nombreUsuario: String, contrasena: String) async {
        estadoDeCarga = true
        error = nil
        
        do {
            let response = try await apiService.login(nombreUsuario: nombreUsuario, contrasena: contrasena)
            self.usuarioAutenticado = response.usuario
            self.authToken = response.token
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
            logout()
        } catch {
            self.error = error.localizedDescription.isEmpty ? "Ocurrió un error inesperado. Intenta nuevamente." : error.localizedDescription
            logout()
        }
        
        estadoDeCarga = false
    }
    
    func logout() {
        usuarioAutenticado = nil
        authToken = nil
        // Limpiar datos del DataService
        DataService.shared.limpiarDatos()
    }
}
