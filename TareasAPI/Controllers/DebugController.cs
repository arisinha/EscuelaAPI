using System;
using System.Linq;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;

namespace TareasApi.Controllers;

[ApiController]
[Route("debug")]
public class DebugController : ControllerBase
{
    private readonly IConfiguration _config;

    public DebugController(IConfiguration config)
    {
        _config = config;
    }

    public class ValidateRequest
    {
        public string? token { get; set; }
    }

    [HttpPost("validate-token")]
    [AllowAnonymous]
    public IActionResult ValidateToken([FromBody] ValidateRequest? req)
    {
        var token = req?.token;

        // Fallback to Authorization header if no token in body
        if (string.IsNullOrWhiteSpace(token))
        {
            var auth = Request.Headers["Authorization"].FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(auth) && auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                token = auth.Substring("Bearer ".Length).Trim();
            }
        }

        if (string.IsNullOrWhiteSpace(token))
        {
            return BadRequest(new { success = false, message = "Token not provided" });
        }

        var key = _config["Jwt:Key"];
        var issuer = _config["Jwt:Issuer"];
        var audience = _config["Jwt:Audience"];

        var tokenHandler = new JwtSecurityTokenHandler();
        var validationParams = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = issuer,
            ValidAudience = audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key!)),
            ClockSkew = TimeSpan.Zero
        };

        try
        {
            var principal = tokenHandler.ValidateToken(token, validationParams, out var validatedToken);
            var jwt = validatedToken as JwtSecurityToken;
            var claims = principal.Claims.ToDictionary(c => c.Type, c => c.Value);

            return Ok(new { success = true, payload = claims });
        }
        catch (Exception ex)
        {
            var exType = ex.GetType().Name;
            var message = ex.Message;

            object? payload = null;
            try
            {
                var parts = token.Split('.');
                if (parts.Length >= 2)
                {
                    var p = parts[1];
                    var pad = new string('=', (4 - p.Length % 4) % 4);
                    var bytes = Convert.FromBase64String(p + pad);
                    var json = Encoding.UTF8.GetString(bytes);
                    payload = System.Text.Json.JsonSerializer.Deserialize<object>(json);
                }
            }
            catch { /* ignore decode errors */ }

            return BadRequest(new { success = false, error = exType, message, payload });
        }
    }
}
