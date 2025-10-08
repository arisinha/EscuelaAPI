using TareasApi.Models;

namespace TareasApi.Repositories.Interfaces;

public interface IGrupoRepository
{
    Task<IEnumerable<Grupo>> GetAllAsync();
    Task<Grupo?> GetByIdAsync(int id);
    Task<Grupo> CreateAsync(Grupo grupo);
    Task<Grupo?> UpdateAsync(Grupo grupo);
    Task<bool> DeleteAsync(int id);
}
