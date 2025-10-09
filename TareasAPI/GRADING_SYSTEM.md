# Sistema de Calificaciones - Documentación de APIs

## Endpoints Disponibles

### 1. Calificar una Entrega
**POST** `/api/entregas/{id}/calificar`

```json
{
  "calificacion": 95.5,
  "retroalimentacionProfesor": "Excelente trabajo. La implementación es clara y cumple con todos los requisitos. Solo falta documentar algunos métodos."
}
```

**Respuesta:**
```json
{
  "success": true,
  "message": "Entrega calificada exitosamente",
  "data": {
    "id": 1,
    "tareaId": 1,
    "alumnoId": 2,
    "nombreArchivo": "tarea1.pdf",
    "rutaArchivo": "/uploads/entregas/tarea1_20251009.pdf",
    "fechaEntrega": "2024-10-09T08:30:00Z",
    "calificacion": 95.5,
    "retroalimentacionProfesor": "Excelente trabajo...",
    "fechaCalificacion": "2024-10-09T10:15:00Z",
    "tarea": { ... },
    "alumno": { ... },
    "profesor": { ... }
  }
}
```

### 2. Obtener Entregas Sin Calificar
**GET** `/api/entregas/sin-calificar`

```json
{
  "success": true,
  "count": 15,
  "data": [
    {
      "id": 3,
      "tareaId": 2,
      "alumnoId": 4,
      "nombreArchivo": "proyecto_final.pdf",
      "rutaArchivo": "/uploads/entregas/proyecto_final_20251009.pdf",
      "fechaEntrega": "2024-10-09T09:45:00Z",
      "calificacion": null,
      "retroalimentacionProfesor": null,
      "fechaCalificacion": null,
      "tarea": { ... },
      "alumno": { ... },
      "profesor": null
    }
  ]
}
```

### 3. Obtener Entregas Calificadas por el Profesor
**GET** `/api/entregas/mis-calificaciones`

```json
{
  "success": true,
  "count": 8,
  "data": [
    {
      "id": 1,
      "tareaId": 1,
      "alumnoId": 2,
      "nombreArchivo": "tarea1.pdf",
      "rutaArchivo": "/uploads/entregas/tarea1_20251009.pdf",
      "fechaEntrega": "2024-10-09T08:30:00Z",
      "calificacion": 95.5,
      "retroalimentacionProfesor": "Excelente trabajo...",
      "fechaCalificacion": "2024-10-09T10:15:00Z",
      "tarea": { ... },
      "alumno": { ... },
      "profesor": { ... }
    }
  ]
}
```

## Validaciones

### CalificarEntregaDto
- **Calificacion**: Requerida, rango 0-100
- **RetroalimentacionProfesor**: Opcional, máximo 1000 caracteres

### Reglas de Negocio
1. **Múltiples entregas permitidas**: Un alumno puede hacer múltiples entregas para la misma tarea
2. Solo se pueden calificar entregas que no han sido previamente calificadas
3. La calificación debe estar entre 0 y 100
4. Solo profesores pueden calificar entregas
5. Se registra automáticamente la fecha de calificación y el ID del profesor
6. Cada entrega es independiente y puede ser calificada por separado

## Headers Requeridos
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

## Códigos de Estado
- **200**: Operación exitosa
- **400**: Datos inválidos o entrega ya calificada
- **401**: No autorizado (token inválido)
- **404**: Entrega no encontrada
- **500**: Error interno del servidor

## Ejemplos de Uso en Swift

### Calificar Entrega
```swift
struct CalificarEntregaDto: Codable {
    let calificacion: Double
    let retroalimentacionProfesor: String?
}

func calificarEntrega(entregaId: Int, calificacion: Double, retroalimentacion: String?) async throws {
    let dto = CalificarEntregaDto(
        calificacion: calificacion,
        retroalimentacionProfesor: retroalimentacion
    )
    
    var request = URLRequest(url: URL(string: "\(baseURL)/api/entregas/\(entregaId)/calificar")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(dto)
    
    let (_, response) = try await URLSession.shared.data(for: request)
    // Manejar respuesta...
}
```

### Obtener Entregas Sin Calificar
```swift
func obtenerEntregasSinCalificar() async throws -> [EntregaDto] {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/entregas/sin-calificar")!)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(ApiResponse<[EntregaDto]>.self, from: data)
    return response.data
}
```

## Notas Importantes

1. **Autorización**: Todos los endpoints requieren autenticación JWT válida
2. **Roles**: Los endpoints de calificación están pensados para profesores
3. **Múltiples entregas**: Un alumno puede hacer múltiples entregas para la misma tarea
4. **Calificación única**: Cada entrega solo puede ser calificada una vez
5. **Timestamps**: Todas las fechas se manejan en UTC
6. **Archivos**: Los archivos de entregas se mantienen accesibles después de la calificación
7. **Versiones**: Cada entrega es independiente, permitiendo correcciones y mejoras

## Casos de Uso para Múltiples Entregas

### Escenario 1: Correcciones
- Alumno sube primera versión con errores
- Profesor califica con nota baja y retroalimentación
- Alumno corrige y sube nueva versión
- Profesor puede calificar la nueva versión con mejor nota

### Escenario 2: Entregas Parciales
- Proyecto largo dividido en partes
- Alumno sube avances parciales
- Profesor puede revisar progreso y dar feedback
- Entrega final incluye todo el trabajo completo

### Escenario 3: Diferentes Formatos
- Alumno sube código fuente (archivo .zip)
- Luego sube documentación (archivo .pdf)
- Profesor califica ambos componentes por separado

## Base de Datos - Nuevos Campos en Entregas

```sql
ALTER TABLE Entregas ADD COLUMN Calificacion DECIMAL(5,2) NULL;
ALTER TABLE Entregas ADD COLUMN RetroalimentacionProfesor VARCHAR(1000) NULL;
ALTER TABLE Entregas ADD COLUMN ProfesorId INT NULL;
ALTER TABLE Entregas ADD COLUMN FechaCalificacion DATETIME NULL;
ALTER TABLE Entregas ADD FOREIGN KEY (ProfesorId) REFERENCES Usuarios(Id);
```