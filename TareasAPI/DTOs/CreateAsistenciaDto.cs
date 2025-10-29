using System;

namespace TareasApi.DTOs;

public record CreateAsistenciaDto(int UsuarioId, int GrupoId, DateTime Fecha, int Estado, string? Observaciones);
