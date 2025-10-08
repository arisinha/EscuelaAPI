using Microsoft.EntityFrameworkCore;
using TareasApi.Models;

namespace TareasApi.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Tarea> Tareas { get; set; }
    public DbSet<Materia> Materias { get; set; }
    public DbSet<UsuarioMateria> UsuarioMaterias { get; set; }

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

            entity.HasMany(u => u.MateriasImpartidas)
                  .WithOne(m => m.Maestro)
                  .HasForeignKey(m => m.MaestroId)
                  .OnDelete(DeleteBehavior.Restrict);
        });
        
        modelBuilder.Entity<Tarea>(entity =>
        {
            entity.ToTable("Tareas");
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Titulo).IsRequired().HasMaxLength(200);
            entity.Property(t => t.Descripcion).HasMaxLength(500);
            entity.Property(t => t.Estado).HasConversion<int>().IsRequired();
            entity.Property(t => t.FechaCreacion).HasColumnType("datetime").IsRequired();
            entity.Property(t => t.FechaActualizacion).HasColumnType("datetime");

            entity.HasOne(t => t.Usuario)
                .WithMany(u => u.Tareas)
                .HasForeignKey(t => t.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);
        });
        modelBuilder.Entity<Materia>(entity =>
        {
            entity.ToTable("Materias");
            entity.HasKey(m => m.Id);
            entity.Property(m => m.Nombre).IsRequired().HasMaxLength(100);
            entity.Property(m => m.Descripcion).HasMaxLength(200);
        });

        modelBuilder.Entity<UsuarioMateria>()
            .HasKey(um => new { um.UsuarioId, um.MateriaId });

        modelBuilder.Entity<UsuarioMateria>()
            .HasOne(um => um.Usuario)
            .WithMany(u => u.MateriasInscritas)
            .HasForeignKey(um => um.UsuarioId);

        modelBuilder.Entity<UsuarioMateria>()
            .HasOne(um => um.Materia)
            .WithMany(m => m.AlumnosInscritos)
            .HasForeignKey(um => um.MateriaId);
    }
}