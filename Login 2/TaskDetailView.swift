import SwiftUI
import Combine

struct TaskDetailView: View {
    let tarea: Tarea

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tarea.titulo)
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack {
                Text("Estado:")
                    .font(.headline)
                Text(tarea.estado.rawValue)
                    .foregroundColor(.secondary)
            }

            if let descripcion = tarea.descripcion {
                Text(descripcion)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detalle de Tarea")
        .navigationBarTitleDisplayMode(.inline)
    }
}
