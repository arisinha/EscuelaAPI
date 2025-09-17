using System.ComponentModel.DataAnnotations;

namespace TareasApi.DTOs;

public record LoginRequest(
    [Required] string NombreUsuario,
    [Required] string Password
);

public record AuthResponse(
    string Token,
    UsuarioDto Usuario
);