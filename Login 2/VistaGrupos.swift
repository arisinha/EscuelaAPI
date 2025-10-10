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
    
    func agregarGrupo(_ nuevoGrupo: Grupo) {
        grupos.append(nuevoGrupo)
        // También actualizar DataService
        DataService.shared.actualizarGrupos(grupos)
    }
    
    func actualizarGrupo(_ grupo: Grupo, token: String) async throws {
        let grupoActualizado = try await APIService.shared.actualizarGrupo(
            id: grupo.id,
            nombreMateria: grupo.nombreMateria,
            codigoGrupo: grupo.codigoGrupo,
            token: token
        )
        
        // Actualizar la lista local
        if let index = grupos.firstIndex(where: { $0.id == grupo.id }) {
            grupos[index] = grupoActualizado
            DataService.shared.actualizarGrupos(grupos)
        }
    }
    
    func eliminarGrupo(_ grupo: Grupo, token: String) async throws {
        try await APIService.shared.eliminarGrupo(id: grupo.id, token: token)
        
        // Eliminar de la lista local
        grupos.removeAll { $0.id == grupo.id }
        DataService.shared.actualizarGrupos(grupos)
    }
}

struct GroupsListView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingEntregasListView = false
    @State private var showingCrearGrupo = false
    @State private var showingEditarGrupo = false
    @State private var showingEliminarConfirmacion = false
    @State private var grupoSeleccionado: Grupo?

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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCrearGrupo = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            } else if viewModel.grupos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No hay grupos disponibles")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Button("Crear Primer Grupo") {
                        showingCrearGrupo = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .navigationTitle("Mis Grupos")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCrearGrupo = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
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
                        HStack {
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
                            
                            Spacer()
                            
                            // Menú de opciones
                            Menu {
                                Button {
                                    grupoSeleccionado = grupo
                                    showingEditarGrupo = true
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    grupoSeleccionado = grupo
                                    showingEliminarConfirmacion = true
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondary)
                                    .font(.title2)
                                    .rotationEffect(.degrees(90))
                            }
                        }
                    }
                }
                .navigationTitle("Mis Grupos")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCrearGrupo = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .navigationDestination(for: Grupo.self) { grupoSeleccionado in
                    TasksListView(grupo: grupoSeleccionado)
                }
            }
        }
        .sheet(isPresented: $showingEntregasListView) {
            EntregasListView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingCrearGrupo) {
            CrearGrupoView { nuevoGrupo in
                viewModel.agregarGrupo(nuevoGrupo)
            }
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditarGrupo) {
            if let grupo = grupoSeleccionado {
                EditarGrupoView(grupo: grupo) { grupoActualizado in
                    Task {
                        do {
                            if let token = authViewModel.authToken {
                                try await viewModel.actualizarGrupo(grupoActualizado, token: token)
                            }
                        } catch {
                            viewModel.error = error.localizedDescription
                        }
                    }
                }
                .environmentObject(authViewModel)
            }
        }
        .alert("Confirmar Eliminación", isPresented: $showingEliminarConfirmacion, presenting: grupoSeleccionado) { grupo in
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                Task {
                    do {
                        if let token = authViewModel.authToken {
                            try await viewModel.eliminarGrupo(grupo, token: token)
                        }
                    } catch {
                        viewModel.error = error.localizedDescription
                    }
                }
            }
        } message: { grupo in
            Text("¿Estás seguro que deseas eliminar el grupo '\(grupo.nombreMateria) - \(grupo.codigoGrupo)'?")
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

struct CrearGrupoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var nombreMateria = ""
    @State private var codigoGrupo = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let onGrupoCreado: (Grupo) -> Void
    
    var isFormValid: Bool {
        !nombreMateria.trimmingCharacters(in: .whitespaces).isEmpty &&
        !codigoGrupo.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Grupo")) {
                    TextField("Nombre de la Materia", text: $nombreMateria)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Código del Grupo", text: $codigoGrupo)
                        .textInputAutocapitalization(.characters)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nuevo Grupo")
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
                            await crearGrupo()
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
                            Text("Creando grupo...")
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
    
    private func crearGrupo() async {
        guard let token = authViewModel.authToken else {
            errorMessage = "No se encontró token de autenticación."
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let grupoCreado = try await APIService.shared.crearGrupo(
                nombreMateria: nombreMateria.trimmingCharacters(in: .whitespaces),
                codigoGrupo: codigoGrupo.trimmingCharacters(in: .whitespaces),
                token: token
            )
            
            // Notificar al componente padre que se creó el grupo
            onGrupoCreado(grupoCreado)
            
            // Cerrar el modal
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCreating = false
    }
}

struct EditarGrupoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var nombreMateria: String
    @State private var codigoGrupo: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    let grupo: Grupo
    let onGrupoActualizado: (Grupo) -> Void
    
    init(grupo: Grupo, onGrupoActualizado: @escaping (Grupo) -> Void) {
        self.grupo = grupo
        self.onGrupoActualizado = onGrupoActualizado
        // Inicializar los campos con los datos actuales
        _nombreMateria = State(initialValue: grupo.nombreMateria)
        _codigoGrupo = State(initialValue: grupo.codigoGrupo)
    }
    
    var isFormValid: Bool {
        !nombreMateria.trimmingCharacters(in: .whitespaces).isEmpty &&
        !codigoGrupo.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var hasChanges: Bool {
        let newNombreMateria = nombreMateria.trimmingCharacters(in: .whitespaces)
        let newCodigoGrupo = codigoGrupo.trimmingCharacters(in: .whitespaces)
        
        return newNombreMateria != grupo.nombreMateria || newCodigoGrupo != grupo.codigoGrupo
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sección con los datos actuales del grupo
                Section(header: Text("Datos Actuales")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Materia Actual")
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
                            VStack(alignment: .leading) {
                                Text("Código Actual")
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
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Nuevos Datos")) {
                    TextField("Nombre de la Materia", text: $nombreMateria)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Código del Grupo", text: $codigoGrupo)
                        .textInputAutocapitalization(.characters)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Editar Grupo")
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
                            await actualizarGrupo()
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
                            Text("Actualizando grupo...")
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
    
    private func actualizarGrupo() async {
        guard let token = authViewModel.authToken else {
            errorMessage = "No se encontró token de autenticación."
            return
        }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            let grupoActualizado = try await APIService.shared.actualizarGrupo(
                id: grupo.id,
                nombreMateria: nombreMateria.trimmingCharacters(in: .whitespaces),
                codigoGrupo: codigoGrupo.trimmingCharacters(in: .whitespaces),
                token: token
            )
            
            // Notificar al componente padre que se actualizó el grupo
            onGrupoActualizado(grupoActualizado)
            
            // Cerrar el modal
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
}

#Preview {
    GroupsListView()
        .environmentObject(AuthenticationViewModel())
}
