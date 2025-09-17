using TareasApi.Models;

namespace TareasApi.Repositories.Interfaces;

public interface ITareaRepository
{
    Task<IEnumerable<Tarea>> GetAllByUserIdAsync(int userId);
    Task<Tarea?> GetByIdAndUserIdAsync(int tareaId, int userId);
    Task<Tarea> CreateAsync(Tarea tarea);
    Task<Tarea?> UpdateAsync(Tarea tarea);
    Task<bool> DeleteAsync(int tareaId);
    Task<Tarea?> FindByIdAsync(int tareaId);
}