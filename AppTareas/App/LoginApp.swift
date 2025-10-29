import SwiftUI
import Combine

@main
struct UniversityApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel.shared
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.usuarioAutenticado != nil {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
