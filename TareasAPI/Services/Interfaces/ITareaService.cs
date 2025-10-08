using TareasApi.DTOs;

namespace TareasApi.Services.Interfaces;

public interface ITareaService
{
    Task<IEnumerable<TareaDto>> GetAllByUserIdAsync(int userId, int? grupoId = null);
    Task<TareaDto?> GetByIdAndUserIdAsync(int tareaId, int userId);
    Task<TareaDto> CreateForUserAsync(CrearTareaDto crearTareaDto, int userId);
    Task<TareaDto?> UpdateForUserAsync(int tareaId, ActualizarTareaDto actualizarTareaDto, int userId);
    Task<bool> DeleteForUserAsync(int tareaId, int userId);
    IEnumerable<object> GetEstados();
}