using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddGrupoAndGrupoId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "GrupoId",
                table: "Tareas",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GrupoId",
                table: "Tareas");
        }
    }
}
