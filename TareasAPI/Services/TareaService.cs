using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services;

public class TareaService : ITareaService
{
    private readonly ITareaRepository _tareaRepository;

    public TareaService(ITareaRepository tareaRepository)
    {
        _tareaRepository = tareaRepository;
    }

    public async Task<TareaDto> CreateForUserAsync(CrearTareaDto crearTareaDto, int userId)
    {
        var tarea = new Tarea
        {
            Titulo = crearTareaDto.Titulo,
            Descripcion = crearTareaDto.Descripcion,
            UsuarioId = userId,
            Estado = EstadoTarea.Pendiente,
            FechaCreacion = DateTime.UtcNow,
            Usuario = null! 
        };

        var nuevaTarea = await _tareaRepository.CreateAsync(tarea);
        return MapTareaToDto(nuevaTarea);
    }

    public async Task<bool> DeleteForUserAsync(int tareaId, int userId)
    {
        var tarea = await _tareaRepository.GetByIdAndUserIdAsync(tareaId, userId);
        if (tarea == null)
        {
            return false; 
        }

        return await _tareaRepository.DeleteAsync(tareaId);
    }

    public async Task<IEnumerable<TareaDto>> GetAllByUserIdAsync(int userId)
    {
        var tareas = await _tareaRepository.GetAllByUserIdAsync(userId);
        return tareas.Select(MapTareaToDto);
    }

    public async Task<TareaDto?> GetByIdAndUserIdAsync(int tareaId, int userId)
    {
        var tarea = await _tareaRepository.GetByIdAndUserIdAsync(tareaId, userId);
        return tarea == null ? null : MapTareaToDto(tarea);
    }

    public async Task<TareaDto?> UpdateForUserAsync(int tareaId, ActualizarTareaDto dto, int userId)
    {
        var tarea = await _tareaRepository.GetByIdAndUserIdAsync(tareaId, userId);
        if (tarea == null)
        {
            return null; 
        }

        if (!string.IsNullOrEmpty(dto.Titulo))
            tarea.Titulo = dto.Titulo;
        if (dto.Descripcion != null)
            tarea.Descripcion = dto.Descripcion;
        if (dto.Estado.HasValue)
            tarea.Estado = dto.Estado.Value;

        tarea.FechaActualizacion = DateTime.UtcNow;

        var tareaActualizada = await _tareaRepository.UpdateAsync(tarea);
        return tareaActualizada == null ? null : MapTareaToDto(tareaActualizada);
    }

    public IEnumerable<object> GetEstados()
    {
        return Enum.GetValues<EstadoTarea>()
            .Select(e => new { id = (int)e, nombre = e.ToString() })
            .ToList();
    }

    private static TareaDto MapTareaToDto(Tarea tarea)
    {
        var usuarioDto = new UsuarioDto(
            tarea.Usuario.Id,
            tarea.Usuario.NombreUsuario,
            tarea.Usuario.NombreCompleto
        );

        return new TareaDto(
            tarea.Id,
            tarea.Titulo,
            tarea.Descripcion,
            tarea.Estado.ToString(),
            tarea.FechaCreacion,
            tarea.FechaActualizacion,
            usuarioDto
        );
    }
}