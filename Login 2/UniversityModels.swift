import Foundation
import Combine

// Refleja el enum 'EstadoTarea' de C#.
enum EstadoTarea: String, Codable, CaseIterable {
    case Pendiente
    case EnProgreso
    case Completada
    case Cancelada
}

// Refleja el modelo 'Tarea' de C# con usuario anidado
struct Tarea: Codable, Identifiable, Hashable {
    let id: Int
    let titulo: String
    let descripcion: String?
    let estado: EstadoTarea
    let fechaCreacion: Date
    let fechaActualizacion: Date?
    let usuarioId: Int
    let grupoId: Int?
    
    // Propiedades adicionales que vienen del servidor pero no necesitamos en la UI
    private let usuario: UsuarioAnidado?
    
    // Estructura para el usuario anidado que viene del servidor
    private struct UsuarioAnidado: Codable, Hashable {
        let id: Int
        let nombreUsuario: String
        let nombreCompleto: String
    }
    
    // CodingKeys para mapear los campos del JSON
    enum CodingKeys: String, CodingKey {
        case id
        case titulo
        case descripcion
        case estado
        case fechaCreacion
        case fechaActualizacion
        case usuario
        case grupoId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        titulo = try container.decode(String.self, forKey: .titulo)
        descripcion = try container.decodeIfPresent(String.self, forKey: .descripcion)
        estado = try container.decode(EstadoTarea.self, forKey: .estado)
        grupoId = try container.decodeIfPresent(Int.self, forKey: .grupoId)
        
        // Decodificar el objeto usuario anidado
        usuario = try container.decodeIfPresent(UsuarioAnidado.self, forKey: .usuario)
        
        // Extraer usuarioId del objeto usuario anidado
        if let usuario = usuario {
            usuarioId = usuario.id
        } else {
            // Si no hay usuario anidado, intentar decodificar usuarioId directamente
            // (por si el backend cambia en el futuro)
            usuarioId = try container.decodeIfPresent(Int.self, forKey: CodingKeys(stringValue: "usuarioId")!) ?? 0
        }
        
        // Decodificar fechas con manejo robusto de formatos
        fechaCreacion = try Self.decodeDate(from: container, forKey: .fechaCreacion)
        fechaActualizacion = try? Self.decodeDate(from: container, forKey: .fechaActualizacion)
    }
    
    // Inicializador normal para crear instancias manualmente
    init(id: Int, titulo: String, descripcion: String?, estado: EstadoTarea, fechaCreacion: Date, fechaActualizacion: Date?, usuarioId: Int, grupoId: Int? = nil) {
        self.id = id
        self.titulo = titulo
        self.descripcion = descripcion
        self.estado = estado
        self.fechaCreacion = fechaCreacion
        self.fechaActualizacion = fechaActualizacion
        self.usuarioId = usuarioId
        self.grupoId = grupoId
        self.usuario = nil
    }
    
    // Helper para decodificar fechas en múltiples formatos
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        if let dateString = try? container.decode(String.self, forKey: key) {
            // Formato 1: ISO8601 con timezone offset (2025-09-19T15:58:04+00:00)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Formato 2: ISO8601 sin milisegundos pero con timezone
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Formato 3: ISO8601 con milisegundos y 'Z' (2024-01-15T10:30:00.123Z)
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Formato 4: ISO8601 básico (2024-01-15T10:30:00Z)
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Formato 5: Manual con DateFormatter para casos especiales
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Intentar con timezone offset
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Intentar sin timezone
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "No se pudo decodificar la fecha: \(dateString)"
            )
        }
        
        return try container.decode(Date.self, forKey: key)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(titulo, forKey: .titulo)
        try container.encodeIfPresent(descripcion, forKey: .descripcion)
        try container.encode(estado, forKey: .estado)
        try container.encode(fechaCreacion, forKey: .fechaCreacion)
        try container.encodeIfPresent(fechaActualizacion, forKey: .fechaActualizacion)
        try container.encodeIfPresent(grupoId, forKey: .grupoId)
        try container.encodeIfPresent(usuario, forKey: .usuario)
    }
    
    // Hashable se implementa automáticamente, pero excluimos usuario del hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tarea, rhs: Tarea) -> Bool {
        lhs.id == rhs.id
    }
}

// Refleja el modelo 'Usuario' de C#.
struct Usuario: Codable, Identifiable, Hashable {
    let id: Int
    let nombreUsuario: String
    let nombreCompleto: String
    
    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implementación de Equatable
    static func == (lhs: Usuario, rhs: Usuario) -> Bool {
        return lhs.id == rhs.id
    }
}

// Modelos para entregas y calificaciones
struct Entrega: Codable, Identifiable, Hashable {
    let id: Int
    let tareaId: Int
    let alumnoId: Int
    let nombreArchivo: String?
    let rutaArchivo: String?
    let fechaEntrega: Date
    let calificacion: Double?
    let retroalimentacionProfesor: String?
    let fechaCalificacion: Date?
    let tarea: Tarea?
    let alumno: Usuario?
    let profesor: Usuario?
    
    enum CodingKeys: String, CodingKey {
        case id, tareaId, alumnoId, nombreArchivo, rutaArchivo
        case fechaEntrega, calificacion, retroalimentacionProfesor
        case fechaCalificacion, tarea, alumno, profesor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        tareaId = try container.decode(Int.self, forKey: .tareaId)
        alumnoId = try container.decode(Int.self, forKey: .alumnoId)
        nombreArchivo = try container.decodeIfPresent(String.self, forKey: .nombreArchivo)
        rutaArchivo = try container.decodeIfPresent(String.self, forKey: .rutaArchivo)
        calificacion = try container.decodeIfPresent(Double.self, forKey: .calificacion)
        retroalimentacionProfesor = try container.decodeIfPresent(String.self, forKey: .retroalimentacionProfesor)
        tarea = try container.decodeIfPresent(Tarea.self, forKey: .tarea)
        alumno = try container.decodeIfPresent(Usuario.self, forKey: .alumno)
        profesor = try container.decodeIfPresent(Usuario.self, forKey: .profesor)
        
        // Decodificar fechas
        fechaEntrega = try Self.decodeDate(from: container, forKey: .fechaEntrega)
        fechaCalificacion = try? Self.decodeDate(from: container, forKey: .fechaCalificacion)
    }
    
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        if let dateString = try? container.decode(String.self, forKey: key) {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
        }
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [key], debugDescription: "Formato de fecha inválido"))
    }
    
    var estaCalificada: Bool {
        return calificacion != nil
    }
    
    // Implementación de Hashable - solo usar el ID único
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implementación de Equatable - comparar por ID
    static func == (lhs: Entrega, rhs: Entrega) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CrearEntregaRequest: Codable {
    let tareaId: Int
}

struct CalificarEntregaRequest: Codable {
    let calificacion: Double
    let retroalimentacionProfesor: String?
}

struct EntregaResponse: Codable {
    let success: Bool
    let message: String?
    let data: Entrega?
}

struct EntregasListResponse: Codable {
    let success: Bool
    let count: Int
    let data: [Entrega]
}
