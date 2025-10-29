using System.ComponentModel.DataAnnotations;

namespace TareasApi.DTOs;

public record LoginRequest(
    [Required] string NombreUsuario,
    [Required] string Password
);

public record RegisterRequest(
    [Required] string NombreUsuario,
    [Required] string Password,
    [Required] string NombreCompleto
);

public record AuthResponse(
    string Token,
    UsuarioDto Usuario
);