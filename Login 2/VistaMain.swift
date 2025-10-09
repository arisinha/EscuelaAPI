import SwiftUI
import Combine

struct MainView: View {
    var body: some View {
        // TabView es el equivalente directo de TabBar en MAUI Shell.
        TabView {
            // PRIMERA PESTAÑA: Lista de Asignaciones
            // Envolvemos la lista en un NavigationStack para permitir
            // la navegación hacia la vista de detalle.
            AssignmentsListView()
                .tabItem {
                    Label("Asignaciones", systemImage: "list.bullet.rectangle.portrait")
                }
            
            // SEGUNDA PESTAÑA: Perfil (ejemplo)
            Text("Pantalla de Perfil")
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
    }
}
