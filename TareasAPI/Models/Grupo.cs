using System.ComponentModel.DataAnnotations;

namespace TareasApi.Models;

public class Grupo
{
    [Key]
    public int Id { get; set; }

    public string NombreMateria { get; set; } = string.Empty;

    public string CodigoGrupo { get; set; } = string.Empty;
}
