using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Repositories;

public class EntregaRepository : IEntregaRepository
{
    private readonly ApplicationDbContext _context;

    public EntregaRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Entrega> CreateAsync(Entrega entrega)
    {
        _context.Entregas.Add(entrega);
        await _context.SaveChangesAsync();
        return await GetByIdAsync(entrega.Id) ?? entrega;
    }

    public async Task<Entrega?> GetByIdAsync(int id)
    {
        return await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Tarea)
            .FirstOrDefaultAsync(e => e.Id == id);
    }

    public async Task<IEnumerable<Entrega>> GetByTareaIdAsync(int tareaId)
    {
        return await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Tarea)
            .Where(e => e.TareaId == tareaId)
            .OrderByDescending(e => e.FechaEntrega)
            .ToListAsync();
    }

    public async Task<IEnumerable<Entrega>> GetByAlumnoIdAsync(int alumnoId)
    {
        return await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Tarea)
            .Where(e => e.AlumnoId == alumnoId)
            .OrderByDescending(e => e.FechaEntrega)
            .ToListAsync();
    }

    public async Task<Entrega?> GetByTareaIdAndAlumnoIdAsync(int tareaId, int alumnoId)
    {
        return await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Tarea)
            .FirstOrDefaultAsync(e => e.TareaId == tareaId && e.AlumnoId == alumnoId);
    }

    public async Task<IEnumerable<Entrega>> GetAllAsync()
    {
        return await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Tarea)
            .OrderByDescending(e => e.FechaEntrega)
            .ToListAsync();
    }

    public async Task<Entrega?> UpdateAsync(Entrega entrega)
    {
        _context.Entregas.Update(entrega);
        await _context.SaveChangesAsync();
        return await GetByIdAsync(entrega.Id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var entrega = await _context.Entregas.FindAsync(id);
        if (entrega == null) return false;

        _context.Entregas.Remove(entrega);
        await _context.SaveChangesAsync();
        return true;
    }
}