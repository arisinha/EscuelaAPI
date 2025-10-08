using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;

namespace TareasApi.Repositories;

public class GrupoRepository : IGrupoRepository
{
    private readonly ApplicationDbContext _context;

    public GrupoRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Grupo> CreateAsync(Grupo grupo)
    {
        _context.Grupos.Add(grupo);
        await _context.SaveChangesAsync();
        return grupo;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var g = await _context.Grupos.FindAsync(id);
        if (g == null) return false;
        _context.Grupos.Remove(g);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<Grupo>> GetAllAsync()
    {
        return await _context.Grupos.AsNoTracking().ToListAsync();
    }

    public async Task<Grupo?> GetByIdAsync(int id)
    {
        return await _context.Grupos.FindAsync(id);
    }

    public async Task<Grupo?> UpdateAsync(Grupo grupo)
    {
        var exists = await _context.Grupos.FindAsync(grupo.Id);
        if (exists == null) return null;
        exists.NombreMateria = grupo.NombreMateria;
        exists.CodigoGrupo = grupo.CodigoGrupo;
        await _context.SaveChangesAsync();
        return exists;
    }
}
