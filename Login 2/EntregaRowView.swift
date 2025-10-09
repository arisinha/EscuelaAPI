import SwiftUI

struct EntregaRowView: View {
    let entrega: Entrega
    let onCalificar: (Entrega) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entrega #\(entrega.id)")
                        .font(.headline)
                    Text("Enviado: \(formatDate(entrega.fechaEntrega))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if entrega.estaCalificada {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Calificación")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", entrega.calificacion ?? 0))/100")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorParaCalificacion(entrega.calificacion ?? 0))
                    }
                } else {
                    Button("Calificar") {
                        onCalificar(entrega)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
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
            
            if entrega.estaCalificada {
                if let retroalimentacion = entrega.retroalimentacionProfesor, !retroalimentacion.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Retroalimentación del Profesor:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(retroalimentacion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let fechaCalificacion = entrega.fechaCalificacion {
                    Text("Calificado: \(formatDate(fechaCalificacion))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
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
    
    private func iconoParaArchivo(_ nombreArchivo: String) -> String {
        let extension = (nombreArchivo as NSString).pathExtension.lowercased()
        switch extension {
        case "jpg", "jpeg", "png", "gif":
            return "photo"
        case "pdf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}