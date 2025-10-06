using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Repositories;

public class TareaRepository : ITareaRepository
{
    private readonly ApplicationDbContext _context;

    public TareaRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Tarea> CreateAsync(Tarea tarea)
    {
        _context.Tareas.Add(tarea);
        await _context.SaveChangesAsync();
        await _context.Entry(tarea).Reference(t => t.Usuario).LoadAsync();
        return tarea;
    }

    public async Task<bool> DeleteAsync(int tareaId)
    {
        var tarea = await _context.Tareas.FindAsync(tareaId);
        if (tarea == null)
        {
            return false;
        }

        _context.Tareas.Remove(tarea);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<Tarea>> GetAllByUserIdAsync(int userId)
    {
        return await _context.Tareas
            .Include(t => t.Usuario)
            .Where(t => t.UsuarioId == userId)
            .OrderByDescending(t => t.FechaCreacion)
            .ToListAsync();
    }

    public async Task<Tarea?> GetByIdAndUserIdAsync(int tareaId, int userId)
    {
        return await _context.Tareas
            .Include(t => t.Usuario) 
            .FirstOrDefaultAsync(t => t.Id == tareaId && t.UsuarioId == userId);
    }

    public async Task<Tarea?> UpdateAsync(Tarea tarea)
    {
        _context.Entry(tarea).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return tarea;
    }
    
    public async Task<Tarea?> FindByIdAsync(int tareaId)
    {
        return await _context.Tareas.FindAsync(tareaId);
    }
}