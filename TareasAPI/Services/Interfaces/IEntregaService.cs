using TareasApi.DTOs;

namespace TareasApi.Services.Interfaces;

public interface IEntregaService
{
    Task<EntregaResponseDto> CrearEntregaAsync(CrearEntregaDto dto, int alumnoId);
    Task<EntregaDto?> GetByIdAsync(int id);
    Task<IEnumerable<EntregaDto>> GetByTareaIdAsync(int tareaId);
    Task<IEnumerable<EntregaDto>> GetByAlumnoIdAsync(int alumnoId);
    Task<EntregaDto?> GetByTareaIdAndAlumnoIdAsync(int tareaId, int alumnoId);
    Task<bool> DeleteAsync(int id, int alumnoId);
}