using TareasApi.Models;

namespace TareasApi.Repositories.Interfaces
{
    public interface ITareaRepository
    {
        Task<IEnumerable<Tarea>> GetAllAsync();
        Task<Tarea?> GetByIdAsync(int id);
        Task<IEnumerable<Tarea>> GetByEstadoAsync(EstadoTarea estado);
        Task<Tarea> CreateAsync(Tarea tarea);
        Task<Tarea?> UpdateAsync(int id, Tarea tarea);
        Task<bool> DeleteAsync(int id);
        Task<bool> ExistsAsync(int id);
    }
}