using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TareasApi.DTOs;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QrController : ControllerBase
{
    private readonly IQrService _qrService;
    private readonly ILogger<QrController> _logger;

    public QrController(IQrService qrService, ILogger<QrController> logger)
    {
        _qrService = qrService;
        _logger = logger;
    }

    /// <summary>
    /// Decodifica un código QR y obtiene información del alumno
    /// </summary>
    [HttpPost("decodificar")]
    public async Task<ActionResult<QrResponseDto>> DecodificarQr([FromBody] QrScanDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new QrResponseDto(false, "Datos inválidos"));

            var alumnoInfo = await _qrService.DecodificarQrAlumnoAsync(dto.QrData);
            
            return Ok(new QrResponseDto(
                true,
                "QR decodificado exitosamente",
                alumnoInfo
            ));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Error al decodificar QR");
            return BadRequest(new QrResponseDto(false, ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error interno al decodificar QR");
            return StatusCode(500, new QrResponseDto(false, "Error interno del servidor"));
        }
    }

    /// <summary>
    /// Registra asistencia de un alumno escaneando su código QR
    /// </summary>
    [HttpPost("asistencia")]
    public async Task<ActionResult<QrResponseDto>> RegistrarAsistencia([FromBody] QrAsistenciaDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new QrResponseDto(false, "Datos inválidos", ModelState));

            var profesorId = GetCurrentUserId();
            var asistencia = await _qrService.RegistrarAsistenciaQrAsync(dto, profesorId);
            
            return Ok(new QrResponseDto(
                true,
                "Asistencia registrada exitosamente",
                asistencia
            ));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Error al registrar asistencia con QR");
            return BadRequest(new QrResponseDto(false, ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error interno al registrar asistencia");
            return StatusCode(500, new QrResponseDto(false, "Error interno del servidor"));
        }
    }

    /// <summary>
    /// Califica una entrega escaneando el código QR del alumno
    /// </summary>
    [HttpPost("calificar")]
    public async Task<ActionResult<QrResponseDto>> CalificarConQr([FromBody] QrCalificarDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new QrResponseDto(false, "Datos inválidos", ModelState));

            var profesorId = GetCurrentUserId();
            var entrega = await _qrService.CalificarConQrAsync(dto, profesorId);
            
            return Ok(new QrResponseDto(
                true,
                "Entrega calificada exitosamente",
                entrega
            ));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Error al calificar con QR");
            return BadRequest(new QrResponseDto(false, ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error interno al calificar");
            return StatusCode(500, new QrResponseDto(false, "Error interno del servidor"));
        }
    }

    /// <summary>
    /// Agrega un alumno a un grupo escaneando su código QR
    /// </summary>
    [HttpPost("agregar-grupo")]
    public async Task<ActionResult<QrResponseDto>> AgregarAlumnoGrupo([FromBody] QrAgregarGrupoDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new QrResponseDto(false, "Datos inválidos", ModelState));

            var profesorId = GetCurrentUserId();
            var resultado = await _qrService.AgregarAlumnoGrupoQrAsync(dto, profesorId);
            
            if (resultado)
            {
                return Ok(new QrResponseDto(
                    true,
                    "Alumno agregado al grupo exitosamente"
                ));
            }
            else
            {
                return BadRequest(new QrResponseDto(false, "No se pudo agregar el alumno al grupo"));
            }
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Error al agregar alumno a grupo con QR");
            return BadRequest(new QrResponseDto(false, ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error interno al agregar alumno a grupo");
            return StatusCode(500, new QrResponseDto(false, "Error interno del servidor"));
        }
    }

    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                        ?? User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? throw new InvalidOperationException("User ID claim not found in token.");

        return int.Parse(userIdClaim);
    }
}
