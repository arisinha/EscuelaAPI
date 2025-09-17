using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TareasApi.Models;

public class Tarea
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(200)]
    public string Titulo { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Descripcion { get; set; }

    [Required]
    public EstadoTarea Estado { get; set; } = EstadoTarea.Pendiente;

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public DateTime? FechaActualizacion { get; set; }

    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    [ForeignKey("UsuarioId")]
    public virtual required Usuario Usuario { get; set; }
}

public enum EstadoTarea
{
    Pendiente = 0,
    EnProgreso = 1,
    Completada = 2,
    Cancelada = 3
}