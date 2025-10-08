namespace TareasApi.Middlewares;

public static class MiddlewareExtensions
{
    public static void UseExceptionMiddleware(this IApplicationBuilder builder)
    {
        builder.UseMiddleware<ExceptionMiddleware>();
    }
}