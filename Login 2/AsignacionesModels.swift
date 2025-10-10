import Foundation

struct Grupo: Codable, Identifiable, Hashable {
    let id: Int
    let nombreMateria: String
    let codigoGrupo: String
}