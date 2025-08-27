using System.ComponentModel.DataAnnotations;
using TareasApi.Models;

namespace TareasApi.DTOs
{
    public class TareaDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string? Descripcion { get; set; }
        public EstadoTarea Estado { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaActualizacion { get; set; }
    }

    public class CrearTareaDto
    {
        [Required(ErrorMessage = "El título es obligatorio")]
        [StringLength(200, ErrorMessage = "El título no puede exceder 200 caracteres")]
        public string Titulo { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "La descripción no puede exceder 500 caracteres")]
        public string? Descripcion { get; set; }

        public EstadoTarea Estado { get; set; } = EstadoTarea.Pendiente;
    }

    public class ActualizarTareaDto
    {
        [StringLength(200, ErrorMessage = "El título no puede exceder 200 caracteres")]
        public string? Titulo { get; set; }

        [StringLength(500, ErrorMessage = "La descripción no puede exceder 500 caracteres")]
        public string? Descripcion { get; set; }

        public EstadoTarea? Estado { get; set; }
    }
}