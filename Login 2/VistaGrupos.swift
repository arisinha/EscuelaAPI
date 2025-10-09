import SwiftUI
import Combine

// ViewModel que obtiene y gestiona la lista de grupos del profesor.
@MainActor
class GroupsViewModel: ObservableObject {
    @Published var grupos: [Grupo] = []
    @Published var estadoDeCarga = false
    @Published var error: String?
    
    private let apiService = APIService.shared
    
    func cargarGrupos(token: String) async {
        estadoDeCarga = true
        error = nil
        do {
            let gruposObtenidos = try await apiService.obtenerGrupos(token: token)
            self.grupos = gruposObtenidos
            // Actualizar DataService para que otros componentes puedan acceder a los grupos
            DataService.shared.actualizarGrupos(gruposObtenidos)
        } catch {
            self.error = error.localizedDescription
        }
        estadoDeCarga = false
    }
}

struct GroupsListView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingEntregasListView = false

    var body: some View {
        NavigationStack {
            if viewModel.estadoDeCarga {
                ProgressView()
                    .navigationTitle("Mis Grupos")
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Reintentar") {
                        Task {
                            if let token = authViewModel.authToken {
                                await viewModel.cargarGrupos(token: token)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Mis Grupos")
            } else if viewModel.grupos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No hay grupos disponibles")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Mis Grupos")
            } else {
                VStack(spacing: 0) {
                    // Botón de entregas por calificar en la parte superior
                    VStack(spacing: 12) {
                        Button(action: {
                            showingEntregasListView = true
                        }) {
                            HStack {
                                Image(systemName: "graduationcap.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Entregas por Calificar")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("Revisa y califica las entregas pendientes")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Lista de grupos
                    List(viewModel.grupos) { grupo in
                        NavigationLink(value: grupo) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(grupo.nombreMateria)
                                        .font(.headline)
                                    Text(grupo.codigoGrupo)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .navigationTitle("Mis Grupos")
                .navigationDestination(for: Grupo.self) { grupoSeleccionado in
                    TasksListView(grupo: grupoSeleccionado)
                }
            }
        }
        .sheet(isPresented: $showingEntregasListView) {
            EntregasListView()
                .environmentObject(authViewModel)
        }
        .task {
            if let token = authViewModel.authToken {
                await viewModel.cargarGrupos(token: token)
            } else {
                viewModel.error = "No se encontró token de autenticación."
            }
        }
    }
}
