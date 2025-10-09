import SwiftUI
import Combine

// ViewModel para la lista de tareas.
@MainActor
class TasksViewModel: ObservableObject {
    @Published var tareas: [Tarea] = []
    @Published var estadoDeCarga = false
    @Published var error: String?
    
    private let apiService = APIService.shared

    func cargarTareas(grupo: Grupo, userId: Int, token: String) async {
        estadoDeCarga = true
        error = nil
        
        do {
            let tareasDelUsuario = try await apiService.obtenerTareas(paraUsuarioId: userId, token: token)
            // Si más adelante hay endpoint por grupo, aquí filtramos por grupo.
            self.tareas = tareasDelUsuario
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        estadoDeCarga = false
    }
}

struct TasksListView: View {
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    let grupo: Grupo

    var body: some View {
        ZStack {
            if viewModel.estadoDeCarga {
                ProgressView("Cargando tareas...")
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Reintentar") {
                        Task {
                            if let token = authViewModel.authToken,
                               let userId = authViewModel.usuarioAutenticado?.id {
                                await viewModel.cargarTareas(grupo: grupo, userId: userId, token: token)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.tareas.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No hay tareas disponibles")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.tareas) { tarea in
                    NavigationLink(value: tarea) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tarea.titulo)
                                .font(.headline)
                            
                            HStack {
                                Circle()
                                    .fill(colorParaEstado(tarea.estado))
                                    .frame(width: 8, height: 8)
                                Text(tarea.estado.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let descripcion = tarea.descripcion, !descripcion.isEmpty {
                                Text(descripcion)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(grupo.nombreMateria)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let token = authViewModel.authToken,
               let userId = authViewModel.usuarioAutenticado?.id {
                await viewModel.cargarTareas(grupo: grupo, userId: userId, token: token)
            } else {
                viewModel.error = "No hay token o usuario de autenticación. Por favor inicia sesión nuevamente."
            }
        }
        .navigationDestination(for: Tarea.self) { tarea in
            TaskDetailView(tarea: tarea)
        }
    }
    
    // Helper para asignar colores según el estado
    private func colorParaEstado(_ estado: EstadoTarea) -> Color {
        switch estado {
        case .Pendiente:
            return .orange
        case .EnProgreso:
            return .blue
        case .Completada:
            return .green
        case .Cancelada:
            return .red
        }
    }
}
