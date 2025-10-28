using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TareasApi.Models;

public enum EstadoAsistencia
{
    Presente = 1,
    Ausente = 2,
    Justificado = 3
}

public class Asistencia
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UsuarioId { get; set; }

    [Required]
    public int GrupoId { get; set; }

    // Fecha de la clase (solo fecha + hora opcional). Se guarda en UTC en la BD.
    [Required]
    public DateTime Fecha { get; set; }

    [Required]
    public EstadoAsistencia Estado { get; set; } = EstadoAsistencia.Presente;

    [StringLength(500)]
    public string? Observaciones { get; set; }

    // Navegación
    public virtual Usuario? Usuario { get; set; }
    public virtual Grupo? Grupo { get; set; }
}
