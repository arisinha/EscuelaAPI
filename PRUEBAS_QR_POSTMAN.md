# 🧪 Guía de Pruebas del Lector QR con Postman

## 📋 Requisitos Previos

1. **Iniciar el servidor:**
   ```bash
   cd TareasAPI
   dotnet run
   ```
   El servidor debe estar corriendo en `http://localhost:5130`

2. **Aplicar la migración de base de datos:**
   ```bash
   dotnet ef database update
   ```

3. **Tener un usuario registrado y obtener el token JWT**

---

## 🔐 Paso 1: Obtener el Token de Autenticación

Todos los endpoints de QR requieren autenticación. Primero debes hacer login:

### Login
```
POST http://localhost:5130/api/Auth/login
Content-Type: application/json

{
  "nombreUsuario": "tu_usuario",
  "password": "tu_contraseña"
}
```

**Respuesta esperada:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "usuario": {
    "id": 1,
    "nombreUsuario": "profesor1",
    "nombreCompleto": "Profesor Demo"
  }
}
```

⚠️ **Copia el token** - Lo necesitarás para todas las siguientes peticiones.

---

## 🎯 Paso 2: Configurar Postman

### Opción A: Configurar Authorization en cada request
1. En la pestaña **Authorization**
2. Type: **Bearer Token**
3. Token: Pega el token que obtuviste

### Opción B: Crear una variable de entorno
1. Click en el icono de ojo (arriba derecha) → **Add**
2. Nombre: `EscuelaAPI`
3. Agrega variable:
   - `baseUrl`: `http://localhost:5130`
   - `token`: (pega tu token aquí)
4. Usa `{{baseUrl}}` y `{{token}}` en tus requests

---

## 🧪 Paso 3: Probar los Endpoints del Lector QR

### 1️⃣ Decodificar QR (Obtener info del alumno)

**Propósito:** Verificar que el QR del alumno es válido y obtener su información.

```
POST http://localhost:5130/api/Qr/decodificar
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "qrData": "1"
}
```

**Notas:**
- `qrData` puede ser el **ID del usuario** (ej: "1", "2", "3")
- O puede ser el **nombre de usuario** (ej: "alumno1")

**Respuesta esperada (200 OK):**
```json
{
  "success": true,
  "message": "QR decodificado exitosamente",
  "data": {
    "alumnoId": 1,
    "nombreCompleto": "Juan Pérez",
    "nombreUsuario": "alumno1"
  }
}
```

**Errores posibles:**
- `400 Bad Request`: QR inválido o usuario no encontrado
- `401 Unauthorized`: Token faltante o inválido

---

### 2️⃣ Registrar Asistencia con QR

**Propósito:** Marcar la asistencia de un alumno escaneando su QR.

```
POST http://localhost:5130/api/Qr/asistencia
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "qrData": "1",
  "grupoId": 1,
  "fecha": "2025-11-02T10:00:00Z",
  "estado": 1,
  "observaciones": "Llegó puntual"
}
```

**Parámetros:**
- `qrData`: ID o username del alumno (string)
- `grupoId`: ID del grupo (int) - **REQUERIDO**
- `fecha`: Fecha y hora (DateTime) - Opcional, por defecto usa la fecha actual
- `estado`: Estado de asistencia (int):
  - `1` = Presente
  - `2` = Ausente
  - `3` = Justificado
- `observaciones`: Notas adicionales (string) - Opcional

**Respuesta esperada (200 OK):**
```json
{
  "success": true,
  "message": "Asistencia registrada exitosamente",
  "data": {
    "id": 15,
    "usuarioId": 1,
    "grupoId": 1,
    "fecha": "2025-11-02T10:00:00Z",
    "estado": 1,
    "observaciones": "Llegó puntual"
  }
}
```

**Casos especiales:**
- Si ya existe asistencia para ese alumno en ese grupo y fecha, se **actualiza** en lugar de crear una nueva

---

### 3️⃣ Calificar Entrega con QR

**Propósito:** Calificar la entrega de un alumno verificando que su QR coincide con la entrega.

```
POST http://localhost:5130/api/Qr/calificar
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "qrData": "1",
  "entregaId": 5,
  "calificacion": 95.5,
  "retroalimentacionProfesor": "Excelente trabajo, muy completo y bien explicado"
}
```

**Parámetros:**
- `qrData`: ID o username del alumno (string) - **REQUERIDO**
- `entregaId`: ID de la entrega a calificar (int) - **REQUERIDO**
- `calificacion`: Nota de 0 a 100 (decimal) - **REQUERIDO**
- `retroalimentacionProfesor`: Comentarios del profesor (string, max 1000 caracteres) - Opcional

**Respuesta esperada (200 OK):**
```json
{
  "success": true,
  "message": "Entrega calificada exitosamente",
  "data": {
    "id": 5,
    "tareaId": 2,
    "alumnoId": 1,
    "comentario": "Mi tarea completada",
    "nombreArchivo": "documento.pdf",
    "rutaArchivo": "/uploads/documento.pdf",
    "tipoArchivo": "application/pdf",
    "tamanoArchivo": 52428,
    "fechaEntrega": "2025-11-01T14:30:00Z",
    "calificacion": 95.5,
    "retroalimentacionProfesor": "Excelente trabajo...",
    "fechaCalificacion": "2025-11-02T10:15:00Z",
    "alumno": { ... },
    "profesor": { ... }
  }
}
```

**Validaciones:**
- ✅ La entrega debe existir
- ✅ El QR escaneado debe corresponder al alumno de esa entrega
- ✅ La calificación debe estar entre 0 y 100

**Errores posibles:**
- `400 Bad Request`: 
  - "QR inválido o alumno no encontrado"
  - "Entrega con ID X no encontrada"
  - "El QR escaneado no corresponde al alumno de esta entrega"
  - "La calificación debe estar entre 0 y 100"

---

### 4️⃣ Agregar Alumno a Grupo con QR

**Propósito:** Inscribir a un alumno en un grupo escaneando su QR.

```
POST http://localhost:5130/api/Qr/agregar-grupo
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "qrData": "1",
  "grupoId": 1
}
```

**Parámetros:**
- `qrData`: ID o username del alumno (string) - **REQUERIDO**
- `grupoId`: ID del grupo (int) - **REQUERIDO**

**Respuesta esperada (200 OK):**
```json
{
  "success": true,
  "message": "Alumno agregado al grupo exitosamente",
  "data": null
}
```

**Notas:**
- Si el alumno ya está en el grupo, la operación es **idempotente** (no genera error)
- El sistema verifica que tanto el alumno como el grupo existan

---

## 🔍 Prueba Completa - Flujo de Trabajo

### Escenario: Clase del día

1. **Crear/Login como profesor**
2. **Tomar asistencia de varios alumnos:**
   - Escanear QR de alumno 1 → `POST /api/Qr/asistencia`
   - Escanear QR de alumno 2 → `POST /api/Qr/asistencia`
   - etc.

3. **Verificar info de un alumno antes de calificar:**
   - Escanear QR → `POST /api/Qr/decodificar`

4. **Calificar entregas:**
   - Listar entregas sin calificar → `GET /api/Entregas/sin-calificar`
   - Por cada entrega: Escanear QR del alumno → `POST /api/Qr/calificar`

5. **Agregar nuevo alumno al grupo:**
   - Escanear QR → `POST /api/Qr/agregar-grupo`

---

## 🐛 Resolución de Problemas

### Error: "Access denied for user 'root'@'localhost'"
- Verifica que MySQL esté corriendo
- Verifica la contraseña en `appsettings.json`

### Error: "Table 'GrupoUsuarios' doesn't exist"
- Ejecuta: `dotnet ef database update`

### Error: 401 Unauthorized
- Verifica que el token sea válido
- El token podría haber expirado, haz login nuevamente

### Error: "Grupo con ID X no encontrado"
- Primero crea un grupo: `POST /api/Grupos`

### Error: "Entrega con ID X no encontrada"
- Verifica que exista una entrega con ese ID
- Usa: `GET /api/Entregas/sin-calificar` para ver entregas disponibles

---

## 📊 Datos de Prueba Sugeridos

Antes de probar, asegúrate de tener:
- ✅ Al menos 1 usuario profesor (para login)
- ✅ Al menos 1-2 usuarios alumnos (IDs: 1, 2, 3...)
- ✅ Al menos 1 grupo creado
- ✅ Al menos 1 tarea creada
- ✅ Al menos 1 entrega sin calificar (para probar calificación)

---

## 💡 Tips para Postman

1. **Crear una Colección:** Agrupa todos los requests del Lector QR
2. **Usar Variables:** Define `{{baseUrl}}` y `{{token}}`
3. **Tests automáticos:** Agrega scripts para validar respuestas
4. **Pre-request Scripts:** Genera fechas dinámicas
   ```javascript
   pm.environment.set("currentDate", new Date().toISOString());
   ```

¡Listo para probar! 🚀
