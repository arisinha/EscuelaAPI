using TareasApi.DTOs;
using TareasApi.Models;

namespace TareasApi.Services.Interfaces
{
    public interface ITareaService
    {
        Task<IEnumerable<TareaDto>> GetAllTareasAsync();
        Task<TareaDto?> GetTareaByIdAsync(int id);
        Task<IEnumerable<TareaDto>> GetTareasByEstadoAsync(EstadoTarea estado);
        Task<TareaDto> CreateTareaAsync(CrearTareaDto crearTareaDto);
        Task<TareaDto?> UpdateTareaAsync(int id, ActualizarTareaDto actualizarTareaDto);
        Task<bool> DeleteTareaAsync(int id);
    }
}