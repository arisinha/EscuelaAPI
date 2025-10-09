using TareasApi.Models;

namespace TareasApi.Repositories.Interfaces;

public interface IEntregaRepository
{
    Task<Entrega> CreateAsync(Entrega entrega);
    Task<Entrega?> GetByIdAsync(int id);
    Task<IEnumerable<Entrega>> GetByTareaIdAsync(int tareaId);
    Task<IEnumerable<Entrega>> GetByAlumnoIdAsync(int alumnoId);
    Task<Entrega?> GetByTareaIdAndAlumnoIdAsync(int tareaId, int alumnoId);
    Task<IEnumerable<Entrega>> GetAllAsync();
    Task<Entrega?> UpdateAsync(Entrega entrega);
    Task<bool> DeleteAsync(int id);
}