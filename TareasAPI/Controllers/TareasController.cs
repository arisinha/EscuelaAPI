using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class TareasController : ControllerBase
    {
        private readonly ITareaService _tareaService;

        public TareasController(ITareaService tareaService)
        {
            _tareaService = tareaService;
        }

        /// <summary>
        /// Obtiene todas las tareas
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<TareaDto>>> GetAllTareas()
        {
            var tareas = await _tareaService.GetAllTareasAsync();
            return Ok(new { success = true, data = tareas, count = tareas.Count() });
        }

        /// <summary>
        /// Obtiene una tarea por su ID
        /// </summary>
        [HttpGet("{id:int}")]
        public async Task<ActionResult<TareaDto>> GetTareaById(int id)
        {
            if (id <= 0)
                return BadRequest(new { success = false, message = "El ID debe ser mayor a 0" });

            var tarea = await _tareaService.GetTareaByIdAsync(id);
            
            if (tarea == null)
                return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });

            return Ok(new { success = true, data = tarea });
        }

        /// <summary>
        /// Obtiene tareas filtradas por estado
        /// </summary>
        [HttpGet("estado/{estado}")]
        public async Task<ActionResult<IEnumerable<TareaDto>>> GetTareasByEstado(EstadoTarea estado)
        {
            if (!Enum.IsDefined(typeof(EstadoTarea), estado))
                return BadRequest(new { success = false, message = "Estado de tarea inválido" });

            var tareas = await _tareaService.GetTareasByEstadoAsync(estado);
            return Ok(new { success = true, data = tareas, count = tareas.Count(), estado });
        }

        /// <summary>
        /// Crea una nueva tarea
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<TareaDto>> CreateTarea([FromBody] CrearTareaDto crearTareaDto)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage);
                return BadRequest(new { success = false, message = "Datos inválidos", errors });
            }

            var tarea = await _tareaService.CreateTareaAsync(crearTareaDto);
            return CreatedAtAction(
                nameof(GetTareaById),
                new { id = tarea.Id },
                new { success = true, data = tarea, message = "Tarea creada exitosamente" }
            );
        }

        /// <summary>
        /// Actualiza una tarea existente
        /// </summary>
        [HttpPut("{id:int}")]
        public async Task<ActionResult<TareaDto>> UpdateTarea(int id, [FromBody] ActualizarTareaDto actualizarTareaDto)
        {
            if (id <= 0)
                return BadRequest(new { success = false, message = "El ID debe ser mayor a 0" });

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage);
                return BadRequest(new { success = false, message = "Datos inválidos", errors });
            }

            var tarea = await _tareaService.UpdateTareaAsync(id, actualizarTareaDto);
            
            if (tarea == null)
                return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });

            return Ok(new { success = true, data = tarea, message = "Tarea actualizada exitosamente" });
        }

        /// <summary>
        /// Elimina una tarea
        /// </summary>
        [HttpDelete("{id:int}")]
        public async Task<ActionResult> DeleteTarea(int id)
        {
            if (id <= 0)
                return BadRequest(new { success = false, message = "El ID debe ser mayor a 0" });

            var deleted = await _tareaService.DeleteTareaAsync(id);
            
            if (!deleted)
                return NotFound(new { success = false, message = $"No se encontró la tarea con ID {id}" });

            return Ok(new { success = true, message = "Tarea eliminada exitosamente" });
        }
    }
}