import SwiftUI

// MARK: - Tipos de botón unificados
enum TipoBotonEntrega {
    case calificar
    case subirImagen
    case subirPDF
    case reintentar
}

// MARK: - Estilos unificados para botones de entrega
struct EstiloBotonEntrega {
    let backgroundColor: Color
    let foregroundColor: Color
    let icon: String
    let fontSize: Font
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    
    static let calificar = EstiloBotonEntrega(
        backgroundColor: .blue,
        foregroundColor: .white,
        icon: "pencil.circle",
        fontSize: .subheadline,
        padding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16),
        cornerRadius: 8
    )
    
    static let subirImagen = EstiloBotonEntrega(
        backgroundColor: .blue,
        foregroundColor: .white,
        icon: "camera",
        fontSize: .caption,
        padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10),
        cornerRadius: 6
    )
    
    static let subirPDF = EstiloBotonEntrega(
        backgroundColor: .green,
        foregroundColor: .white,
        icon: "doc.fill",
        fontSize: .caption,
        padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10),
        cornerRadius: 6
    )
    
    static let reintentar = EstiloBotonEntrega(
        backgroundColor: .blue,
        foregroundColor: .white,
        icon: "arrow.clockwise",
        fontSize: .subheadline,
        padding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
        cornerRadius: 8
    )
}

// MARK: - Componente de botón unificado
struct BotonEntregaUnificado: View {
    let titulo: String
    let tipo: TipoBotonEntrega
    let accion: () -> Void
    let isLoading: Bool
    
    init(titulo: String, tipo: TipoBotonEntrega, isLoading: Bool = false, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.tipo = tipo
        self.isLoading = isLoading
        self.accion = accion
    }
    
    private var estilo: EstiloBotonEntrega {
        switch tipo {
        case .calificar:
            return .calificar
        case .subirImagen:
            return .subirImagen
        case .subirPDF:
            return .subirPDF
        case .reintentar:
            return .reintentar
        }
    }
    
    var body: some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .foregroundColor(estilo.foregroundColor)
                } else {
                    Image(systemName: estilo.icon)
                        .font(estilo.fontSize)
                }
                
                Text(titulo)
                    .font(estilo.fontSize)
                    .fontWeight(.medium)
            }
            .padding(estilo.padding)
            .background(isLoading ? estilo.backgroundColor.opacity(0.6) : estilo.backgroundColor)
            .foregroundColor(estilo.foregroundColor)
            .cornerRadius(estilo.cornerRadius)
        }
        .disabled(isLoading)
    }
}

// MARK: - Grupo de botones para subir entregas (Versión con dos botones separados)
struct BotonesSubirEntrega: View {
    let isLoading: Bool
    let onSubirImagen: () -> Void
    let onSubirPDF: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            BotonEntregaUnificado(
                titulo: "Imagen",
                tipo: .subirImagen,
                isLoading: isLoading,
                accion: onSubirImagen
            )
            
            BotonEntregaUnificado(
                titulo: "PDF",
                tipo: .subirPDF,
                isLoading: isLoading,
                accion: onSubirPDF
            )
        }
    }
}

// MARK: - Botón único para subir entregas
struct BotonSubirEntrega: View {
    let isLoading: Bool
    let onSubirEntrega: () -> Void
    
    var body: some View {
        Button(action: onSubirEntrega) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                }
                
                Text("Nueva Entrega")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isLoading ? Color.blue.opacity(0.6) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Botón de calificar entrega
struct BotonCalificarEntrega: View {
    let entrega: Entrega
    let isLoading: Bool
    let onCalificar: (Entrega) -> Void
    
    var body: some View {
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
            BotonEntregaUnificado(
                titulo: "Calificar",
                tipo: .calificar,
                isLoading: isLoading,
                accion: { onCalificar(entrega) }
            )
        }
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
}

// MARK: - Vista tipo notificación para seleccionar tipo de entrega
struct NotificacionSeleccionEntrega: View {
    @Binding var nombreAlumno: String
    let isLoading: Bool
    let onSeleccionarImagen: () -> Void
    let onSeleccionarPDF: () -> Void
    let onCancelar: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Contenedor principal con efecto de tarjeta
            VStack(spacing: 16) {
                // Icono y título
                VStack(spacing: 8) {
                    Image(systemName: "paperclip.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Nueva Entrega")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Campo para nombre del alumno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre del estudiante")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Ingrese el nombre del alumno", text: $nombreAlumno)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isTextFieldFocused = false
                        }
                }
                .padding(.horizontal)
                
                Text("Selecciona el tipo de archivo a entregar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Botones de selección
                VStack(spacing: 12) {
                    // Botón Imagen
                    Button(action: onSeleccionarImagen) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Imagen")
                                    .font(.headline)
                                Text("JPG, PNG, HEIC")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(nombreAlumno.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || nombreAlumno.isEmpty)
                    
                    // Botón PDF
                    Button(action: onSeleccionarPDF) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Documento PDF")
                                    .font(.headline)
                                Text("Archivos PDF")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(nombreAlumno.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || nombreAlumno.isEmpty)
                }
                .padding(.horizontal)
                
                // Indicador de carga si está procesando
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Procesando...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                
                // Botón Cancelar
                Button(action: onCancelar) {
                    Text("Cancelar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                }
                .disabled(isLoading)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onTapGesture {
            // Cerrar el teclado al tocar fuera del campo de texto
            isTextFieldFocused = false
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var nombreAlumno = "Juan Pérez"
        
        var body: some View {
            VStack(spacing: 20) {
                // Botón único
                BotonSubirEntrega(
                    isLoading: false,
                    onSubirEntrega: { }
                )
                
                // Botón único cargando
                BotonSubirEntrega(
                    isLoading: true,
                    onSubirEntrega: { }
                )
                
                // Botones separados (para comparación)
                BotonesSubirEntrega(
                    isLoading: false,
                    onSubirImagen: { },
                    onSubirPDF: { }
                )
                
                // Notificación de selección
                NotificacionSeleccionEntrega(
                    nombreAlumno: $nombreAlumno,
                    isLoading: false,
                    onSeleccionarImagen: { },
                    onSeleccionarPDF: { },
                    onCancelar: { }
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}