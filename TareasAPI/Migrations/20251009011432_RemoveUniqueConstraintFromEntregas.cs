using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class RemoveUniqueConstraintFromEntregas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // First, create a new non-unique index with a different name
            migrationBuilder.CreateIndex(
                name: "IX_Entregas_TareaId_AlumnoId_New",
                table: "Entregas",
                columns: new[] { "TareaId", "AlumnoId" });

            // Then drop the unique index (MySQL will allow this since we have the new index)
            migrationBuilder.DropIndex(
                name: "IX_Entregas_TareaId_AlumnoId",
                table: "Entregas");

            // Finally, rename the new index to the original name
            migrationBuilder.Sql("ALTER TABLE `Entregas` RENAME INDEX `IX_Entregas_TareaId_AlumnoId_New` TO `IX_Entregas_TareaId_AlumnoId`");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Entregas_TareaId_AlumnoId",
                table: "Entregas");

            migrationBuilder.CreateIndex(
                name: "IX_Entregas_TareaId_AlumnoId",
                table: "Entregas",
                columns: new[] { "TareaId", "AlumnoId" },
                unique: true);
        }
    }
}
