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

        Task {
            defer { isLoading = false }
            await authViewModel.login(nombreUsuario: teacherID, contrasena: password)
        }
    }
}

struct LoginView: View {
    // Creamos una instancia del ViewModel específica para esta vista.
    @StateObject private var viewModel = LoginViewModel()
    
    // Obtenemos el ViewModel de autenticación desde el entorno.
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showError = false

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
                .textInputAutocapitalization(.never)

            SecureField("Contraseña", text: $viewModel.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onSubmit {
                    viewModel.performLogin(authViewModel: authViewModel)
                }

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
            .disabled(viewModel.isLoading || viewModel.teacherID.isEmpty || viewModel.password.isEmpty)

            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding()
        .onChange(of: authViewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error al iniciar sesión", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.error ?? "Intenta nuevamente.")
        }
    }
}

