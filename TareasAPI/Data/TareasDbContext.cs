using Microsoft.EntityFrameworkCore;
using TareasApi.Models;

namespace TareasApi.Data
{
    public class TareasDbContext : DbContext
    {
        public TareasDbContext(DbContextOptions<TareasDbContext> options) : base(options)
        {
        }

        public DbSet<Tarea> Tareas { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            modelBuilder.Entity<Tarea>(entity =>
            {
                entity.ToTable("Tareas");
                
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.Id)
                    .HasColumnName("Id")
                    .ValueGeneratedOnAdd();

                entity.Property(e => e.Titulo)
                    .HasColumnName("Titulo")
                    .HasMaxLength(200)
                    .IsRequired();

                entity.Property(e => e.Descripcion)
                    .HasColumnName("Descripcion")
                    .HasMaxLength(500)
                    .IsRequired(false);

                entity.Property(e => e.Estado)
                    .HasColumnName("Estado")
                    .HasConversion<int>()
                    .IsRequired();

                entity.Property(e => e.FechaCreacion)
                    .HasColumnName("FechaCreacion")
                    .HasColumnType("datetime")
                    .IsRequired();

                entity.Property(e => e.FechaActualizacion)
                    .HasColumnName("FechaActualizacion")
                    .HasColumnType("datetime")
                    .IsRequired(false);
            });
            
            modelBuilder.Entity<Tarea>().HasData(
                new Tarea
                {
                    Id = 1,
                    Titulo = "Tarea de ejemplo",
                    Descripcion = "Esta es una tarea de ejemplo",
                    Estado = EstadoTarea.Pendiente,
                    FechaCreacion = DateTime.UtcNow
                }
            );
        }
    }
}