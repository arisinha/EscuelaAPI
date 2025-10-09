using TareasApi.DTOs;
using TareasApi.Models;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services.Interfaces;

namespace TareasApi.Services;

public class EntregaService : IEntregaService
{
    private readonly IEntregaRepository _entregaRepository;
    private readonly ITareaRepository _tareaRepository;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<EntregaService> _logger;

    public EntregaService(
        IEntregaRepository entregaRepository, 
        ITareaRepository tareaRepository,
        IWebHostEnvironment environment,
        ILogger<EntregaService> logger)
    {
        _entregaRepository = entregaRepository;
        _tareaRepository = tareaRepository;
        _environment = environment;
        _logger = logger;
    }

    public async Task<EntregaResponseDto> CrearEntregaAsync(CrearEntregaDto dto, int alumnoId)
    {
        // Verificar que la tarea existe
        var tarea = await _tareaRepository.FindByIdAsync(dto.TareaId);
        if (tarea == null)
            throw new ArgumentException("La tarea especificada no existe.");

        // Verificar que no existe ya una entrega para esta tarea y alumno
        var entregaExistente = await _entregaRepository.GetByTareaIdAndAlumnoIdAsync(dto.TareaId, alumnoId);
        if (entregaExistente != null)
            throw new InvalidOperationException("Ya existe una entrega para esta tarea.");

        // Validar archivo
        if (dto.Archivo == null || dto.Archivo.Length == 0)
            throw new ArgumentException("Debe proporcionar un archivo válido.");

        var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif", "application/pdf" };
        if (!allowedTypes.Contains(dto.Archivo.ContentType.ToLower()))
            throw new ArgumentException("Tipo de archivo no permitido. Solo se permiten imágenes (JPEG, PNG, GIF) y PDF.");

        const long maxSize = 10 * 1024 * 1024; // 10 MB
        if (dto.Archivo.Length > maxSize)
            throw new ArgumentException("El archivo es demasiado grande. Tamaño máximo: 10 MB.");

        // Guardar archivo
        var uploadsPath = Path.Combine(_environment.WebRootPath ?? _environment.ContentRootPath, "uploads", "entregas");
        if (!Directory.Exists(uploadsPath))
            Directory.CreateDirectory(uploadsPath);

        var fileName = $"{Guid.NewGuid()}_{Path.GetFileName(dto.Archivo.FileName)}";
        var filePath = Path.Combine(uploadsPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await dto.Archivo.CopyToAsync(stream);
        }

        // Crear entrega
        var entrega = new Entrega
        {
            TareaId = dto.TareaId,
            AlumnoId = alumnoId,
            Comentario = dto.Comentario,
            NombreArchivo = dto.Archivo.FileName,
            RutaArchivo = filePath,
            TipoArchivo = dto.Archivo.ContentType,
            TamanoArchivo = dto.Archivo.Length,
            FechaEntrega = DateTimeOffset.UtcNow,
            Tarea = null!,
            Alumno = null!
        };

        var entregaCreada = await _entregaRepository.CreateAsync(entrega);

        return new EntregaResponseDto(
            entregaCreada.Id,
            entregaCreada.TareaId,
            entregaCreada.Comentario,
            entregaCreada.NombreArchivo,
            $"/uploads/entregas/{fileName}",
            entregaCreada.FechaEntrega,
            entregaCreada.Calificacion,
            entregaCreada.RetroalimentacionProfesor,
            entregaCreada.FechaCalificacion
        );
    }

    public async Task<EntregaDto?> GetByIdAsync(int id)
    {
        var entrega = await _entregaRepository.GetByIdAsync(id);
        return entrega == null ? null : MapEntregaToDto(entrega);
    }

    public async Task<IEnumerable<EntregaDto>> GetByTareaIdAsync(int tareaId)
    {
        var entregas = await _entregaRepository.GetByTareaIdAsync(tareaId);
        return entregas.Select(MapEntregaToDto);
    }

    public async Task<IEnumerable<EntregaDto>> GetByAlumnoIdAsync(int alumnoId)
    {
        var entregas = await _entregaRepository.GetByAlumnoIdAsync(alumnoId);
        return entregas.Select(MapEntregaToDto);
    }

    public async Task<EntregaDto?> GetByTareaIdAndAlumnoIdAsync(int tareaId, int alumnoId)
    {
        var entrega = await _entregaRepository.GetByTareaIdAndAlumnoIdAsync(tareaId, alumnoId);
        return entrega == null ? null : MapEntregaToDto(entrega);
    }

    public async Task<bool> DeleteAsync(int id, int alumnoId)
    {
        var entrega = await _entregaRepository.GetByIdAsync(id);
        if (entrega == null || entrega.AlumnoId != alumnoId)
            return false;

        // Eliminar archivo físico
        if (File.Exists(entrega.RutaArchivo))
        {
            try
            {
                File.Delete(entrega.RutaArchivo);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo eliminar el archivo físico: {FilePath}", entrega.RutaArchivo);
            }
        }

        return await _entregaRepository.DeleteAsync(id);
    }

    public async Task<EntregaDto> CalificarEntregaAsync(int entregaId, CalificarEntregaDto dto, int profesorId)
    {
        var entrega = await _entregaRepository.GetByIdAsync(entregaId);
        if (entrega == null)
            throw new ArgumentException("La entrega especificada no existe.");

        entrega.Calificacion = dto.Calificacion;
        entrega.RetroalimentacionProfesor = dto.RetroalimentacionProfesor;
        entrega.ProfesorId = profesorId;
        entrega.FechaCalificacion = DateTimeOffset.UtcNow;

        var entregaActualizada = await _entregaRepository.UpdateAsync(entrega);
        return MapEntregaToDto(entregaActualizada!);
    }

    public async Task<IEnumerable<EntregaDto>> GetEntregasSinCalificarAsync()
    {
        var entregas = await _entregaRepository.GetEntregasSinCalificarAsync();
        return entregas.Select(MapEntregaToDto);
    }

    public async Task<IEnumerable<EntregaDto>> GetEntregasCalificadasPorProfesorAsync(int profesorId)
    {
        var entregas = await _entregaRepository.GetEntregasCalificadasPorProfesorAsync(profesorId);
        return entregas.Select(MapEntregaToDto);
    }

    private static EntregaDto MapEntregaToDto(Entrega entrega)
    {
        var alumnoDto = new UsuarioDto(
            entrega.Alumno.Id,
            entrega.Alumno.NombreUsuario,
            entrega.Alumno.NombreCompleto
        );

        var profesorDto = entrega.Profesor != null ? new UsuarioDto(
            entrega.Profesor.Id,
            entrega.Profesor.NombreUsuario,
            entrega.Profesor.NombreCompleto
        ) : null;

        var fileName = Path.GetFileName(entrega.RutaArchivo);
        
        return new EntregaDto(
            entrega.Id,
            entrega.TareaId,
            entrega.AlumnoId,
            entrega.Comentario,
            entrega.NombreArchivo,
            $"/uploads/entregas/{fileName}",
            entrega.TipoArchivo,
            entrega.TamanoArchivo,
            entrega.FechaEntrega,
            entrega.Calificacion,
            entrega.RetroalimentacionProfesor,
            entrega.FechaCalificacion,
            alumnoDto,
            profesorDto
        );
    }
}