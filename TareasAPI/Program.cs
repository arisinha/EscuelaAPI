using System;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.Tasks;
using System.Text.Json;
using System.Linq;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using TareasApi.Data;
using TareasApi.Middlewares;
using TareasApi.Repositories;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services;
using TareasApi.Services.Interfaces;
 

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
builder.Services.AddScoped<ITareaRepository, TareaRepository>();
builder.Services.AddScoped<ITareaService, TareaService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IGrupoRepository, GrupoRepository>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Tareas API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. \r\n\r\n Enter 'Bearer' [space] and then your token in the text input below.\r\n\r\nExample: \"Bearer 12345abcdef\""
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
            NameClaimType = JwtRegisteredClaimNames.Sub,
            // Remove default clock skew so expiration is strict
            ClockSkew = TimeSpan.Zero
        };

        // Keep only necessary event handlers: handle failures and challenges gracefully.
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = async context =>
            {
                var loggerFactory = context.HttpContext.RequestServices.GetService(typeof(ILoggerFactory)) as ILoggerFactory;
                var logger = loggerFactory?.CreateLogger("JwtAuth");
                var reason = context.Exception?.GetType().Name ?? "AuthenticationFailed";
                logger?.LogError(context.Exception, "Authentication failed: {reason}", reason);

                if (context.Exception is SecurityTokenExpiredException)
                {
                    // If response hasn't started we can add header; otherwise skip.
                    if (!context.Response.HasStarted)
                    {
                        context.Response.Headers.Append("Token-Expired", "true");
                    }
                }

                // If client expects JSON, return a JSON body with the error reason
                var acceptHeader = context.Request.Headers["Accept"].ToString();
                if (!string.IsNullOrEmpty(acceptHeader) && acceptHeader.Contains("application/json"))
                {
                    // Only write if the response hasn't started yet.
                    if (!context.Response.HasStarted)
                    {
                        context.Response.ContentType = "application/json";
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        var payload = JsonSerializer.Serialize(new
                        {
                            success = false,
                            error = reason,
                            message = context.Exception?.Message
                        });
                        await context.Response.WriteAsync(payload);
                    }
                }

                // Do not call context.Fail here because we've written the response.
                // This allows the normal pipeline to finish.
            },
            OnChallenge = async context =>
            {
                var loggerFactory = context.HttpContext.RequestServices.GetService(typeof(ILoggerFactory)) as ILoggerFactory;
                var logger = loggerFactory?.CreateLogger("JwtAuth");

                // If a response has already started, let the default handling proceed
                if (context.Response.HasStarted)
                {
                    logger?.LogWarning("OnChallenge: response has already started");
                    return;
                }

                // Prevent the default challenge response and write JSON only if allowed
                context.HandleResponse();
                if (!context.Response.HasStarted)
                {
                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    context.Response.ContentType = "application/json";

                    // Determine error code and message
                    var error = context.Error ?? "invalid_token";
                    var message = context.ErrorDescription ?? context.AuthenticateFailure?.Message ?? "Unauthorized";

                    if (context.AuthenticateFailure is SecurityTokenExpiredException)
                    {
                        context.Response.Headers.Append("Token-Expired", "true");
                    }

                    logger?.LogWarning("OnChallenge returned 401: error={error} message={message}", error, message);

                    var payload = JsonSerializer.Serialize(new { success = false, error, message });
                    await context.Response.WriteAsync(payload);
                }
            }
        };
    });

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<ExceptionMiddleware>();
app.UseHttpsRedirection();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
if (app.Environment.IsDevelopment())
{
    // Apply any pending EF Core migrations at startup so the database schema stays in sync.
    // This is convenient for development. In production we prefer manual migration application.
    using (var scope = app.Services.CreateScope())
    {
        var services = scope.ServiceProvider;
        try
        {
            var db = services.GetRequiredService<ApplicationDbContext>();
            db.Database.Migrate();
        }
        catch (Exception ex)
        {
            var logger = services.GetService<ILogger<Program>>();
            logger?.LogError(ex, "An error occurred while migrating the database on startup.");
            throw;
        }
    }

    // Development-only endpoint to reset a user's password by hashing a new password.
    // Use to migrate users that still have plaintext passwords stored.
    app.MapPost("/dev/users/reset-password", async (
        [FromServices] ApplicationDbContext db,
        [FromBody] ResetPasswordRequest req) =>
    {
        if (req is null || string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.NewPassword))
        {
            return Results.BadRequest(new { success = false, message = "username and newPassword are required" });
        }

        var user = await db.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == req.Username);
        if (user == null)
        {
            return Results.NotFound(new { success = false, message = "User not found" });
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
        await db.SaveChangesAsync();
        return Results.Ok(new { success = true, message = $"Password reset for {req.Username}" });
    });
}

app.Run();

public record ResetPasswordRequest(string Username, string NewPassword);