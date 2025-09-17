using System.ComponentModel.DataAnnotations;
using TareasApi.Models;

namespace TareasApi.DTOs;

// The main DTO for returning a task (Corrected)
public record TareaDto(
    int Id,
    string Titulo,
    string? Descripcion,
    string Estado,
    DateTime FechaCreacion,
    DateTime? FechaActualizacion,
    UsuarioDto Usuario
);

// DTO for creating a new task
public record CrearTareaDto(
    [Required(ErrorMessage = "El título es requerido.")]
    [StringLength(200, ErrorMessage = "El título no puede exceder los 200 caracteres.")]
    string Titulo,

    [StringLength(500, ErrorMessage = "La descripción no puede exceder los 500 caracteres.")]
    string? Descripcion
);

// DTO for updating an existing task
public record ActualizarTareaDto(
    [StringLength(200, ErrorMessage = "El título no puede exceder los 200 caracteres.")]
    string? Titulo,

    [StringLength(500, ErrorMessage = "La descripción no puede exceder los 500 caracteres.")]
    string? Descripcion,

    EstadoTarea? Estado
);