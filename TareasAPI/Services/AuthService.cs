using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TareasApi.Data;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services;

public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _config;
    private readonly ILogger<AuthService>? _logger;

    public AuthService(ApplicationDbContext context, IConfiguration config, ILogger<AuthService>? logger = null)
    {
        _context = context;
        _config = config;
        _logger = logger;
    }

    public async Task<AuthResponse?> AuthenticateAsync(LoginRequest loginRequest)
    {
        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.NombreUsuario == loginRequest.NombreUsuario);

        if (usuario == null)
            return null; // Invalid credentials

        // Protect against malformed or legacy password hashes causing runtime exceptions
        if (string.IsNullOrWhiteSpace(usuario.PasswordHash))
            return null;

        // If the stored value is not a valid BCrypt hash, attempt a migration from plaintext safely.
        if (!IsLikelyBcryptHash(usuario.PasswordHash))
        {
            if (usuario.PasswordHash == loginRequest.Password)
            {
                try
                {
                    var newHash = BCrypt.Net.BCrypt.HashPassword(loginRequest.Password);
                    usuario.PasswordHash = newHash;
                    await _context.SaveChangesAsync();
                    // proceed to token issuance below
                }
                catch (Exception saveEx)
                {
                    _logger?.LogError(saveEx, "Failed to migrate plaintext password for user {User}", loginRequest.NombreUsuario);
                    return null;
                }
            }
            else
            {
                _logger?.LogInformation("User {User} has a non-bcrypt password format that doesn't match input. Rejecting login.", loginRequest.NombreUsuario);
                return null;
            }
        }

        bool verified;
        try
        {
            verified = BCrypt.Net.BCrypt.Verify(loginRequest.Password, usuario.PasswordHash);
        }
        catch (Exception ex)
        {
            // If Verify throws despite hash looking valid, treat as invalid credentials without rethrowing.
            _logger?.LogWarning(ex, "Password verification threw for user {User}", loginRequest.NombreUsuario);
            return null;
        }

        if (!verified)
            return null; // Invalid credentials

        var token = GenerateJwtToken(usuario);
        var usuarioDto = new UsuarioDto(usuario.Id, usuario.NombreUsuario, usuario.NombreCompleto);

        return new AuthResponse(token, usuarioDto);
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest registerRequest)
    {
        // Check if username already exists
        var existingUser = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.NombreUsuario == registerRequest.NombreUsuario);

        if (existingUser != null)
            return null; // Username already taken

        // Create new user with hashed password
        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(registerRequest.Password);

        var nuevoUsuario = new Usuario
        {
            NombreUsuario = registerRequest.NombreUsuario,
            NombreCompleto = registerRequest.NombreCompleto,
            PasswordHash = hashedPassword
        };

        _context.Usuarios.Add(nuevoUsuario);
        await _context.SaveChangesAsync();

        // Generate token for the new user
        var token = GenerateJwtToken(nuevoUsuario);
        var usuarioDto = new UsuarioDto(nuevoUsuario.Id, nuevoUsuario.NombreUsuario, nuevoUsuario.NombreCompleto);

        return new AuthResponse(token, usuarioDto);
    }

    private string GenerateJwtToken(Usuario usuario)
    {
        var issuer = _config["Jwt:Issuer"];
        var audience = _config["Jwt:Audience"];
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Name, usuario.NombreUsuario),
            new Claim("nombre_completo", usuario.NombreCompleto),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var tokenDescriptor = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: DateTime.UtcNow.AddHours(8), // Token valid for 8 hours
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);
    }

    private static bool IsLikelyBcryptHash(string? hash)
    {
        if (string.IsNullOrWhiteSpace(hash)) return false;
        // Typical bcrypt hashes are 60 chars and start with $2a$, $2b$, or $2y$
        if (hash.Length < 55 || hash.Length > 80) return false; // be tolerant but narrow
        return hash.StartsWith("$2a$") || hash.StartsWith("$2b$") || hash.StartsWith("$2y$");
    }
}