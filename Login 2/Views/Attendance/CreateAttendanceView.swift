import SwiftUI

struct CreateAttendanceView: View {
    let grupo: Grupo
    let fecha: Date
    let token: String
    let onAsistenciaCreada: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var estadoSeleccionado: EstadoAsistencia = .presente
    @State private var observaciones: String = ""
    @State private var alumnoSeleccionado: Usuario?
    @State private var alumnos: [Usuario] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCrearAlumno = false
    @State private var estadoDeCargaAlumnos = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Grupo")) {
                    HStack {
                        Text("Materia:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(grupo.nombreMateria)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Código:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(grupo.codigoGrupo)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Fecha:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(fecha, style: .date)
                            .fontWeight(.medium)
                    }
                }
                
                Section(header: Text("Seleccionar Alumno")) {
                    if estadoDeCargaAlumnos {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if alumnos.isEmpty {
                        VStack(spacing: 12) {
                            Text("No hay alumnos registrados")
                                .foregroundColor(.secondary)
                            Button(action: {
                                showingCrearAlumno = true
                            }) {
                                Label("Crear Nuevo Alumno", systemImage: "person.badge.plus")
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Picker("Alumno", selection: $alumnoSeleccionado) {
                            Text("Seleccionar...").tag(nil as Usuario?)
                            ForEach(alumnos) { alumno in
                                Text(alumno.nombreCompleto).tag(alumno as Usuario?)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button(action: {
                            showingCrearAlumno = true
                        }) {
                            Label("Agregar Nuevo Alumno", systemImage: "person.badge.plus")
                        }
                    }
                }
                
                Section(header: Text("Estado de Asistencia")) {
                    Picker("Estado", selection: $estadoSeleccionado) {
                        ForEach(EstadoAsistencia.allCases, id: \.self) { estado in
                            HStack {
                                Circle()
                                    .fill(estadoColor(for: estado))
                                    .frame(width: 10, height: 10)
                                Text(estado.displayName)
                            }
                            .tag(estado)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Observaciones (Opcional)")) {
                    TextEditor(text: $observaciones)
                        .frame(minHeight: 80)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Registrar Asistencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await guardarAsistencia()
                        }
                    }
                    .disabled(alumnoSeleccionado == nil || isLoading)
                }
            }
            .sheet(isPresented: $showingCrearAlumno) {
                CreateStudentView(
                    grupoId: grupo.id,
                    token: token,
                    onAlumnoCreado: { nuevoAlumno in
                        alumnos.append(nuevoAlumno)
                        alumnoSeleccionado = nuevoAlumno
                    }
                )
            }
            .task {
                await cargarAlumnos()
            }
        }
    }
    
    private func cargarAlumnos() async {
        estadoDeCargaAlumnos = true
        // Por ahora, simulamos una lista de alumnos
        // En una implementación real, harías una llamada a la API para obtener los alumnos del grupo
        // TODO: Implementar endpoint para obtener alumnos de un grupo
        
        // Simulación de datos
        alumnos = [
            Usuario(id: 1, nombreUsuario: "alumno1", nombreCompleto: "Juan Pérez"),
            Usuario(id: 2, nombreUsuario: "alumno2", nombreCompleto: "María González"),
            Usuario(id: 3, nombreUsuario: "alumno3", nombreCompleto: "Carlos Rodríguez")
        ]
        estadoDeCargaAlumnos = false
    }
    
    private func guardarAsistencia() async {
        guard let alumno = alumnoSeleccionado else {
            errorMessage = "Por favor selecciona un alumno"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await APIService.shared.crearAsistencia(
                usuarioId: alumno.id,
                grupoId: grupo.id,
                fecha: fecha,
                estado: estadoSeleccionado,
                observaciones: observaciones.isEmpty ? nil : observaciones,
                token: token
            )
            
            onAsistenciaCreada()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func estadoColor(for estado: EstadoAsistencia) -> Color {
        switch estado {
        case .presente:
            return .green
        case .ausente:
            return .red
        case .justificado:
            return .orange
        }
    }
}

// Vista para crear un nuevo alumno
struct CreateStudentView: View {
    let grupoId: Int
    let token: String
    let onAlumnoCreado: (Usuario) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var nombreUsuario: String = ""
    @State private var nombreCompleto: String = ""
    @State private var contrasena: String = ""
    @State private var confirmarContrasena: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Alumno")) {
                    TextField("Nombre de usuario", text: $nombreUsuario)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Nombre completo", text: $nombreCompleto)
                        .textInputAutocapitalization(.words)
                    
                    SecureField("Contraseña", text: $contrasena)
                    
                    SecureField("Confirmar contraseña", text: $confirmarContrasena)
                }
                
                Section(header: Text("Información del Grupo")) {
                    HStack {
                        Text("Grupo ID:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(grupoId)")
                            .fontWeight(.medium)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nuevo Alumno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        Task {
                            await crearAlumno()
                        }
                    }
                    .disabled(!formularioValido || isLoading)
                }
            }
        }
    }
    
    private var formularioValido: Bool {
        !nombreUsuario.isEmpty &&
        !nombreCompleto.isEmpty &&
        !contrasena.isEmpty &&
        contrasena == confirmarContrasena &&
        contrasena.count >= 6
    }
    
    private func crearAlumno() async {
        guard formularioValido else {
            errorMessage = "Por favor completa todos los campos correctamente"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Registrar el nuevo usuario
            let response = try await APIService.shared.register(
                nombreUsuario: nombreUsuario,
                contrasena: contrasena,
                nombreCompleto: nombreCompleto
            )
            
            // El usuario se ha registrado exitosamente
            onAlumnoCreado(response.usuario)
            dismiss()
        } catch {
            errorMessage = "Error al crear el alumno: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    CreateAttendanceView(
        grupo: Grupo(id: 1, nombreMateria: "Programación Móvil", codigoGrupo: "PM-101"),
        fecha: Date(),
        token: "token-preview",
        onAsistenciaCreada: {}
    )
}
