using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TareasApi.Models;
using TareasApi.Data;
using Microsoft.EntityFrameworkCore;

namespace TareasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsuarioMateriasController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    public UsuarioMateriasController(ApplicationDbContext context)
    {
        _context = context;
    }

    // Inscribir alumno en materia
    [HttpPost]
    public async Task<IActionResult> InscribirAlumno([FromBody] UsuarioMateria usuarioMateria)
    {
        var existe = await _context.UsuarioMaterias.AnyAsync(um => um.UsuarioId == usuarioMateria.UsuarioId && um.MateriaId == usuarioMateria.MateriaId);
        if (existe)
            return BadRequest(new { success = false, message = "El alumno ya está inscrito en la materia." });
        _context.UsuarioMaterias.Add(usuarioMateria);
        await _context.SaveChangesAsync();
        return Ok(new { success = true, message = "Alumno inscrito correctamente." });
    }

    // Eliminar inscripción de alumno en materia
    [HttpDelete]
    public async Task<IActionResult> EliminarInscripcion([FromBody] UsuarioMateria usuarioMateria)
    {
        var inscripcion = await _context.UsuarioMaterias.FirstOrDefaultAsync(um => um.UsuarioId == usuarioMateria.UsuarioId && um.MateriaId == usuarioMateria.MateriaId);
        if (inscripcion == null)
            return NotFound(new { success = false, message = "La inscripción no existe." });
        _context.UsuarioMaterias.Remove(inscripcion);
        await _context.SaveChangesAsync();
        return Ok(new { success = true, message = "Inscripción eliminada correctamente." });
    }
}
