using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Services.Interfaces;

namespace TareasApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    [Authorize]
    public class TareasController : ControllerBase
    {
        private readonly ITareaService _tareaService;

        public TareasController(ITareaService tareaService)
        {
            _tareaService = tareaService;
        }
        
        //get all tareas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<TareaDto>>> GetAllTareas()
        {
            var tareas = await _tareaService.GetAllTareasAsync();
            return Ok(new { success = true, data = tareas, count = tareas.Count() });
        }
        
        //get por ID de tarea
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
        
        //get tarea por estado 
        [HttpGet("estado/{estado}")]
        public async Task<ActionResult<IEnumerable<TareaDto>>> GetTareasByEstado(EstadoTarea estado)
        {
            if (!Enum.IsDefined(typeof(EstadoTarea), estado))
                return BadRequest(new { success = false, message = "Estado de tarea inválido" });

            var tareas = await _tareaService.GetTareasByEstadoAsync(estado);
            return Ok(new { success = true, data = tareas, count = tareas.Count(), estado });
        }
        
        //crear tarea
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
        
        //actualizar tarea 
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

        //eliminar tarea
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