using Microsoft.AspNetCore.Mvc;
using TareasApi.DTOs;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest loginRequest)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var authResponse = await _authService.AuthenticateAsync(loginRequest);

        if (authResponse == null)
        {
            return Unauthorized("Credenciales inválidas.");
        }

        return Ok(authResponse);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest registerRequest)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var authResponse = await _authService.RegisterAsync(registerRequest);

        if (authResponse == null)
        {
            return BadRequest("El nombre de usuario ya existe.");
        }

        return Ok(authResponse);
    }
}