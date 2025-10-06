using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class CorregirLlaveForaneaTareaUsuario : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tareas_Usuarios_nombre_usuario",
                table: "Tareas");

            migrationBuilder.RenameColumn(
                name: "nombre_usuario",
                table: "Tareas",
                newName: "UsuarioId");

            migrationBuilder.RenameIndex(
                name: "IX_Tareas_nombre_usuario",
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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tareas_Usuarios_UsuarioId",
                table: "Tareas");

            migrationBuilder.RenameColumn(
                name: "UsuarioId",
                table: "Tareas",
                newName: "nombre_usuario");

            migrationBuilder.RenameIndex(
                name: "IX_Tareas_UsuarioId",
                table: "Tareas",
                newName: "IX_Tareas_nombre_usuario");

            migrationBuilder.AddForeignKey(
                name: "FK_Tareas_Usuarios_nombre_usuario",
                table: "Tareas",
                column: "nombre_usuario",
                principalTable: "Usuarios",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
