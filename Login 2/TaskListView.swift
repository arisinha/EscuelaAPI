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
            // Usar la nueva función que filtra por grupo específico
            self.tareas = try await apiService.obtenerTareasPorGrupo(grupoId: grupo.id, token: token)
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        estadoDeCarga = false
    }
    
    func agregarTarea(_ tarea: Tarea) {
        tareas.insert(tarea, at: 0) // Agregar al inicio de la lista
    }
    
    func actualizarTarea(_ tareaActualizada: Tarea) {
        if let index = tareas.firstIndex(where: { $0.id == tareaActualizada.id }) {
            tareas[index] = tareaActualizada
        }
    }
    
    func eliminarTarea(_ tarea: Tarea) {
        tareas.removeAll { $0.id == tarea.id }
    }
}

struct TasksListView: View {
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCrearTarea = false
    @State private var showingEditarTarea = false
    @State private var showingEliminarConfirmacion = false
    @State private var tareaSeleccionadaParaEditar: Tarea?
    @State private var tareaSeleccionadaParaEliminar: Tarea?
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
                    
                    Button("Crear Primera Tarea") {
                        showingCrearTarea = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                List(viewModel.tareas) { tarea in
                    HStack {
                        // Contenido de la tarea
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
                        
                        // Menú de opciones
                        Menu {
                            Button {
                                tareaSeleccionadaParaEditar = tarea
                                showingEditarTarea = true
                            } label: {
                                HStack {
                                    Text("Editar")
                                    Spacer()
                                    Image(systemName: "pencil")
                                }
                            }
                            
                            Button(role: .destructive) {
                                tareaSeleccionadaParaEliminar = tarea
                                showingEliminarConfirmacion = true
                            } label: {
                                HStack {
                                    Text("Eliminar")
                                    Spacer()
                                    Image(systemName: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .navigationTitle(grupo.nombreMateria)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCrearTarea = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCrearTarea) {
            CrearTareaView(grupo: grupo) { nuevaTarea in
                viewModel.agregarTarea(nuevaTarea)
            }
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditarTarea) {
            if let tareaSeleccionada = tareaSeleccionadaParaEditar {
                EditarTareaView(tarea: tareaSeleccionada, grupo: grupo) { tareaActualizada in
                    viewModel.actualizarTarea(tareaActualizada)
                }
                .environmentObject(authViewModel)
            }
        }
        .alert("Eliminar Tarea", isPresented: $showingEliminarConfirmacion) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let tareaSeleccionada = tareaSeleccionadaParaEliminar {
                    Task {
                        await eliminarTarea(tareaSeleccionada)
                    }
                }
            }
        } message: {
            if let tareaSeleccionada = tareaSeleccionadaParaEliminar {
                Text("¿Estás seguro de que deseas eliminar la tarea '\(tareaSeleccionada.titulo)'? Esta acción no se puede deshacer.")
            }
        }
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
    
    private func eliminarTarea(_ tarea: Tarea) async {
        guard let token = authViewModel.authToken else {
            viewModel.error = "No se encontró token de autenticación."
            return
        }
        
        do {
            try await APIService.shared.eliminarTarea(id: tarea.id, token: token)
            viewModel.eliminarTarea(tarea)
        } catch {
            viewModel.error = "Error al eliminar la tarea: \(error.localizedDescription)"
        }
    }
    
    // Helper para asignar colores según el estado
    private func colorParaEstado(_ estado: EstadoTarea) -> Color {
        switch estado {
        case .Abierto:
            return .blue
        case .Cerrado:
            return .green
        }
    }
}

struct CrearTareaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var titulo = ""
    @State private var descripcion = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let grupo: Grupo
    let onTareaCreada: (Tarea) -> Void
    
    var isFormValid: Bool {
        !titulo.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la Tarea")) {
                    TextField("Título de la Tarea", text: $titulo)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Descripción (Opcional)", text: $descripcion, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Grupo")) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(grupo.nombreMateria)
                                .font(.headline)
                            Text(grupo.codigoGrupo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nueva Tarea")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        Task {
                            await crearTarea()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .disabled(isCreating)
            .overlay(
                Group {
                    if isCreating {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Creando tarea...")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                }
            )
        }
    }
    
    private func crearTarea() async {
        guard let token = authViewModel.authToken else {
            errorMessage = "No se encontró token de autenticación."
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let tareaCreada = try await APIService.shared.crearTarea(
                titulo: titulo.trimmingCharacters(in: .whitespaces),
                descripcion: descripcion.trimmingCharacters(in: .whitespaces).isEmpty ? nil : descripcion.trimmingCharacters(in: .whitespaces),
                grupoId: grupo.id,
                token: token
            )
            
            // Notificar al componente padre que se creó la tarea
            onTareaCreada(tareaCreada)
            
            // Cerrar el modal
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCreating = false
    }
}

struct EditarTareaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var titulo: String
    @State private var descripcion: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    let tarea: Tarea
    let grupo: Grupo
    let onTareaActualizada: (Tarea) -> Void
    
    init(tarea: Tarea, grupo: Grupo, onTareaActualizada: @escaping (Tarea) -> Void) {
        self.tarea = tarea
        self.grupo = grupo
        self.onTareaActualizada = onTareaActualizada
        // Inicializar los campos con los datos actuales
        _titulo = State(initialValue: tarea.titulo)
        _descripcion = State(initialValue: tarea.descripcion ?? "")
    }
    
    var isFormValid: Bool {
        !titulo.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var hasChanges: Bool {
        let newTitulo = titulo.trimmingCharacters(in: .whitespaces)
        let newDescripcion = descripcion.trimmingCharacters(in: .whitespaces)
        let originalDescripcion = tarea.descripcion ?? ""
        
        return newTitulo != tarea.titulo || newDescripcion != originalDescripcion
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sección con los datos actuales de la tarea
                Section(header: Text("Datos Actuales")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Título Actual")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(tarea.titulo)
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        
                        if let descripcionActual = tarea.descripcion, !descripcionActual.isEmpty {
                            Divider()
                            HStack(alignment: .top) {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("Descripción Actual")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(descripcionActual)
                                        .font(.body)
                                }
                                Spacer()
                            }
                        }
                        
                        Divider()
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Estado")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Circle()
                                        .fill(tarea.estado == .Cerrado ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    Text(tarea.estado == .Cerrado ? "Completada" : "Pendiente")
                                        .font(.body)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Nuevos Datos")) {
                    TextField("Título de la Tarea", text: $titulo)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Descripción (Opcional)", text: $descripcion, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Grupo")) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(grupo.nombreMateria)
                                .font(.headline)
                            Text(grupo.codigoGrupo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Editar Tarea")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Actualizar") {
                        Task {
                            await actualizarTarea()
                        }
                    }
                    .disabled(!isFormValid || !hasChanges || isUpdating)
                }
            }
            .disabled(isUpdating)
            .overlay(
                Group {
                    if isUpdating {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Actualizando tarea...")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                }
            )
        }
    }
    
    private func actualizarTarea() async {
        guard let token = authViewModel.authToken else {
            errorMessage = "No se encontró token de autenticación."
            return
        }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            let tareaActualizada = try await APIService.shared.actualizarTarea(
                id: tarea.id,
                titulo: titulo.trimmingCharacters(in: .whitespaces),
                descripcion: descripcion.trimmingCharacters(in: .whitespaces).isEmpty ? nil : descripcion.trimmingCharacters(in: .whitespaces),
                grupoId: grupo.id,
                token: token
            )
            
            // Notificar al componente padre que se actualizó la tarea
            onTareaActualizada(tareaActualizada)
            
            // Cerrar el modal
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
}

#Preview {
    CrearTareaView(
        grupo: Grupo(id: 1, nombreMateria: "Matemáticas", codigoGrupo: "MAT-101"),
        onTareaCreada: { _ in }
    )
    .environmentObject(AuthenticationViewModel())
}
