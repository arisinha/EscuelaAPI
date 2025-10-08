using Microsoft.AspNetCore.Mvc;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class GruposController : ControllerBase
{
    private readonly IGrupoRepository _repo;

    public GruposController(IGrupoRepository repo)
    {
        _repo = repo;
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
