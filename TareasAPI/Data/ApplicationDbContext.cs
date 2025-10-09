using Microsoft.EntityFrameworkCore;
using TareasApi.Models;

namespace TareasApi.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Tarea> Tareas { get; set; }
    public DbSet<Grupo> Grupos { get; set; }
    public DbSet<Entrega> Entregas { get; set; }

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

            // Unique constraint: one delivery per student per task
            entity.HasIndex(e => new { e.TareaId, e.AlumnoId })
                .IsUnique()
                .HasDatabaseName("IX_Entregas_TareaId_AlumnoId");
        });
    }
}