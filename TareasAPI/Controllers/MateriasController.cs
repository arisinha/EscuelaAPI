
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TareasApi.Models;
using TareasApi.Data;
using Microsoft.EntityFrameworkCore;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MateriasController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    public MateriasController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("maestro/{maestroId}")]
    public async Task<ActionResult<IEnumerable<Materia>>> GetMateriasPorMaestro(int maestroId)
    {
        var materias = await _context.Materias.Where(m => m.MaestroId == maestroId).ToListAsync();
        return Ok(materias);
    }

    [HttpGet("alumno/{alumnoId}")]
    public async Task<ActionResult<IEnumerable<Materia>>> GetMateriasPorAlumno(int alumnoId)
    {
        var materias = await _context.UsuarioMaterias
            .Where(um => um.UsuarioId == alumnoId)
            .Include(um => um.Materia)
            .Select(um => um.Materia)
            .ToListAsync();
        return Ok(materias);
    }
}
