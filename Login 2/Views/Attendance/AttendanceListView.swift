import SwiftUI

// ViewModel para gestionar la lista de asistencias de un grupo
@MainActor
class AttendanceViewModel: ObservableObject {
    @Published var asistencias: [Asistencia] = []
    @Published var estadoDeCarga = false
    @Published var error: String?
    @Published var selectedDate = Date()
    
    private let apiService = APIService.shared
    
    func cargarAsistencias(grupoId: Int, fecha: Date, token: String) async {
        estadoDeCarga = true
        error = nil
        do {
            let asistenciasObtenidas = try await apiService.obtenerAsistenciasPorGrupoYFecha(
                grupoId: grupoId,
                fecha: fecha,
                token: token
            )
            self.asistencias = asistenciasObtenidas
        } catch {
            self.error = error.localizedDescription
        }
        estadoDeCarga = false
    }
    
    func crearAsistencia(usuarioId: Int, grupoId: Int, fecha: Date, estado: EstadoAsistencia, observaciones: String?, token: String) async throws {
        let nuevaAsistencia = try await apiService.crearAsistencia(
            usuarioId: usuarioId,
            grupoId: grupoId,
            fecha: fecha,
            estado: estado,
            observaciones: observaciones,
            token: token
        )
        
        // Agregar a la lista local
        asistencias.append(nuevaAsistencia)
    }
}

struct AttendanceListView: View {
    let grupo: Grupo
    @StateObject private var viewModel = AttendanceViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCrearAsistencia = false
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Picker Section
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Fecha de asistencia:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        showingDatePicker.toggle()
                    }) {
                        HStack {
                            Text(viewModel.selectedDate, style: .date)
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                if showingDatePicker {
                    DatePicker(
                        "Seleccionar fecha",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                        Task {
                            if let token = authViewModel.authToken {
                                await viewModel.cargarAsistencias(grupoId: grupo.id, fecha: newValue, token: token)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            
            Divider()
            
            // Content
            if viewModel.estadoDeCarga {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Reintentar") {
                        Task {
                            if let token = authViewModel.authToken {
                                await viewModel.cargarAsistencias(grupoId: grupo.id, fecha: viewModel.selectedDate, token: token)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if viewModel.asistencias.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No hay asistencias registradas")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("para esta fecha")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Registrar Asistencia") {
                        showingCrearAsistencia = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.asistencias) { asistencia in
                        AttendanceRowView(asistencia: asistencia)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Asistencia - \(grupo.nombreMateria)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCrearAsistencia = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCrearAsistencia) {
            if let token = authViewModel.authToken {
                CreateAttendanceView(
                    grupo: grupo,
                    fecha: viewModel.selectedDate,
                    token: token,
                    onAsistenciaCreada: {
                        Task {
                            await viewModel.cargarAsistencias(grupoId: grupo.id, fecha: viewModel.selectedDate, token: token)
                        }
                    }
                )
            }
        }
        .task {
            if let token = authViewModel.authToken {
                await viewModel.cargarAsistencias(grupoId: grupo.id, fecha: viewModel.selectedDate, token: token)
            }
        }
    }
}

// Vista para mostrar una fila de asistencia
struct AttendanceRowView: View {
    let asistencia: Asistencia
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de estado
            Circle()
                .fill(estadoColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                if let usuario = asistencia.usuario {
                    Text(usuario.nombreCompleto)
                        .font(.headline)
                } else {
                    Text("Usuario #\(asistencia.usuarioId)")
                        .font(.headline)
                }
                
                HStack(spacing: 8) {
                    Label(asistencia.estado.displayName, systemImage: estadoIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let observaciones = asistencia.observaciones, !observaciones.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(observaciones)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Badge del estado
            Text(asistencia.estado.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(estadoColor.opacity(0.2))
                .foregroundColor(estadoColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    private var estadoColor: Color {
        switch asistencia.estado {
        case .presente:
            return .green
        case .ausente:
            return .red
        case .justificado:
            return .orange
        }
    }
    
    private var estadoIcon: String {
        switch asistencia.estado {
        case .presente:
            return "checkmark.circle.fill"
        case .ausente:
            return "xmark.circle.fill"
        case .justificado:
            return "exclamationmark.circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        AttendanceListView(grupo: Grupo(id: 1, nombreMateria: "Programación Móvil", codigoGrupo: "PM-101"))
            .environmentObject(AuthenticationViewModel())
    }
}
