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
}