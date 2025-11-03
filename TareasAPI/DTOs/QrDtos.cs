using System.ComponentModel.DataAnnotations;
using TareasApi.Models;

namespace TareasApi.DTOs;

/// <summary>
/// DTO para escanear código QR del alumno
/// El QR debe contener el ID del usuario (alumno)
/// </summary>
public record QrScanDto(
    [Required] string QrData
);

/// <summary>
/// DTO para registrar asistencia mediante QR
/// </summary>
public record QrAsistenciaDto(
    [Required] string QrData,
    [Required] int GrupoId,
    DateTime? Fecha,
    EstadoAsistencia Estado = EstadoAsistencia.Presente,
    string? Observaciones = null
);

/// <summary>
/// DTO para calificar trabajo mediante QR
/// </summary>
public record QrCalificarDto(
    [Required] string QrData,
    [Required] int EntregaId,
    [Required]
    [Range(0, 100, ErrorMessage = "La calificación debe estar entre 0 y 100")]
    decimal Calificacion,
    [StringLength(1000)] string? RetroalimentacionProfesor
);

/// <summary>
/// DTO para agregar alumno a grupo mediante QR
/// </summary>
public record QrAgregarGrupoDto(
    [Required] string QrData,
    [Required] int GrupoId
);

/// <summary>
/// Respuesta genérica para operaciones con QR
/// </summary>
public record QrResponseDto(
    bool Success,
    string Message,
    object? Data = null
);

/// <summary>
/// DTO para información del alumno obtenida del QR
/// </summary>
public record QrAlumnoInfoDto(
    int AlumnoId,
    string NombreCompleto,
    string NombreUsuario
);
