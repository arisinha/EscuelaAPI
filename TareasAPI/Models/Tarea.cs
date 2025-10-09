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
    public EstadoTarea Estado { get; set; } = EstadoTarea.Abierto;

    public DateTimeOffset FechaCreacion { get; set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset? FechaActualizacion { get; set; }

    // Optional association to Grupo
    public int? GrupoId { get; set; }

    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    [ForeignKey("UsuarioId")]
    public virtual required Usuario Usuario { get; set; }
}

public enum EstadoTarea
{
    Abierto = 0,
    Cerrado = 1
}