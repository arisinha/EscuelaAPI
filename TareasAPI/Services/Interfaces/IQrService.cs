using TareasApi.DTOs;
using TareasApi.Models;

namespace TareasApi.Services.Interfaces;

public interface IQrService
{
    /// <summary>
    /// Decodifica el QR y obtiene la información del alumno
    /// </summary>
    Task<QrAlumnoInfoDto> DecodificarQrAlumnoAsync(string qrData);
    
    /// <summary>
    /// Registra asistencia de un alumno mediante QR
    /// </summary>
    Task<AsistenciaDto> RegistrarAsistenciaQrAsync(QrAsistenciaDto dto, int profesorId);
    
    /// <summary>
    /// Califica una entrega mediante QR del alumno
    /// </summary>
    Task<EntregaDto> CalificarConQrAsync(QrCalificarDto dto, int profesorId);
    
    /// <summary>
    /// Agrega un alumno a un grupo mediante QR
    /// </summary>
    Task<bool> AgregarAlumnoGrupoQrAsync(QrAgregarGrupoDto dto, int profesorId);
    
    /// <summary>
    /// Valida que el QR data sea un ID de usuario válido
    /// </summary>
    Task<Usuario?> ValidarYObtenerUsuarioAsync(string qrData);
}
