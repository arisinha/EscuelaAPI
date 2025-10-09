
import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers

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
    @Published var isShowingDocumentPicker = false
    @Published var selectedDocumentURL: URL?
    @Published var nombreAlumno: String = ""
    @Published var showingNameDialog = false
    
    private let apiService = APIService.shared
    
    func cargarEntregas(token: String) async {
        isLoading = true
        error = nil
        
        do {
            entregas = try await apiService.obtenerMisEntregas(token: token)
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch let generalError {
            error = generalError.localizedDescription
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
        
        let nombreSanitizado = nombreAlumno.isEmpty ? "Alumno" : nombreAlumno.replacingOccurrences(of: " ", with: "_")
        let nombreArchivo = "\(nombreSanitizado)_tarea\(tarea.id)_\(Date().timeIntervalSince1970).jpg"
        
        do {
            let nuevaEntrega = try await apiService.crearEntregaConComentario(
                tareaId: tarea.id,
                archivo: imageData,
                nombreArchivo: nombreArchivo,
                comentario: nombreAlumno.isEmpty ? nil : "Entrega de: \(nombreAlumno)",
                token: token
            )
            
            await cargarEntregas(token: token)
            nombreAlumno = "" // Limpiar el campo después de subir
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch let generalError {
            error = generalError.localizedDescription
        }
        
        isUploadingEntrega = false
    }
    
    func subirDocumento(tarea: Tarea, documentURL: URL, token: String) async {
        isUploadingEntrega = true
        error = nil
        
        guard documentURL.startAccessingSecurityScopedResource() else {
            error = "No se pudo acceder al documento"
            isUploadingEntrega = false
            return
        }
        
        defer { documentURL.stopAccessingSecurityScopedResource() }
        
        do {
            let documentData = try Data(contentsOf: documentURL)
            let originalName = documentURL.lastPathComponent
            let nombreSanitizado = nombreAlumno.isEmpty ? "Alumno" : nombreAlumno.replacingOccurrences(of: " ", with: "_")
            let fileExtension = (originalName as NSString).pathExtension
            let nombreArchivo = "\(nombreSanitizado)_tarea\(tarea.id)_\(Date().timeIntervalSince1970).\(fileExtension)"
            
            let nuevaEntrega = try await apiService.crearEntregaConComentario(
                tareaId: tarea.id,
                archivo: documentData,
                nombreArchivo: nombreArchivo,
                comentario: nombreAlumno.isEmpty ? nil : "Entrega de: \(nombreAlumno)",
                token: token
            )
            
            await cargarEntregas(token: token)
            selectedDocumentURL = nil
            nombreAlumno = "" // Limpiar el campo después de subir
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch let generalError {
            error = generalError.localizedDescription
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
        } catch let generalError {
            error = generalError.localizedDescription
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
                        
                        // Botones para agregar entrega (siempre disponibles)
                        if !viewModel.isUploadingEntrega {
                            HStack(spacing: 8) {
                                Button(action: {
                                    viewModel.showingNameDialog = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Imagen")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .font(.caption)
                                }
                                
                                Button(action: {
                                    viewModel.showingNameDialog = true
                                }) {
                                    HStack {
                                        Image(systemName: "doc.fill")
                                        Text("PDF")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .font(.caption)
                                }
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
        .sheet(isPresented: $viewModel.isShowingDocumentPicker) {
            DocumentPickerView(
                allowedContentTypes: [.pdf],
                onDocumentPicked: { url in
                    viewModel.selectedDocumentURL = url
                    Task {
                        if let token = authViewModel.authToken {
                            await viewModel.subirDocumento(tarea: tarea, documentURL: url, token: token)
                        }
                    }
                }
            )
        }
        .alert("Nombre del Alumno", isPresented: $viewModel.showingNameDialog) {
            TextField("Ingrese el nombre del alumno", text: $viewModel.nombreAlumno)
            Button("Imagen") {
                showingImagePicker = true
            }
            Button("PDF") {
                viewModel.isShowingDocumentPicker = true
            }
            Button("Cancelar", role: .cancel) {
                viewModel.nombreAlumno = ""
            }
        } message: {
            Text("Ingrese el nombre del alumno para identificar la entrega")
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
    case .Abierto:
        return .blue
    case .Cerrado:
        return .green
    }
}

// DocumentPickerView para seleccionar PDFs
struct DocumentPickerView: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentPicked(url)
            }
        }
    }
}
