import SwiftUI

struct GradingSheetView: View {
    let entrega: Entrega?
    @Binding var calificacion: String
    @Binding var retroalimentacion: String
    let isLoading: Bool
    let onGrade: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isCalificacionFocused: Bool
    @FocusState private var isRetroalimentacionFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let entrega = entrega {
                        // Información de la entrega
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calificar Entrega")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Group {
                                HStack {
                                    Text("Entrega ID:")
                                        .fontWeight(.semibold)
                                    Text("#\(entrega.id)")
                                        .foregroundColor(.secondary)
                                }
                                
                                if let alumno = entrega.alumno {
                                    HStack {
                                        Text("Alumno:")
                                            .fontWeight(.semibold)
                                        Text(alumno.nombreCompleto)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HStack {
                                    Text("Fecha de entrega:")
                                        .fontWeight(.semibold)
                                    Text(formatDate(entrega.fechaEntrega))
                                        .foregroundColor(.secondary)
                                }
                                
                                if let nombreArchivo = entrega.nombreArchivo {
                                    HStack {
                                        Text("Archivo:")
                                            .fontWeight(.semibold)
                                        HStack {
                                            Image(systemName: iconoParaArchivo(nombreArchivo))
                                                .foregroundColor(.blue)
                                            Text(nombreArchivo)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .font(.caption)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Formulario de calificación
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Calificación (0-100)")
                                    .font(.headline)
                                
                                TextField("Ingrese la calificación", text: $calificacion)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isCalificacionFocused)
                                
                                if !calificacion.isEmpty {
                                    if let calificacionDouble = Double(calificacion) {
                                        if calificacionDouble < 0 || calificacionDouble > 100 {
                                            Text("La calificación debe estar entre 0 y 100")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        } else {
                                            HStack {
                                                Text("Equivalente:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(descripcionCalificacion(calificacionDouble))
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(colorParaCalificacion(calificacionDouble))
                                            }
                                        }
                                    } else {
                                        Text("Ingrese un número válido")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Retroalimentación (Opcional)")
                                    .font(.headline)
                                
                                TextEditor(text: $retroalimentacion)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .focused($isRetroalimentacionFocused)
                                
                                Text("\(retroalimentacion.count)/1000 caracteres")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        // Botones de acción
                        HStack(spacing: 16) {
                            Button("Cancelar") {
                                onCancel()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            
                            Button("Calificar") {
                                onGrade()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidCalificacion() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(!isValidCalificacion() || isLoading)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Guardando calificación...")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Calificar Entrega")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        isCalificacionFocused = false
                        isRetroalimentacionFocused = false
                    }
                }
            }
        }
    }
    
    private func isValidCalificacion() -> Bool {
        guard let calificacionDouble = Double(calificacion) else { return false }
        return calificacionDouble >= 0 && calificacionDouble <= 100 && retroalimentacion.count <= 1000
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func colorParaCalificacion(_ calificacion: Double) -> Color {
        switch calificacion {
        case 90...100:
            return .green
        case 70..<90:
            return .blue
        case 60..<70:
            return .orange
        default:
            return .red
        }
    }
    
    private func descripcionCalificacion(_ calificacion: Double) -> String {
        switch calificacion {
        case 90...100:
            return "Excelente"
        case 80..<90:
            return "Muy Bueno"
        case 70..<80:
            return "Bueno"
        case 60..<70:
            return "Suficiente"
        default:
            return "Insuficiente"
        }
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