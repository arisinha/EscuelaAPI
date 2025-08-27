using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Repositories
{
    public class TareaRepository : ITareaRepository
    {
        private readonly TareasDbContext _context;

        public TareaRepository(TareasDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Tarea>> GetAllAsync()
        {
            return await _context.Tareas
                .OrderByDescending(t => t.FechaCreacion)
                .ToListAsync();
        }

        public async Task<Tarea?> GetByIdAsync(int id)
        {
            return await _context.Tareas.FindAsync(id);
        }

        public async Task<IEnumerable<Tarea>> GetByEstadoAsync(EstadoTarea estado)
        {
            return await _context.Tareas
                .Where(t => t.Estado == estado)
                .OrderByDescending(t => t.FechaCreacion)
                .ToListAsync();
        }

        public async Task<Tarea> CreateAsync(Tarea tarea)
        {
            tarea.FechaCreacion = DateTime.UtcNow;
            _context.Tareas.Add(tarea);
            await _context.SaveChangesAsync();
            return tarea;
        }

        public async Task<Tarea?> UpdateAsync(int id, Tarea tarea)
        {
            var existingTarea = await _context.Tareas.FindAsync(id);
            if (existingTarea == null)
                return null;

            existingTarea.Titulo = tarea.Titulo;
            existingTarea.Descripcion = tarea.Descripcion;
            existingTarea.Estado = tarea.Estado;
            existingTarea.FechaActualizacion = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return existingTarea;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var tarea = await _context.Tareas.FindAsync(id);
            if (tarea == null)
                return false;

            _context.Tareas.Remove(tarea);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await _context.Tareas.AnyAsync(t => t.Id == id);
        }
    }
}