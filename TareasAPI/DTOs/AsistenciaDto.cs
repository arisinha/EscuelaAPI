using System;
using TareasApi.Models;

namespace TareasApi.DTOs;

public record AsistenciaDto(int Id, int UsuarioId, int GrupoId, DateTime Fecha, EstadoAsistencia Estado, string? Observaciones);
