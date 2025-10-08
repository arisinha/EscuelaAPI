using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TareasApi.DTOs;
using TareasApi.Services.Interfaces;
using System.IdentityModel.Tokens.Jwt;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] 

public class TareasController : ControllerBase
{
    private readonly ITareaService _tareaService;
    private readonly TareasApi.Repositories.Interfaces.IGrupoRepository _grupoRepository;

    public TareasController(ITareaService tareaService, TareasApi.Repositories.Interfaces.IGrupoRepository grupoRepository)
    {
        _tareaService = tareaService;
        _grupoRepository = grupoRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TareaDto>>> GetTareas([FromQuery] int? grupoId)
    {
        var userId = GetCurrentUserId();
        var tareas = await _tareaService.GetAllByUserIdAsync(userId, grupoId);
        return Ok(new { success = true, count = tareas.Count(), data = tareas });
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TareaDto>> GetTarea(int id)
    {
        var userId = GetCurrentUserId();
        var tarea = await _tareaService.GetByIdAndUserIdAsync(id, userId);
        if (tarea == null)
        {
            return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });
        }
        return Ok(new { success = true, data = tarea });
    }

    [HttpPost]
    public async Task<ActionResult<TareaDto>> CreateTarea(CrearTareaDto crearTareaDto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, errors = ModelState });
        }

        var userId = GetCurrentUserId();
        var nuevaTarea = await _tareaService.CreateForUserAsync(crearTareaDto, userId);

        return CreatedAtAction(
            nameof(GetTarea),
            new { id = nuevaTarea.Id },
            new { success = true, message = "Tarea creada exitosamente", data = nuevaTarea }
        );
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateTarea(int id, ActualizarTareaDto actualizarTareaDto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, errors = ModelState });
        }
        
        var userId = GetCurrentUserId();
        var tareaActualizada = await _tareaService.UpdateForUserAsync(id, actualizarTareaDto, userId);
        if (tareaActualizada == null)
        {
            return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });
        }
        return Ok(new { success = true, message = "Tarea actualizada exitosamente", data = tareaActualizada });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteTarea(int id)
    {
        var userId = GetCurrentUserId();
        var deleted = await _tareaService.DeleteForUserAsync(id, userId);
        if (!deleted)
        {
            return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });
        }
        return Ok(new { success = true, message = "Tarea eliminada exitosamente" });
    }

    // PATCH: /api/Tareas/{id}/grupo
    [HttpPatch("{id:int}/grupo")]
    public async Task<IActionResult> AssignGrupo(int id, [FromBody] int? grupoId)
    {
        var userId = GetCurrentUserId();
        var tarea = await _tareaService.GetByIdAndUserIdAsync(id, userId);
        if (tarea == null) return NotFound(new { success = false, message = "Tarea no encontrada" });

        // If grupoId provided, ensure it exists
        if (grupoId.HasValue)
        {
            var g = await _grupoRepository.GetByIdAsync(grupoId.Value);
            if (g == null) return BadRequest(new { success = false, message = "Grupo no existe" });
        }

        // Build update DTO with only grupoId
        var updateDto = new ActualizarTareaDto(null, null, null, grupoId);
        var updated = await _tareaService.UpdateForUserAsync(id, updateDto, userId);
        if (updated == null) return StatusCode(500, new { success = false, message = "No se pudo actualizar la tarea" });
        return Ok(new { success = true, data = updated });
    }
    
    [HttpGet("estados")]
    [AllowAnonymous]
    public ActionResult<object> GetEstados()
    {
        var estados = _tareaService.GetEstados();
        return Ok(new { success = true, data = estados });
    }
    
    private int GetCurrentUserId()
    {
        // Accept either the JWT 'sub' claim or the standard NameIdentifier claim which may be mapped by the
        // token handler depending on inbound claim mapping settings.
        var userIdClaim = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                        ?? User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier)
                        ?? throw new InvalidOperationException("User ID claim (sub or nameidentifier) not found in token.");

        return int.Parse(userIdClaim);
    }   
}