using System.ComponentModel.DataAnnotations;

namespace TareasApi.DTOs;

public record EntregaDto(
    int Id,
    int TareaId,
    int AlumnoId,
    string? Comentario,
    string NombreArchivo,
    string RutaArchivo,
    string TipoArchivo,
    long TamanoArchivo,
    DateTimeOffset FechaEntrega,
    decimal? Calificacion,
    string? RetroalimentacionProfesor,
    DateTimeOffset? FechaCalificacion,
    UsuarioDto Alumno,
    UsuarioDto? Profesor
);

public record CrearEntregaDto(
    [Required] int TareaId,
    [StringLength(500)] string? Comentario,
    [Required] IFormFile Archivo
);

public record EntregaResponseDto(
    int Id,
    int TareaId,
    string? Comentario,
    string NombreArchivo,
    string UrlArchivo,
    DateTimeOffset FechaEntrega,
    decimal? Calificacion,
    string? RetroalimentacionProfesor,
    DateTimeOffset? FechaCalificacion
);

public record CalificarEntregaDto(
    [Required]
    [Range(0, 100, ErrorMessage = "La calificación debe estar entre 0 y 100")]
    decimal Calificacion,
    
    [StringLength(1000, ErrorMessage = "La retroalimentación no puede exceder los 1000 caracteres")]
    string? RetroalimentacionProfesor
);