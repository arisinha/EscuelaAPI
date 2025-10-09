using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TareasApi.Models;

public class Entrega
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int TareaId { get; set; }

    [Required]
    public int AlumnoId { get; set; }

    [StringLength(500)]
    public string? Comentario { get; set; }

    [Required]
    [StringLength(255)]
    public string NombreArchivo { get; set; } = string.Empty;

    [Required]
    [StringLength(500)]
    public string RutaArchivo { get; set; } = string.Empty;

    [StringLength(50)]
    public string TipoArchivo { get; set; } = string.Empty;

    public long TamanoArchivo { get; set; }

    public DateTimeOffset FechaEntrega { get; set; } = DateTimeOffset.UtcNow;

    // Navigation properties
    [ForeignKey("TareaId")]
    public virtual required Tarea Tarea { get; set; }

    [ForeignKey("AlumnoId")]
    public virtual required Usuario Alumno { get; set; }
}