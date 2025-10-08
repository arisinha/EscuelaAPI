using System.ComponentModel.DataAnnotations.Schema;
using TareasApi.Models;

namespace TareasApi.Models
{
    public class UsuarioMateria
    {
        public int UsuarioId { get; set; }
        public virtual Usuario Usuario { get; set; }

        public int MateriaId { get; set; }
        public virtual Materia Materia { get; set; }
    }
}
