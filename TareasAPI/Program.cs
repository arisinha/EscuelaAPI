using System;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.Tasks;
using System.Text.Json.Serialization;
using System.Text.Json;
using System.Linq;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Logging;
using TareasApi.Data;
using TareasApi.Middlewares;
using TareasApi.Repositories;
using TareasApi.Repositories.Interfaces;
using TareasApi.Services;
using TareasApi.Services.Interfaces;
using TareasApi.Helpers;

var builder = WebApplication.CreateBuilder(args);
// Ensure JSON serializes DateTime values in ISO 8601 round-trip format with timezone ("o")
builder.Services.AddControllers().AddJsonOptions(opts =>
{
    opts.JsonSerializerOptions.Converters.Add(new DateTimeJsonConverter());
    opts.JsonSerializerOptions.Converters.Add(new NullableDateTimeJsonConverter());
});

// Converters implemented in Helpers/JsonConverters.cs
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

app.UseExceptionMiddleware(); 
app.UseHttpsRedirection();
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();
app.UseAuditMiddleware(); 
app.MapControllers();
// Apply any pending EF Core migrations at startup so the database schema stays in sync.
// This is convenient for development and small deployments. If migrations fail, we log and rethrow.
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

// Seed some data for development/testing: a test user and a few grupos
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var db = services.GetRequiredService<ApplicationDbContext>();
    try
    {
        // Seed or upsert test user
        var existingUser = db.Usuarios.FirstOrDefault(u => u.NombreUsuario == "testuser");
        if (existingUser == null)
        {
            var pwHash = BCrypt.Net.BCrypt.HashPassword("P@ssw0rd");
            db.Usuarios.Add(new TareasApi.Models.Usuario { NombreUsuario = "testuser", NombreCompleto = "Usuario de Prueba", PasswordHash = pwHash });
            db.SaveChanges();
        }
        else
        {
            // Ensure the password matches the known test password
            existingUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword("P@ssw0rd");
            db.SaveChanges();
        }

        // Seed grupos if none exist
        if (!db.Grupos.Any())
        {
            db.Grupos.AddRange(
                new TareasApi.Models.Grupo { NombreMateria = "Matemáticas", CodigoGrupo = "MATH101" },
                new TareasApi.Models.Grupo { NombreMateria = "Física", CodigoGrupo = "PHYS101" },
                new TareasApi.Models.Grupo { NombreMateria = "Historia", CodigoGrupo = "HIST101" }
            );
            db.SaveChanges();
        }

        // Seed up to 2 tareas per usuario for testing with mixed states and dates
        var gruposList = db.Grupos.ToList();
        var random = new Random();
        var possibleStates = new[] { TareasApi.Models.EstadoTarea.Pendiente, TareasApi.Models.EstadoTarea.EnProgreso, TareasApi.Models.EstadoTarea.Completada };
        foreach (var user in db.Usuarios.ToList())
        {
            var existingCount = db.Tareas.Count(t => t.UsuarioId == user.Id);
            for (int i = existingCount; i < 2; i++)
            {
                var grupoId = gruposList.Count > 0 ? gruposList[random.Next(gruposList.Count)].Id : (int?)null;
                var estado = possibleStates[random.Next(possibleStates.Length)];
                var createdAt = DateTimeOffset.UtcNow.AddDays(-random.Next(0, 30)).AddHours(-random.Next(0, 24));
                DateTimeOffset? updatedAt = null;
                // If completed, usually have an update timestamp; otherwise sometimes have one
                if (estado == TareasApi.Models.EstadoTarea.Completada || random.NextDouble() < 0.4)
                {
                    updatedAt = createdAt.AddDays(random.Next(0, 7)).AddHours(random.Next(0, 24));
                }

                db.Tareas.Add(new TareasApi.Models.Tarea
                {
                    Titulo = $"Tarea seed {i + 1} para {user.NombreUsuario}",
                    Descripcion = "Tarea creada por seed para pruebas",
                    UsuarioId = user.Id,
                    Usuario = user,
                    GrupoId = grupoId,
                    Estado = estado,
                    FechaCreacion = createdAt,
                    FechaActualizacion = updatedAt
                });
            }
        }
        db.SaveChanges();

        // Additionally: ensure there are example tasks attached to each Grupo (2 per grupo)
        var testUser = db.Usuarios.FirstOrDefault(u => u.NombreUsuario == "testuser");
        if (testUser != null)
        {
            foreach (var grupo in db.Grupos.ToList())
            {
                var countForGrupo = db.Tareas.Count(t => t.GrupoId == grupo.Id);
                for (int i = countForGrupo; i < 2; i++)
                {
                    // Vary the state: first example pending, second one random
                    var estado = i == 0 ? TareasApi.Models.EstadoTarea.Pendiente : (random.Next(2) == 0 ? TareasApi.Models.EstadoTarea.EnProgreso : TareasApi.Models.EstadoTarea.Completada);
                    var createdAt = DateTimeOffset.UtcNow.AddDays(-random.Next(1, 20)).AddHours(-random.Next(0, 24));
                    DateTimeOffset? updatedAt = null;
                    if (estado == TareasApi.Models.EstadoTarea.Completada)
                    {
                        updatedAt = createdAt.AddDays(random.Next(1, 5)).AddHours(random.Next(0, 24));
                    }

                    db.Tareas.Add(new TareasApi.Models.Tarea
                    {
                        Titulo = $"Ejemplo {grupo.CodigoGrupo} - {i + 1}",
                        Descripcion = $"Tarea de ejemplo para el grupo {grupo.NombreMateria}",
                        UsuarioId = testUser.Id,
                        Usuario = testUser,
                        GrupoId = grupo.Id,
                        Estado = estado,
                        FechaCreacion = createdAt,
                        FechaActualizacion = updatedAt
                    });
                }
            }
            db.SaveChanges();
        }
    }
    catch (Exception ex)
    {
        var logger = services.GetService<ILogger<Program>>();
        logger?.LogError(ex, "An error occurred while seeding the database.");
        // don't rethrow - seeding failure shouldn't block the app from starting in dev
    }
}

app.Run();