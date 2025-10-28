using TareasApi.Models;

namespace TareasApi.Repositories.Interfaces;

public interface IAsistenciaRepository
{
    Task<Asistencia> CreateAsync(Asistencia asistencia);
    Task<Asistencia?> GetByIdAsync(int id);
    Task<IEnumerable<Asistencia>> GetByGrupoAndFechaAsync(int grupoId, DateTime fecha);
    Task<IEnumerable<Asistencia>> GetByUsuarioAsync(int usuarioId);
}
