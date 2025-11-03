using Microsoft.EntityFrameworkCore;
using TareasApi.Data;
using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services;

public class QrService : IQrService
{
    private readonly ApplicationDbContext _context;
    private readonly IAsistenciaService _asistenciaService;
    private readonly IEntregaService _entregaService;

    public QrService(
        ApplicationDbContext context,
        IAsistenciaService asistenciaService,
        IEntregaService entregaService)
    {
        _context = context;
        _asistenciaService = asistenciaService;
        _entregaService = entregaService;
    }

    public async Task<QrAlumnoInfoDto> DecodificarQrAlumnoAsync(string qrData)
    {
        var usuario = await ValidarYObtenerUsuarioAsync(qrData);
        
        if (usuario == null)
            throw new ArgumentException("QR inválido o usuario no encontrado");

        return new QrAlumnoInfoDto(
            usuario.Id,
            usuario.NombreCompleto,
            usuario.NombreUsuario
        );
    }

    public async Task<AsistenciaDto> RegistrarAsistenciaQrAsync(QrAsistenciaDto dto, int profesorId)
    {
        // Validar usuario del QR
        var alumno = await ValidarYObtenerUsuarioAsync(dto.QrData);
        if (alumno == null)
            throw new ArgumentException("QR inválido o alumno no encontrado");

        // Validar que el grupo existe
        var grupo = await _context.Grupos.FindAsync(dto.GrupoId);
        if (grupo == null)
            throw new ArgumentException($"Grupo con ID {dto.GrupoId} no encontrado");

        // Verificar si ya existe asistencia para este alumno en este grupo y fecha
        var fecha = (dto.Fecha ?? DateTime.UtcNow.Date).ToUniversalTime();
        var asistenciaExistente = await _context.Asistencias
            .FirstOrDefaultAsync(a => 
                a.UsuarioId == alumno.Id && 
                a.GrupoId == dto.GrupoId && 
                a.Fecha.Date == fecha.Date);

        if (asistenciaExistente != null)
        {
            // Actualizar asistencia existente
            asistenciaExistente.Estado = dto.Estado;
            asistenciaExistente.Observaciones = dto.Observaciones;
            await _context.SaveChangesAsync();

            return new AsistenciaDto(
                asistenciaExistente.Id,
                asistenciaExistente.UsuarioId,
                asistenciaExistente.GrupoId,
                asistenciaExistente.Fecha,
                asistenciaExistente.Estado,
                asistenciaExistente.Observaciones
            );
        }

        // Crear nueva asistencia
        var asistencia = new Asistencia
        {
            UsuarioId = alumno.Id,
            GrupoId = dto.GrupoId,
            Fecha = fecha,
            Estado = dto.Estado,
            Observaciones = dto.Observaciones
        };

        var created = await _asistenciaService.CreateAsync(asistencia);
        
        return new AsistenciaDto(
            created.Id,
            created.UsuarioId,
            created.GrupoId,
            created.Fecha,
            created.Estado,
            created.Observaciones
        );
    }

    public async Task<EntregaDto> CalificarConQrAsync(QrCalificarDto dto, int profesorId)
    {
        // Validar usuario del QR
        var alumno = await ValidarYObtenerUsuarioAsync(dto.QrData);
        if (alumno == null)
            throw new ArgumentException("QR inválido o alumno no encontrado");

        // Validar que la entrega existe y pertenece al alumno del QR
        var entrega = await _context.Entregas
            .Include(e => e.Alumno)
            .Include(e => e.Profesor)
            .FirstOrDefaultAsync(e => e.Id == dto.EntregaId);

        if (entrega == null)
            throw new ArgumentException($"Entrega con ID {dto.EntregaId} no encontrada");

        if (entrega.AlumnoId != alumno.Id)
            throw new ArgumentException("El QR escaneado no corresponde al alumno de esta entrega");

        // Calificar la entrega usando el servicio existente
        var calificarDto = new CalificarEntregaDto(
            dto.Calificacion,
            dto.RetroalimentacionProfesor
        );

        return await _entregaService.CalificarEntregaAsync(dto.EntregaId, calificarDto, profesorId);
    }

    public async Task<bool> AgregarAlumnoGrupoQrAsync(QrAgregarGrupoDto dto, int profesorId)
    {
        // Validar usuario del QR
        var alumno = await ValidarYObtenerUsuarioAsync(dto.QrData);
        if (alumno == null)
            throw new ArgumentException("QR inválido o alumno no encontrado");

        // Validar que el grupo existe
        var grupo = await _context.Grupos
            .Include(g => g.Miembros)
            .FirstOrDefaultAsync(g => g.Id == dto.GrupoId);

        if (grupo == null)
            throw new ArgumentException($"Grupo con ID {dto.GrupoId} no encontrado");

        // Verificar si el alumno ya está en el grupo
        if (grupo.Miembros.Any(m => m.Id == alumno.Id))
        {
            // Ya está en el grupo, no hacer nada
            return true;
        }

        // Agregar el alumno al grupo
        grupo.Miembros.Add(alumno);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<Usuario?> ValidarYObtenerUsuarioAsync(string qrData)
    {
        if (string.IsNullOrWhiteSpace(qrData))
            return null;

        // El QR debe contener el ID del usuario
        // Intentar parsear como int
        if (!int.TryParse(qrData, out int usuarioId))
        {
            // Si no es un número, podría ser el nombre de usuario
            return await _context.Usuarios
                .FirstOrDefaultAsync(u => u.NombreUsuario == qrData);
        }

        return await _context.Usuarios.FindAsync(usuarioId);
    }
}
