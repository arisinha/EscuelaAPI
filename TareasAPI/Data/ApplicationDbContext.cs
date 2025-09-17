using Microsoft.EntityFrameworkCore;
using TareasApi.Models;

namespace TareasApi.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Tarea> Tareas { get; set; }

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
            entity.Property(t => t.FechaActualizacion).HasColumnType("datetime");

            entity.HasOne(t => t.Usuario)
                .WithMany(u => u.Tareas)
                .HasForeignKey(t => t.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}