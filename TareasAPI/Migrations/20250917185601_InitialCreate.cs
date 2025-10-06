using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tareas_Usuarios_UsuarioId",
                table: "Tareas");

            migrationBuilder.RenameColumn(
                name: "UsuarioId",
                table: "Tareas",
                newName: "usuario_id");

            migrationBuilder.RenameIndex(
                name: "IX_Tareas_UsuarioId",
                table: "Tareas",
                newName: "IX_Tareas_usuario_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tareas_Usuarios_usuario_id",
                table: "Tareas",
                column: "usuario_id",
                principalTable: "Usuarios",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tareas_Usuarios_usuario_id",
                table: "Tareas");

            migrationBuilder.RenameColumn(
                name: "usuario_id",
                table: "Tareas",
                newName: "UsuarioId");

            migrationBuilder.RenameIndex(
                name: "IX_Tareas_usuario_id",
                table: "Tareas",
                newName: "IX_Tareas_UsuarioId");

            migrationBuilder.AddForeignKey(
                name: "FK_Tareas_Usuarios_UsuarioId",
                table: "Tareas",
                column: "UsuarioId",
                principalTable: "Usuarios",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
