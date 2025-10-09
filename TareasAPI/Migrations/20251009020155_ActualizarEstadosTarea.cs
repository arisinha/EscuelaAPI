using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class ActualizarEstadosTarea : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Actualizar estados existentes de tareas
            // Pendiente (0) y EnProgreso (1) -> Abierto (0)  
            // Completada (2) y Cancelada (3) -> Cerrado (1)
            
            migrationBuilder.Sql(@"
                UPDATE Tareas SET Estado = 0 WHERE Estado IN (0, 1);
                UPDATE Tareas SET Estado = 1 WHERE Estado IN (2, 3);
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No es posible revertir con precisión los estados anteriores
            // Se asignarán todos a Pendiente por defecto
            migrationBuilder.Sql(@"
                UPDATE Tareas SET Estado = 0;
            ");
        }
    }
}
