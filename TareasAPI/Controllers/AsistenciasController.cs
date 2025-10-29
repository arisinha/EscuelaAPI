using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AsistenciasController : ControllerBase
{
    private readonly IAsistenciaService _service;

    public AsistenciasController(IAsistenciaService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<ActionResult<AsistenciaDto>> Create([FromBody] CreateAsistenciaDto dto)
    {
        if (dto == null) return BadRequest();

        var asistencia = new Asistencia
        {
            UsuarioId = dto.UsuarioId,
            GrupoId = dto.GrupoId,
            Fecha = dto.Fecha.ToUniversalTime(),
            Estado = (EstadoAsistencia)dto.Estado,
            Observaciones = dto.Observaciones
        };

        var created = await _service.CreateAsync(asistencia);
        var result = new AsistenciaDto(created.Id, created.UsuarioId, created.GrupoId, created.Fecha, created.Estado, created.Observaciones);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<AsistenciaDto>> GetById(int id)
    {
        var a = await _service.GetByIdAsync(id);
        if (a == null) return NotFound();
        return Ok(new AsistenciaDto(a.Id, a.UsuarioId, a.GrupoId, a.Fecha, a.Estado, a.Observaciones));
    }

    // GET /api/Asistencias/grupo/{grupoId}?fecha=2025-10-28
    [HttpGet("grupo/{grupoId:int}")]
    public async Task<ActionResult<IEnumerable<AsistenciaDto>>> GetByGrupo(int grupoId, [FromQuery] DateTime? fecha)
    {
        var date = fecha?.ToUniversalTime() ?? DateTime.UtcNow.Date;
        var list = await _service.GetByGrupoAndFechaAsync(grupoId, date);
        var dtos = list.Select(a => new AsistenciaDto(a.Id, a.UsuarioId, a.GrupoId, a.Fecha, a.Estado, a.Observaciones));
        return Ok(dtos);
    }

    [HttpGet("usuario/{usuarioId:int}")]
    public async Task<ActionResult<IEnumerable<AsistenciaDto>>> GetByUsuario(int usuarioId)
    {
        var list = await _service.GetByUsuarioAsync(usuarioId);
        var dtos = list.Select(a => new AsistenciaDto(a.Id, a.UsuarioId, a.GrupoId, a.Fecha, a.Estado, a.Observaciones));
        return Ok(dtos);
    }
}
