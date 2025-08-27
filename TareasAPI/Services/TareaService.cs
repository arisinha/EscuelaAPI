using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services
{
    public class TareaService : ITareaService
    {
        private readonly ITareaRepository _tareaRepository;

        public TareaService(ITareaRepository tareaRepository)
        {
            _tareaRepository = tareaRepository;
        }

        public async Task<IEnumerable<TareaDto>> GetAllTareasAsync()
        {
            var tareas = await _tareaRepository.GetAllAsync();
            return tareas.Select(MapToDto);
        }

        public async Task<TareaDto?> GetTareaByIdAsync(int id)
        {
            var tarea = await _tareaRepository.GetByIdAsync(id);
            return tarea != null ? MapToDto(tarea) : null;
        }

        public async Task<IEnumerable<TareaDto>> GetTareasByEstadoAsync(EstadoTarea estado)
        {
            var tareas = await _tareaRepository.GetByEstadoAsync(estado);
            return tareas.Select(MapToDto);
        }

        public async Task<TareaDto> CreateTareaAsync(CrearTareaDto crearTareaDto)
        {
            var tarea = new Tarea
            {
                Titulo = crearTareaDto.Titulo,
                Descripcion = crearTareaDto.Descripcion,
                Estado = crearTareaDto.Estado
            };

            var createdTarea = await _tareaRepository.CreateAsync(tarea);
            return MapToDto(createdTarea);
        }

        public async Task<TareaDto?> UpdateTareaAsync(int id, ActualizarTareaDto actualizarTareaDto)
        {
            var existingTarea = await _tareaRepository.GetByIdAsync(id);
            if (existingTarea == null)
                return null;

            // Solo actualizar campos que no sean null
            if (!string.IsNullOrEmpty(actualizarTareaDto.Titulo))
                existingTarea.Titulo = actualizarTareaDto.Titulo;
            
            if (actualizarTareaDto.Descripcion != null)
                existingTarea.Descripcion = actualizarTareaDto.Descripcion;
            
            if (actualizarTareaDto.Estado.HasValue)
                existingTarea.Estado = actualizarTareaDto.Estado.Value;

            var updatedTarea = await _tareaRepository.UpdateAsync(id, existingTarea);
            return updatedTarea != null ? MapToDto(updatedTarea) : null;
        }

        public async Task<bool> DeleteTareaAsync(int id)
        {
            return await _tareaRepository.DeleteAsync(id);
        }

        private static TareaDto MapToDto(Tarea tarea)
        {
            return new TareaDto
            {
                Id = tarea.Id,
                Titulo = tarea.Titulo,
                Descripcion = tarea.Descripcion,
                Estado = tarea.Estado,
                FechaCreacion = tarea.FechaCreacion,
                FechaActualizacion = tarea.FechaActualizacion
            };
        }
    }
}