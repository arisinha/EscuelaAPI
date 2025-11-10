using System.ComponentModel.DataAnnotations;

namespace TareasApi.Models;

public class Grupo
{
    [Key]
    public int Id { get; set; }

    public string NombreMateria { get; set; } = string.Empty;

    public string CodigoGrupo { get; set; } = string.Empty;

    // Relación muchos a muchos con Usuario (miembros del grupo)
    public virtual ICollection<Usuario> Miembros { get; set; } = new List<Usuario>();
}
