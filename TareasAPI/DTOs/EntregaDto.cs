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
    UsuarioDto Alumno
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
    DateTimeOffset FechaEntrega
);