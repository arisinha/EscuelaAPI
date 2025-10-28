using TareasApi.Models;

namespace TareasApi.Services.Interfaces;

public interface IAsistenciaService
{
    Task<Asistencia> CreateAsync(Asistencia asistencia);
    Task<Asistencia?> GetByIdAsync(int id);
    Task<IEnumerable<Asistencia>> GetByGrupoAndFechaAsync(int grupoId, DateTime fecha);
    Task<IEnumerable<Asistencia>> GetByUsuarioAsync(int usuarioId);
}
