import SwiftUI
import Combine

@MainActor
class EntregasListViewModel: ObservableObject {
    @Published var entregas: [Entrega] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingGradingSheet = false
    @Published var gradingEntrega: Entrega?
    @Published var calificacion: String = ""
    @Published var retroalimentacion: String = ""
    
    private let apiService = APIService.shared
    
    func cargarEntregasSinCalificar(token: String) async {
        isLoading = true
        error = nil
        
        do {
            entregas = try await apiService.obtenerEntregasSinCalificar(token: token)
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch let generalError {
            error = generalError.localizedDescription
        }
        
        isLoading = false
    }
    
    func calificarEntrega(token: String) async {
        guard let entrega = gradingEntrega,
              let calificacionDouble = Double(calificacion),
              calificacionDouble >= 0 && calificacionDouble <= 100 else {
            error = "La calificación debe ser un número entre 0 y 100"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            _ = try await apiService.calificarEntrega(
                entregaId: entrega.id,
                calificacion: calificacionDouble,
                retroalimentacion: retroalimentacion.isEmpty ? nil : retroalimentacion,
                token: token
            )
            
            // Remover la entrega de la lista de sin calificar
            entregas.removeAll { $0.id == entrega.id }
            
            showingGradingSheet = false
            calificacion = ""
            retroalimentacion = ""
            gradingEntrega = nil
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch let generalError {
            error = generalError.localizedDescription
        }
        
        isLoading = false
    }
}

struct EntregasListView: View {
    @StateObject private var viewModel = EntregasListViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Cargando entregas...")
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        BotonEntregaUnificado(
                            titulo: "Reintentar",
                            tipo: .reintentar
                        ) {
                            Task {
                                if let token = authViewModel.authToken {
                                    await viewModel.cargarEntregasSinCalificar(token: token)
                                }
                            }
                        }
                    }
                } else if viewModel.entregas.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("¡Todas las entregas están calificadas!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("No hay entregas pendientes de calificar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.entregas) { entrega in
                            EntregaSinCalificarRowView(
                                entrega: entrega,
                                onCalificar: { entrega in
                                    viewModel.gradingEntrega = entrega
                                    viewModel.showingGradingSheet = true
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Entregas por Calificar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            if let token = authViewModel.authToken {
                                await viewModel.cargarEntregasSinCalificar(token: token)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingGradingSheet) {
                GradingSheetView(
                    entrega: viewModel.gradingEntrega,
                    calificacion: $viewModel.calificacion,
                    retroalimentacion: $viewModel.retroalimentacion,
                    isLoading: viewModel.isLoading,
                    onGrade: {
                        Task {
                            if let token = authViewModel.authToken {
                                await viewModel.calificarEntrega(token: token)
                            }
                        }
                    },
                    onCancel: {
                        viewModel.showingGradingSheet = false
                        viewModel.gradingEntrega = nil
                        viewModel.calificacion = ""
                        viewModel.retroalimentacion = ""
                    }
                )
            }
            .task {
                if let token = authViewModel.authToken {
                    await viewModel.cargarEntregasSinCalificar(token: token)
                }
            }
        }
    }
}

struct EntregaSinCalificarRowView: View {
    let entrega: Entrega
    let onCalificar: (Entrega) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    if let tarea = entrega.tarea {
                        Text(tarea.titulo)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    if let alumno = entrega.alumno {
                        Text("Alumno: \(alumno.nombreCompleto)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Entregado: \(formatDate(entrega.fechaEntrega))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                BotonEntregaUnificado(
                    titulo: "Calificar",
                    tipo: .calificar
                ) {
                    onCalificar(entrega)
                }
            }
            
            if let nombreArchivo = entrega.nombreArchivo {
                HStack {
                    Image(systemName: iconoParaArchivo(nombreArchivo))
                        .foregroundColor(.blue)
                    Text(nombreArchivo)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func iconoParaArchivo(_ nombreArchivo: String) -> String {
        let fileExtension = (nombreArchivo as NSString).pathExtension.lowercased()
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif":
            return "photo"
        case "pdf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}

#Preview {
    EntregasListView()
        .environmentObject(AuthenticationViewModel())
}
