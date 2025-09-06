namespace TareasAPI.Middlewares;

public static class MiddlewareExtensions
{
    public static IApplicationBuilder UseAuditMiddleware(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<AuditMiddleware>();
    }

    public static IApplicationBuilder UseExceptionMiddleware(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<ExceptionMiddleware>();
    }
}