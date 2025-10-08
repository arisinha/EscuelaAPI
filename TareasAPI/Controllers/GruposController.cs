using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class GruposController : ControllerBase
{
    private readonly IGrupoRepository _repo;
    private readonly TareasApi.Services.Interfaces.ITareaService _tareaService;

    public GruposController(IGrupoRepository repo, TareasApi.Services.Interfaces.ITareaService tareaService)
    {
        _repo = repo;
        _tareaService = tareaService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<GrupoDto>>> Get()
    {
        var grupos = (await _repo.GetAllAsync()).Select(g => new GrupoDto(g.Id, g.NombreMateria, g.CodigoGrupo));
        return Ok(grupos);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<GrupoDto>> GetById(int id)
    {
        var g = await _repo.GetByIdAsync(id);
        if (g == null) return NotFound();
        return Ok(new GrupoDto(g.Id, g.NombreMateria, g.CodigoGrupo));
    }

    // GET /api/Grupos/{id}/tareas - requiere autenticación
    [HttpGet("{id:int}/tareas")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> GetTareasPorGrupo(int id)
    {
        // Ensure group exists
        var grupo = await _repo.GetByIdAsync(id);
        if (grupo == null) return NotFound(new { success = false, message = "Grupo no encontrado" });

        // Extract user id from claims (like in TareasController)
        var userIdClaim = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)
                         ?? User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userIdClaim == null) return Unauthorized();
        var userId = int.Parse(userIdClaim);

        var tareas = await _tareaService.GetAllByUserIdAsync(userId, id);
        return Ok(new { success = true, count = tareas.Count(), data = tareas });
    }

    [HttpPost]
    public async Task<ActionResult<GrupoDto>> Create(GrupoDto dto)
    {
        var g = new Grupo { NombreMateria = dto.NombreMateria, CodigoGrupo = dto.CodigoGrupo };
        var created = await _repo.CreateAsync(g);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new GrupoDto(created.Id, created.NombreMateria, created.CodigoGrupo));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<GrupoDto>> Update(int id, GrupoDto dto)
    {
        if (id != dto.Id) return BadRequest();
        var grupo = new Grupo { Id = dto.Id, NombreMateria = dto.NombreMateria, CodigoGrupo = dto.CodigoGrupo };
        var updated = await _repo.UpdateAsync(grupo);
        if (updated == null) return NotFound();
        return Ok(new GrupoDto(updated.Id, updated.NombreMateria, updated.CodigoGrupo));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _repo.DeleteAsync(id);
        if (!ok) return NotFound();
        return NoContent();
    }
}
