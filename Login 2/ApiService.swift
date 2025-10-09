import Foundation
import Combine
import CryptoKit

#if DEBUG
final class InsecureSessionDelegate: NSObject, URLSessionDelegate {
    private let allowedHosts: Set<String>

    init(allowedHosts: [String]) {
        self.allowedHosts = Set(allowedHosts)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        if allowedHosts.contains(host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
#endif

enum APIError: Error {
    case invalidURL
    case requestFailed(description: String)
    case invalidResponse
    case decodingError(description: String)
    case emptyResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL de la API es inválida."
        case .requestFailed(let description):
            return description
        case .invalidResponse:
            return "La respuesta del servidor no es válida."
        case .decodingError(let description):
            return "Error al procesar la respuesta: \(description)"
        case .emptyResponse:
            return "El servidor devolvió una respuesta vacía."
        }
    }
}

struct LoginResponse: Codable {
    let token: String
    let usuario: Usuario
}

class APIService {
    static let shared = APIService()

    #if DEBUG
    private lazy var session: URLSession = {
        var hosts: [String] = ["localhost", "127.0.0.1"]
        if let host = URL(string: baseURL)?.host {
            hosts.append(host)
        }
        return URLSession(configuration: .default, delegate: InsecureSessionDelegate(allowedHosts: hosts), delegateQueue: nil)
    }()
    #else
    private let session: URLSession = .shared
    #endif

    private let baseURL = "https://localhost:7131"

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Estructuras de respuesta
    
    private struct TareasResponseWrapper: Decodable {
        let success: Bool
        let count: Int?
        let data: [Tarea]
    }
    
    private struct GruposResponseWrapper: Decodable {
        let success: Bool
        let count: Int?
        let data: [Grupo]
    }
    
    private struct RemoteGrupo: Decodable {
        let id: Int
        let nombreMateria: String
        let codigoGrupo: String
    }

    // MARK: - Login
    
    func login(nombreUsuario: String, contrasena: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/api/Auth/login") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "NombreUsuario": nombreUsuario,
            "Password": contrasena
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            let message = (serverMessage?.isEmpty == false)
                ? serverMessage!
                : "Credenciales inválidas o error del servidor. (código \(httpResponse.statusCode))"
            throw APIError.requestFailed(description: message)
        }

        do {
            return try jsonDecoder.decode(LoginResponse.self, from: data)
        } catch {
            throw APIError.decodingError(description: error.localizedDescription)
        }
    }

    // MARK: - Obtener Tareas
    
    func obtenerTareas(paraUsuarioId id: Int, token: String) async throws -> [Tarea] {
        guard let url = URL(string: "\(baseURL)/api/Tareas") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        #if DEBUG
        print("[API] GET /api/Tareas -> URL:", url.absoluteString)
        print("[API] Authorization:", request.value(forHTTPHeaderField: "Authorization") ?? "nil")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[API] /api/Tareas status:", httpResponse.statusCode)
        print("[API] /api/Tareas body:", String(data: data, encoding: .utf8) ?? "nil")
        #endif

        if httpResponse.statusCode == 401 {
            throw APIError.requestFailed(description: "No autorizado. La sesión puede haber expirado.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            let message = (serverMessage?.isEmpty == false)
                ? serverMessage!
                : "Error al obtener tareas. Código: \(httpResponse.statusCode)"
            throw APIError.requestFailed(description: message)
        }

        guard !data.isEmpty else {
            throw APIError.emptyResponse
        }

        do {
            // El backend devuelve: { success: true, count: 4, data: [Tarea] }
            let wrapper = try jsonDecoder.decode(TareasResponseWrapper.self, from: data)
            
            if wrapper.success {
                return wrapper.data
            } else {
                throw APIError.requestFailed(description: "La API indicó fallo al obtener tareas.")
            }
            
        } catch let decodingError as DecodingError {
            let errorDescription = detailedDecodingError(decodingError, data: data)
            throw APIError.decodingError(description: errorDescription)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(description: error.localizedDescription)
        }
    }
    
    // MARK: - Obtener Tareas por Grupo
    
    func obtenerTareasPorGrupo(grupoId: Int, token: String) async throws -> [Tarea] {
        guard let url = URL(string: "\(baseURL)/api/Grupos/\(grupoId)/tareas") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        #if DEBUG
        print("[API] GET /api/Grupos/\(grupoId)/tareas -> URL:", url.absoluteString)
        print("[API] Authorization:", request.value(forHTTPHeaderField: "Authorization") ?? "nil")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[API] /api/Grupos/\(grupoId)/tareas status:", httpResponse.statusCode)
        print("[API] /api/Grupos/\(grupoId)/tareas body:", String(data: data, encoding: .utf8) ?? "nil")
        #endif

        if httpResponse.statusCode == 401 {
            throw APIError.requestFailed(description: "No autorizado. La sesión puede haber expirado.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            let message = (serverMessage?.isEmpty == false)
                ? serverMessage!
                : "Error al obtener tareas del grupo. Código: \(httpResponse.statusCode)"
            throw APIError.requestFailed(description: message)
        }

        guard !data.isEmpty else {
            throw APIError.emptyResponse
        }

        do {
            // El backend devuelve: { success: true, count: 4, data: [Tarea] }
            let wrapper = try jsonDecoder.decode(TareasResponseWrapper.self, from: data)
            
            if wrapper.success {
                return wrapper.data
            } else {
                throw APIError.requestFailed(description: "La API indicó fallo al obtener tareas del grupo.")
            }
            
        } catch let decodingError as DecodingError {
            let errorDescription = detailedDecodingError(decodingError, data: data)
            throw APIError.decodingError(description: errorDescription)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(description: "Error desconocido: \(error.localizedDescription)")
        }
    }

    // MARK: - Obtener Grupos
    
    func obtenerGrupos(token: String) async throws -> [Grupo] {
        guard let url = URL(string: "\(baseURL)/api/Grupos") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        #if DEBUG
        print("[API] GET /api/Grupos -> URL:", url.absoluteString)
        print("[API] Authorization:", request.value(forHTTPHeaderField: "Authorization") ?? "nil")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[API] /api/Grupos status:", httpResponse.statusCode)
        print("[API] /api/Grupos body:", String(data: data, encoding: .utf8) ?? "nil")
        #endif

        if httpResponse.statusCode == 401 {
            throw APIError.requestFailed(description: "No autorizado. La sesión puede haber expirado.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            let message = (serverMessage?.isEmpty == false)
                ? serverMessage!
                : "Error al obtener grupos. Código: \(httpResponse.statusCode)"
            throw APIError.requestFailed(description: message)
        }

        guard !data.isEmpty else {
            throw APIError.emptyResponse
        }

        do {
            // Formato 1: { success, count, data: [Grupo] }
            if let wrapper = try? jsonDecoder.decode(GruposResponseWrapper.self, from: data) {
                if wrapper.success {
                    return wrapper.data
                } else {
                    throw APIError.requestFailed(description: "La API indicó fallo al obtener grupos.")
                }
            }

            // Formato 2: Array de {id:Int, nombreMateria:String, codigoGrupo:String}
            let remote = try jsonDecoder.decode([RemoteGrupo].self, from: data)
            let grupos: [Grupo] = remote.map { item in
                return Grupo(id: item.id, nombreMateria: item.nombreMateria, codigoGrupo: item.codigoGrupo)
            }
            return grupos
            
        } catch let decodingError as DecodingError {
            let errorDescription = detailedDecodingError(decodingError, data: data)
            throw APIError.decodingError(description: errorDescription)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(description: error.localizedDescription)
        }
    }

    // MARK: - Helpers
    
    static func uuidV5(namespace: UUID, name: String) -> UUID {
        let ns = namespace.uuid
        let nsBytes: [UInt8] = [
            ns.0, ns.1, ns.2, ns.3,
            ns.4, ns.5, ns.6, ns.7,
            ns.8, ns.9, ns.10, ns.11,
            ns.12, ns.13, ns.14, ns.15
        ]
        let nsData = Data(nsBytes)
        let nameData = Data(name.utf8)
        let hash = SHA256.hash(data: nsData + nameData)
        var bytes = Array(hash.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let uuid = bytes.withUnsafeBytes { rawPtr -> uuid_t in
            let ptr = rawPtr.bindMemory(to: UInt8.self)
            return (ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], ptr[8], ptr[9], ptr[10], ptr[11], ptr[12], ptr[13], ptr[14], ptr[15])
        }
        return UUID(uuid: uuid)
    }
    
    // MARK: - Entregas (Deliveries)
    
    /// Obtiene todas las entregas del usuario autenticado
    func obtenerMisEntregas(token: String) async throws -> [Entrega] {
        guard let url = URL(string: "\(baseURL)/api/entregas/mis-entregas") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.requestFailed(description: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let response = try jsonDecoder.decode(EntregasListResponse.self, from: data)
            return response.data
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(description: detailedDecodingError(decodingError, data: data))
        }
    }
    
    /// Crea una nueva entrega con archivo de imagen/documento
    func crearEntrega(tareaId: Int, archivo: Data, nombreArchivo: String, token: String) async throws -> Entrega {
        guard let url = URL(string: "\(baseURL)/api/entregas") else {
            throw APIError.invalidURL
        }
        
        // Crear el boundary para multipart/form-data
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construir el body multipart
        var body = Data()
        
        // Agregar el campo TareaId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"TareaId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tareaId)\r\n".data(using: .utf8)!)
        
        // Agregar el archivo
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Archivo\"; filename=\"\(nombreArchivo)\"\r\n".data(using: .utf8)!)
        
        // Determinar el content type basado en la extensión
        let contentType = determinarContentType(nombreArchivo: nombreArchivo)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(archivo)
        body.append("\r\n".data(using: .utf8)!)
        
        // Cerrar el boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.requestFailed(description: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let response = try jsonDecoder.decode(EntregaResponse.self, from: data)
            guard let entrega = response.data else {
                throw APIError.emptyResponse
            }
            return entrega
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(description: detailedDecodingError(decodingError, data: data))
        }
    }
    
    /// Crea una nueva entrega con documento PDF
    func crearEntregaConDocumento(tareaId: Int, documentData: Data, nombreArchivo: String, token: String) async throws -> Entrega {
        return try await crearEntrega(tareaId: tareaId, archivo: documentData, nombreArchivo: nombreArchivo, token: token)
    }
    
    /// Crea una nueva entrega con comentario personalizado
    func crearEntregaConComentario(tareaId: Int, archivo: Data, nombreArchivo: String, comentario: String?, token: String) async throws -> Entrega {
        guard let url = URL(string: "\(baseURL)/api/entregas") else {
            throw APIError.invalidURL
        }
        
        // Crear el boundary para multipart/form-data
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construir el body multipart
        var body = Data()
        
        // Agregar el campo TareaId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"TareaId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tareaId)\r\n".data(using: .utf8)!)
        
        // Agregar comentario si existe
        if let comentario = comentario, !comentario.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"Comentario\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(comentario)\r\n".data(using: .utf8)!)
        }
        
        // Agregar el archivo
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Archivo\"; filename=\"\(nombreArchivo)\"\r\n".data(using: .utf8)!)
        
        // Determinar el content type basado en la extensión
        let contentType = determinarContentType(nombreArchivo: nombreArchivo)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(archivo)
        body.append("\r\n".data(using: .utf8)!)
        
        // Cerrar el boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.requestFailed(description: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let response = try jsonDecoder.decode(EntregaResponse.self, from: data)
            guard let entrega = response.data else {
                throw APIError.emptyResponse
            }
            return entrega
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(description: detailedDecodingError(decodingError, data: data))
        }
    }
    
    /// Califica una entrega (solo para profesores)
    func calificarEntrega(entregaId: Int, calificacion: Double, retroalimentacion: String?, token: String) async throws -> Entrega {
        guard let url = URL(string: "\(baseURL)/api/entregas/\(entregaId)/calificar") else {
            throw APIError.invalidURL
        }
        
        let request = CalificarEntregaRequest(calificacion: calificacion, retroalimentacionProfesor: retroalimentacion)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.requestFailed(description: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let response = try jsonDecoder.decode(EntregaResponse.self, from: data)
            guard let entrega = response.data else {
                throw APIError.emptyResponse
            }
            return entrega
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(description: detailedDecodingError(decodingError, data: data))
        }
    }
    
    /// Obtiene entregas sin calificar (solo para profesores)
    func obtenerEntregasSinCalificar(token: String) async throws -> [Entrega] {
        guard let url = URL(string: "\(baseURL)/api/entregas/sin-calificar") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.requestFailed(description: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let response = try jsonDecoder.decode(EntregasListResponse.self, from: data)
            return response.data
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(description: detailedDecodingError(decodingError, data: data))
        }
    }
    
    /// Helper para determinar el content type basado en la extensión del archivo
    private func determinarContentType(nombreArchivo: String) -> String {
        let fileExtension = (nombreArchivo as NSString).pathExtension.lowercased()
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
    
    /// Proporciona información detallada sobre errores de decodificación
    private func detailedDecodingError(_ error: DecodingError, data: Data) -> String {
        let jsonString = String(data: data, encoding: .utf8) ?? "No se pudo leer el JSON"
        
        switch error {
        case .keyNotFound(let key, let context):
            return "Falta la clave '\(key.stringValue)' en la ruta: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). JSON: \(jsonString)"
            
        case .typeMismatch(let type, let context):
            return "Tipo incorrecto para '\(context.codingPath.last?.stringValue ?? "desconocido")'. Se esperaba \(type). JSON: \(jsonString)"
            
        case .valueNotFound(let type, let context):
            return "Valor null encontrado para '\(context.codingPath.last?.stringValue ?? "desconocido")' donde se esperaba \(type). JSON: \(jsonString)"
            
        case .dataCorrupted(let context):
            return "Datos corruptos en '\(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))'. Descripción: \(context.debugDescription). JSON: \(jsonString)"
            
        @unknown default:
            return "Error de decodificación desconocido. JSON: \(jsonString)"
        }
    }
}
