using System.ComponentModel.DataAnnotations;

namespace TareasApi.Models;

public class Usuario
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(50)]
    public required string NombreUsuario { get; set; }

    [Required]
    [StringLength(255)]
    public required string PasswordHash { get; set; }

    [Required]
    [StringLength(150)]
    public required string NombreCompleto { get; set; }

    public virtual ICollection<Tarea> Tareas { get; set; } = new List<Tarea>();

    [Required]
    [StringLength(20)]
    public required string Rol { get; set; }

    // Materias en las que el usuario está inscrito (como alumno)
    public virtual ICollection<UsuarioMateria> MateriasInscritas { get; set; } = new List<UsuarioMateria>();

    // Materias que el usuario imparte (como maestro)
    [System.ComponentModel.DataAnnotations.Schema.InverseProperty("Maestro")]
    public virtual ICollection<Materia> MateriasImpartidas { get; set; } = new List<Materia>();
}