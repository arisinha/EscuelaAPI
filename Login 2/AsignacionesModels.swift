import Foundation

struct Grupo: Identifiable, Hashable {
    let id: UUID
    let nombreMateria: String
    let codigoGrupo: String
}

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

    // Conveniencia para vistas que muestran el nombre de la materia de la asignación
    var nombreMateria: String {
        if let grupo = DataService.shared.obtenerGrupos().first(where: { $0.id == grupoId }) {
            return grupo.nombreMateria
        }
        return ""
    }
}
