import SwiftUI
import Combine
import PhotosUI

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var entregas: [Entrega] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isUploadingEntrega = false
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isShowingCamera = false
    @Published var capturedImage: UIImage?
    @Published var showingGradingSheet = false
    @Published var gradingEntrega: Entrega?
    @Published var calificacion: String = ""
    @Published var retroalimentacion: String = ""
    
    private let apiService = APIService.shared
    
    func cargarEntregas(token: String) async {
        isLoading = true
        error = nil
        
        do {
            entregas = try await apiService.obtenerMisEntregas(token: token)
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func subirEntrega(tarea: Tarea, image: UIImage, token: String) async {
        isUploadingEntrega = true
        error = nil
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            error = "No se pudo procesar la imagen"
            isUploadingEntrega = false
            return
        }
        
        let nombreArchivo = "entrega_tarea\(tarea.id)_\(Date().timeIntervalSince1970).jpg"
        
        do {
            let nuevaEntrega = try await apiService.crearEntrega(
                tareaId: tarea.id,
                archivo: imageData,
                nombreArchivo: nombreArchivo,
                token: token
            )
            entregas.append(nuevaEntrega)
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            error = error.localizedDescription
        }
        
        isUploadingEntrega = false
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
            let entregaCalificada = try await apiService.calificarEntrega(
                entregaId: entrega.id,
                calificacion: calificacionDouble,
                retroalimentacion: retroalimentacion.isEmpty ? nil : retroalimentacion,
                token: token
            )
            
            // Actualizar la entrega en la lista
            if let index = entregas.firstIndex(where: { $0.id == entrega.id }) {
                entregas[index] = entregaCalificada
            }
            
            showingGradingSheet = false
            calificacion = ""
            retroalimentacion = ""
            gradingEntrega = nil
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            error = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct TaskDetailView: View {
    let tarea: Tarea
    @StateObject private var viewModel = TaskDetailViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Información de la tarea
                VStack(alignment: .leading, spacing: 12) {
                    Text(tarea.titulo)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Estado:")
                            .font(.headline)
                        Text(tarea.estado.rawValue)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorParaEstado(tarea.estado).opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    if let descripcion = tarea.descripcion, !descripcion.isEmpty {
                        Text("Descripción:")
                            .font(.headline)
                        Text(descripcion)
                            .font(.body)
                    }
                }
                
                Divider()
                
                // Sección de entregas
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Entregas")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        // Botón para agregar entrega (solo si no hay entrega para esta tarea)
                        if !tieneEntregaParaTarea() && !viewModel.isUploadingEntrega {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Subir Entrega")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("Cargando entregas...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if viewModel.entregas.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No hay entregas para esta tarea")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(entregasParaTarea(), id: \.id) { entrega in
                                EntregaRowView(
                                    entrega: entrega,
                                    onCalificar: { entrega in
                                        viewModel.gradingEntrega = entrega
                                        viewModel.showingGradingSheet = true
                                    }
                                )
                            }
                        }
                    }
                    
                    if viewModel.isUploadingEntrega {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Subiendo entrega...")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Detalle de Tarea")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { image in
                if let image = image {
                    Task {
                        if let token = authViewModel.authToken {
                            await viewModel.subirEntrega(tarea: tarea, image: image, token: token)
                        }
                    }
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
                await viewModel.cargarEntregas(token: token)
            }
        }
    }
    
    private func tieneEntregaParaTarea() -> Bool {
        return viewModel.entregas.contains { $0.tareaId == tarea.id }
    }
    
    private func entregasParaTarea() -> [Entrega] {
        return viewModel.entregas.filter { $0.tareaId == tarea.id }
    }
}

// Helper para colores de estado
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
