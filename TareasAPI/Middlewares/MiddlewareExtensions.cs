namespace TareasApi.Middlewares;

public static class MiddlewareExtensions
{
    public static void UseAuditMiddleware(this IApplicationBuilder builder)
    {
        builder.UseMiddleware<AuditMiddleware>();
    }

    public static void UseExceptionMiddleware(this IApplicationBuilder builder)
    {
        builder.UseMiddleware<ExceptionMiddleware>();
    }
}