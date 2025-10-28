using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Repositories;

public class AsistenciaRepository : IAsistenciaRepository
{
    private readonly ApplicationDbContext _db;

    public AsistenciaRepository(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<Asistencia> CreateAsync(Asistencia asistencia)
    {
        var entry = await _db.Asistencias.AddAsync(asistencia);
        await _db.SaveChangesAsync();
        return entry.Entity;
    }

    public async Task<Asistencia?> GetByIdAsync(int id)
    {
        return await _db.Asistencias.Include(a => a.Usuario).Include(a => a.Grupo).FirstOrDefaultAsync(a => a.Id == id);
    }

    public async Task<IEnumerable<Asistencia>> GetByGrupoAndFechaAsync(int grupoId, DateTime fecha)
    {
        // compare by date only (UTC)
        var dateOnly = fecha.Date;
        return await _db.Asistencias
            .Include(a => a.Usuario)
            .Where(a => a.GrupoId == grupoId && a.Fecha.Date == dateOnly)
            .ToListAsync();
    }

    public async Task<IEnumerable<Asistencia>> GetByUsuarioAsync(int usuarioId)
    {
        return await _db.Asistencias
            .Include(a => a.Grupo)
            .Where(a => a.UsuarioId == usuarioId)
            .OrderByDescending(a => a.Fecha)
            .ToListAsync();
    }
}
