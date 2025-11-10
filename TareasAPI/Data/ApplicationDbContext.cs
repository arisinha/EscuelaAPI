using Microsoft.EntityFrameworkCore;
using TareasApi.Models;

namespace TareasApi.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Tarea> Tareas { get; set; }
    public DbSet<Grupo> Grupos { get; set; }
    public DbSet<Entrega> Entregas { get; set; }
    public DbSet<Asistencia> Asistencias { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.ToTable("Usuarios");
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.NombreUsuario).IsUnique();

            entity.Property(u => u.NombreUsuario).IsRequired().HasMaxLength(50).HasColumnName("nombre_usuario");
            entity.Property(u => u.NombreCompleto).IsRequired().HasMaxLength(150).HasColumnName("nombre_completo");
            entity.Property(u => u.PasswordHash).IsRequired().HasColumnName("contrasena");
        });
        
        modelBuilder.Entity<Tarea>(entity =>
        {
            entity.ToTable("Tareas");
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Titulo).IsRequired().HasMaxLength(200);
            entity.Property(t => t.Descripcion).HasMaxLength(500);
            entity.Property(t => t.Estado).HasConversion<int>().IsRequired();
            entity.Property(t => t.FechaCreacion).HasColumnType("datetime").IsRequired();
            // Store DateTimeOffset as UTC DateTime in database to avoid schema changes
            entity.Property(t => t.FechaCreacion)
                  .HasConversion(
                      v => v.UtcDateTime,
                      v => DateTime.SpecifyKind(v, DateTimeKind.Utc));
            entity.Property(t => t.FechaActualizacion).HasColumnType("datetime")
                  .HasConversion(
                      v => v.HasValue ? v.Value.UtcDateTime : (DateTime?)null,
                      v => v.HasValue ? DateTime.SpecifyKind(v.Value, DateTimeKind.Utc) : (DateTime?)null);

            entity.HasOne(t => t.Usuario)
                .WithMany(u => u.Tareas)
                .HasForeignKey(t => t.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            // Optional relationship to Grupo
            entity.HasOne<Grupo>()
                .WithMany()
                .HasForeignKey(t => t.GrupoId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Grupo>(entity =>
        {
            entity.ToTable("Grupos");
            entity.HasKey(g => g.Id);
            entity.Property(g => g.NombreMateria).IsRequired().HasMaxLength(200).HasColumnName("nombre_materia");
            entity.Property(g => g.CodigoGrupo).IsRequired().HasMaxLength(100).HasColumnName("codigo_grupo");
            
            // Configurar relación muchos a muchos con Usuario
            entity.HasMany(g => g.Miembros)
                .WithMany(u => u.Grupos)
                .UsingEntity<Dictionary<string, object>>(
                    "GrupoUsuario",
                    j => j.HasOne<Usuario>().WithMany().HasForeignKey("UsuarioId").OnDelete(DeleteBehavior.Cascade),
                    j => j.HasOne<Grupo>().WithMany().HasForeignKey("GrupoId").OnDelete(DeleteBehavior.Cascade),
                    j =>
                    {
                        j.HasKey("GrupoId", "UsuarioId");
                        j.ToTable("GrupoUsuarios");
                    }
                );
        });

        modelBuilder.Entity<Entrega>(entity =>
        {
            entity.ToTable("Entregas");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Comentario).HasMaxLength(500);
            entity.Property(e => e.NombreArchivo).IsRequired().HasMaxLength(255);
            entity.Property(e => e.RutaArchivo).IsRequired().HasMaxLength(500);
            entity.Property(e => e.TipoArchivo).HasMaxLength(50);
            entity.Property(e => e.FechaEntrega).HasColumnType("datetime").IsRequired();

            // Store DateTimeOffset as UTC DateTime in database
            entity.Property(e => e.FechaEntrega)
                  .HasConversion(
                      v => v.UtcDateTime,
                      v => DateTime.SpecifyKind(v, DateTimeKind.Utc));

            // Foreign key relationships
            entity.HasOne(e => e.Tarea)
                .WithMany()
                .HasForeignKey(e => e.TareaId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Alumno)
                .WithMany()
                .HasForeignKey(e => e.AlumnoId)
                .OnDelete(DeleteBehavior.Cascade);

            // Index for better performance (not unique to allow multiple deliveries per student per task)
            entity.HasIndex(e => new { e.TareaId, e.AlumnoId })
                .HasDatabaseName("IX_Entregas_TareaId_AlumnoId");
        });

        modelBuilder.Entity<Asistencia>(entity =>
        {
            entity.ToTable("Asistencias");
            entity.HasKey(a => a.Id);

            entity.Property(a => a.Fecha).HasColumnType("datetime").IsRequired();
            // Store DateTime as UTC
            entity.Property(a => a.Fecha)
                  .HasConversion(
                      v => v.ToUniversalTime(),
                      v => DateTime.SpecifyKind(v, DateTimeKind.Utc));

            entity.Property(a => a.Observaciones).HasMaxLength(500);

            entity.Property(a => a.Estado).HasConversion<int>().IsRequired();

            entity.HasOne(a => a.Usuario)
                .WithMany()
                .HasForeignKey(a => a.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.Grupo)
                .WithMany()
                .HasForeignKey(a => a.GrupoId)
                .OnDelete(DeleteBehavior.Cascade);

            // Index for queries by group and date
            entity.HasIndex(a => new { a.GrupoId, a.Fecha }).HasDatabaseName("IX_Asistencias_GrupoId_Fecha");
        });
    }
}