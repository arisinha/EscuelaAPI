using TareasApi.DTOs;

namespace TareasApi.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponse?> AuthenticateAsync(LoginRequest loginRequest);
    Task<AuthResponse?> RegisterAsync(RegisterRequest registerRequest);
}