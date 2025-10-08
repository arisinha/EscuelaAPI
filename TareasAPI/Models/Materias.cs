using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using TareasApi.Models;

namespace TareasApi.Models
{
    public class Materia
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Nombre { get; set; }

        [MaxLength(200)]
        public string Descripcion { get; set; }

        public int MaestroId { get; set; }
        public virtual Usuario Maestro { get; set; }

        public virtual ICollection<UsuarioMateria> AlumnosInscritos { get; set; } = new List<UsuarioMateria>();
    }
}