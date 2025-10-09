# Configuración de Permisos para AppTareas

## Permisos requeridos para el funcionamiento completo de la app

Para que la aplicación funcione correctamente con las funcionalidades de cámara y entregas, necesitas agregar los siguientes permisos al archivo Info.plist del proyecto:

### 1. Acceso a la Cámara
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para tomar fotos de las entregas de tareas.</string>
```

### 2. Acceso a la Galería de Fotos
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Esta app necesita acceso a la galería de fotos para seleccionar imágenes para las entregas de tareas.</string>
```

## Cómo agregar los permisos en Xcode:

1. Abre el proyecto AppTareas.xcodeproj en Xcode
2. Selecciona el target "AppTareas" en el navegador del proyecto
3. Ve a la pestaña "Info"
4. Haz clic en el botón "+" para agregar una nueva entrada
5. Busca y selecciona "Privacy - Camera Usage Description"
6. En el valor, escribe: "Esta app necesita acceso a la cámara para tomar fotos de las entregas de tareas."
7. Repite el proceso para "Privacy - Photo Library Usage Description"
8. En el valor, escribe: "Esta app necesita acceso a la galería de fotos para seleccionar imágenes para las entregas de tareas."

## Funcionalidades agregadas:

### Para Estudiantes:
- ✅ **Vista de detalle de tareas mejorada** con sección de entregas
- ✅ **Botón "Subir Entrega"** que permite elegir entre cámara y galería
- ✅ **Selector de imágenes** con soporte para cámara y galería de fotos
- ✅ **Upload automático** de archivos al servidor con validación
- ✅ **Vista de entregas propias** con estado de calificación
- ✅ **Visualización de calificaciones** y retroalimentación del profesor

### Para Profesores:
- ✅ **Botón "Entregas por Calificar"** en la pantalla principal
- ✅ **Lista de entregas sin calificar** de todos los estudiantes
- ✅ **Interfaz de calificación** con:
  - Campo numérico para calificación (0-100)
  - Campo de texto para retroalimentación
  - Validación de entrada
  - Descripción automática del nivel (Excelente, Bueno, etc.)
- ✅ **Sistema de colores** para diferentes rangos de calificación
- ✅ **Actualización automática** después de calificar

### Modelos y APIs:
- ✅ **Modelo Entrega completo** con todos los campos necesarios
- ✅ **Endpoints integrados**:
  - `GET /api/entregas` - Obtener mis entregas
  - `POST /api/entregas` - Crear nueva entrega con archivo
  - `POST /api/entregas/{id}/calificar` - Calificar entrega
  - `GET /api/entregas/sin-calificar` - Entregas pendientes de calificar
- ✅ **Upload multipart** para imágenes y documentos
- ✅ **Validación de archivos** (JPEG, PNG, GIF, PDF)
- ✅ **Manejo de errores** robusto

## Estructura de archivos agregados:

```
Login 2/
├── TaskDetailView.swift (actualizado)
├── EntregaRowView.swift (nuevo)
├── ImagePickerView.swift (nuevo)
├── GradingSheetView.swift (nuevo)
├── EntregasListView.swift (nuevo)
├── VistaGrupos.swift (actualizado)
├── ApiService.swift (actualizado)
└── UniversityModels.swift (actualizado)
```

## Flujo de trabajo:

### Para Estudiantes:
1. Ver lista de grupos → Seleccionar grupo → Ver tareas
2. Tocar una tarea → Ver detalle con sección de entregas
3. Si no hay entrega, tocar "Subir Entrega" → Elegir cámara o galería
4. Tomar foto o seleccionar imagen → Se sube automáticamente
5. Ver estado de calificación cuando el profesor la evalúe

### Para Profesores:
1. Ver lista de grupos → Tocar "Entregas por Calificar"
2. Ver lista de todas las entregas pendientes
3. Tocar "Calificar" en una entrega
4. Ingresar calificación (0-100) y retroalimentación opcional
5. Guardar → La entrega se marca como calificada

¡La aplicación ahora tiene un sistema completo de entregas con calificaciones!