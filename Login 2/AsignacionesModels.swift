import Foundation

struct Grupo: Codable, Identifiable, Hashable {
    let id: UUID
    let nombreMateria: String
    let codigoGrupo: String
}

// NOTA: Este modelo ya no se usa - ahora usamos el modelo Tarea de UniversityModels.swift
// Lo mantengo aquí por compatibilidad, pero considera eliminarlo en el futuro
struct Asignacion: Identifiable, Hashable {
    let id: UUID
    let grupoId: UUID
    let titulo: String
    let entregasRealizadas: Int
    let totalAlumnos: Int

    init(id: UUID = UUID(), grupoId: UUID, titulo: String, entregasRealizadas: Int, totalAlumnos: Int) {
        self.id = id
        self.grupoId = grupoId
        self.titulo = titulo
        self.entregasRealizadas = entregasRealizadas
        self.totalAlumnos = totalAlumnos
    }

    var nombreMateria: String {
        if let grupo = DataService.shared.obtenerGrupos().first(where: { $0.id == grupoId }) {
            return grupo.nombreMateria
        }
        return ""
    }
}
