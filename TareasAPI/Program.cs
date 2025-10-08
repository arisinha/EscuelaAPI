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

        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var loggerFactory = context.HttpContext.RequestServices.GetService(typeof(ILoggerFactory)) as ILoggerFactory;
                var logger = loggerFactory?.CreateLogger("JwtAuth");
                var auth = context.Request.Headers["Authorization"].ToString();
                if (string.IsNullOrEmpty(auth))
                {
                    logger?.LogWarning("OnMessageReceived: no Authorization header for {Path}", context.Request.Path);
                }
                else
                {
                    var preview = auth.Length > 80 ? auth.Substring(0, 80) + "..." : auth;
                    logger?.LogInformation("OnMessageReceived: Authorization header for {Path} -> {Auth}", context.Request.Path, preview);
                }
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var loggerFactory = context.HttpContext.RequestServices.GetService(typeof(ILoggerFactory)) as ILoggerFactory;
                var logger = loggerFactory?.CreateLogger("JwtAuth");
                // Diagnostic: log token type, issuer and audiences when available. Avoid failing here;
                // TokenValidationParameters already enforces issuer/audience/lifetime/signing key.
                try
                {
                    if (context.SecurityToken is JwtSecurityToken jwtToken)
                    {
                        logger?.LogInformation("OnTokenValidated: token issuer={issuer}, audiences={aud}", jwtToken.Issuer, string.Join(',', jwtToken.Audiences));
                    }
                    else
                    {
                        logger?.LogInformation("OnTokenValidated: SecurityToken is of type {Type}", context.SecurityToken?.GetType()?.FullName ?? "(null)");
                    }
                }
                catch (Exception ex)
                {
                    logger?.LogError(ex, "Error while logging token info in OnTokenValidated");
                }

                return Task.CompletedTask;
            },
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

                    var payload = JsonSerializer.Serialize(new
                    {
                        success = false,
                        error,
                        message
                    });

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
app.Run();