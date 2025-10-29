import SwiftUI

struct GroupDetailView: View {
    let grupo: Grupo
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingEditarGrupo = false
    @State private var showingEliminarConfirmacion = false
    
    var body: some View {
        List {
            // Información del grupo
            Section(header: Text("Información del Grupo")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Materia")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(grupo.nombreMateria)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Código")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(grupo.codigoGrupo)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("ID del Grupo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("#\(grupo.id)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Navegación a las diferentes secciones
            Section(header: Text("Gestión")) {
                // Tareas del grupo
                NavigationLink(destination: TasksListView(grupo: grupo)) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tareas")
                                .font(.headline)
                            Text("Ver y gestionar tareas del grupo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Asistencia del grupo
                NavigationLink(destination: AttendanceListView(grupo: grupo)) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Asistencia")
                                .font(.headline)
                            Text("Registrar y consultar asistencias")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Acciones del grupo
            Section(header: Text("Acciones")) {
                Button(action: {
                    showingEditarGrupo = true
                }) {
                    Label("Editar Grupo", systemImage: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(role: .destructive, action: {
                    showingEliminarConfirmacion = true
                }) {
                    Label("Eliminar Grupo", systemImage: "trash")
                }
            }
        }
        .navigationTitle(grupo.nombreMateria)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditarGrupo) {
            EditarGrupoView(grupo: grupo) { _ in
                // Refresh logic if needed
            }
            .environmentObject(authViewModel)
        }
        .alert("Confirmar Eliminación", isPresented: $showingEliminarConfirmacion) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                // TODO: Implement delete logic
            }
        } message: {
            Text("¿Estás seguro que deseas eliminar el grupo '\(grupo.nombreMateria) - \(grupo.codigoGrupo)'?")
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(grupo: Grupo(id: 1, nombreMateria: "Programación Móvil", codigoGrupo: "PM-101"))
            .environmentObject(AuthenticationViewModel())
    }
}
