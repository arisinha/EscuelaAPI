import Foundation
import Combine

// Esta clase gestiona la obtención de datos para la aplicación.
final class DataService {
    
    static let shared = DataService()
    
    // MARK: - Propiedades privadas
    
    private var gruposEnMemoria: [Grupo] = []
    
    // Inicializador privado
    private init() {
        // Inicialización vacía - los grupos se cargarán desde la API
    }
    
    // MARK: - Métodos públicos
    
    /// Actualiza la lista de grupos en memoria desde la API
    func actualizarGrupos(_ nuevosGrupos: [Grupo]) {
        self.gruposEnMemoria = nuevosGrupos
    }
    
    /// Obtiene los grupos almacenados en memoria
    func obtenerGrupos() -> [Grupo] {
        return self.gruposEnMemoria
    }
    
    /// Limpia los datos almacenados (útil al cerrar sesión)
    func limpiarDatos() {
        self.gruposEnMemoria = []
    }
}
