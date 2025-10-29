using TareasApi.Models;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services;

public class AsistenciaService : IAsistenciaService
{
    private readonly IAsistenciaRepository _repo;

    public AsistenciaService(IAsistenciaRepository repo)
    {
        _repo = repo;
    }

    public Task<Asistencia> CreateAsync(Asistencia asistencia)
    {
        // Business rules could go here (e.g., prevent duplicate for same user/grupo/fecha)
        return _repo.CreateAsync(asistencia);
    }

    public Task<Asistencia?> GetByIdAsync(int id) => _repo.GetByIdAsync(id);

    public Task<IEnumerable<Asistencia>> GetByGrupoAndFechaAsync(int grupoId, DateTime fecha) => _repo.GetByGrupoAndFechaAsync(grupoId, fecha);

    public Task<IEnumerable<Asistencia>> GetByUsuarioAsync(int usuarioId) => _repo.GetByUsuarioAsync(usuarioId);
}
