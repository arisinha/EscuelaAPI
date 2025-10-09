import SwiftUI
import Combine

// El ViewModel para la lógica de la pantalla de Login.
class LoginViewModel: ObservableObject {
    @Published var teacherID = ""
    @Published var password = ""
    @Published var isLoading = false
    
    // Este método es el equivalente al "Command" en MAUI.
    // La vista lo llamará directamente.
    func performLogin(authViewModel: AuthenticationViewModel) {
        isLoading = true
        print("Iniciando sesión para el profesor: \(teacherID)")
        
        // Llamamos al método del ViewModel de autenticación global.
        authViewModel.login()
        
        // Nota: isLoading se quedaría en true porque la vista desaparecerá.
        // En un caso real, manejarías el final de la carga al recibir una respuesta.
    }
}

struct LoginView: View {
    // Creamos una instancia del ViewModel específica para esta vista.
    @StateObject private var viewModel = LoginViewModel()
    
    // Obtenemos el ViewModel de autenticación desde el entorno.
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Portal del Profesor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)

            TextField("ID de Profesor o Correo", text: $viewModel.teacherID)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Contraseña", text: $viewModel.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            // El botón de acción llama directamente al método del ViewModel.
            Button(action: {
                viewModel.performLogin(authViewModel: authViewModel)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Iniciar Sesión")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .disabled(viewModel.isLoading)

            Spacer()
            Spacer()
        }
        .padding()
    }
}
