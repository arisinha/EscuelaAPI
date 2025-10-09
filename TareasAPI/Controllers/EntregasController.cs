using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using TareasApi.DTOs;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class EntregasController : ControllerBase
{
    private readonly IEntregaService _entregaService;

    public EntregasController(IEntregaService entregaService)
    {
        _entregaService = entregaService;
    }

    [HttpPost]
    public async Task<IActionResult> CrearEntrega([FromForm] CrearEntregaDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var alumnoId = GetCurrentUserId();
            var entrega = await _entregaService.CrearEntregaAsync(dto, alumnoId);

            return CreatedAtAction(
                nameof(GetEntrega),
                new { id = entrega.Id },
                new { success = true, message = "Entrega creada exitosamente", data = entrega }
            );
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { success = false, message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = "Error interno del servidor", details = ex.Message });
        }
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<EntregaDto>> GetEntrega(int id)
    {
        var entrega = await _entregaService.GetByIdAsync(id);
        if (entrega == null)
            return NotFound(new { success = false, message = "Entrega no encontrada" });

        return Ok(new { success = true, data = entrega });
    }

    [HttpGet("tarea/{tareaId:int}")]
    public async Task<ActionResult<IEnumerable<EntregaDto>>> GetEntregasPorTarea(int tareaId)
    {
        var entregas = await _entregaService.GetByTareaIdAsync(tareaId);
        return Ok(new { success = true, count = entregas.Count(), data = entregas });
    }

    [HttpGet("mis-entregas")]
    public async Task<ActionResult<IEnumerable<EntregaDto>>> GetMisEntregas()
    {
        var alumnoId = GetCurrentUserId();
        var entregas = await _entregaService.GetByAlumnoIdAsync(alumnoId);
        return Ok(new { success = true, count = entregas.Count(), data = entregas });
    }

    [HttpGet("tarea/{tareaId:int}/mi-entrega")]
    public async Task<ActionResult<EntregaDto>> GetMiEntregaPorTarea(int tareaId)
    {
        var alumnoId = GetCurrentUserId();
        var entrega = await _entregaService.GetByTareaIdAndAlumnoIdAsync(tareaId, alumnoId);
        
        if (entrega == null)
            return NotFound(new { success = false, message = "No tienes entrega para esta tarea" });

        return Ok(new { success = true, data = entrega });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarEntrega(int id)
    {
        var alumnoId = GetCurrentUserId();
        var eliminado = await _entregaService.DeleteAsync(id, alumnoId);
        
        if (!eliminado)
            return NotFound(new { success = false, message = "Entrega no encontrada o no tienes permisos para eliminarla" });

        return Ok(new { success = true, message = "Entrega eliminada exitosamente" });
    }

    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                        ?? User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier)
                        ?? throw new InvalidOperationException("User ID claim not found in token.");

        return int.Parse(userIdClaim);
    }
}