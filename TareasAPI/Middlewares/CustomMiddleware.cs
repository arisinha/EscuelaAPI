namespace TareasApi.Middlewares;

public class AuditMiddleware
{
    private readonly ILogger<AuditMiddleware> _logger;
    private readonly RequestDelegate _next;

    public AuditMiddleware(RequestDelegate next, ILogger<AuditMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        await _next(context);

        var request = context.Request;


        if (request.Path.StartsWithSegments("/api/tareas") && request.Method == "POST")
            if (context.Response.StatusCode == 201)
            {
                var userEmail = context.User.Identity?.Name ?? "Usuario desconocido";

                _logger.LogInformation(
                    "AUDITORÍA: El usuario '{UserEmail}' creó una nueva tarea exitosamente.",
                    userEmail
                );
            }
    }
}