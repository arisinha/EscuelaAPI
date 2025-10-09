using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TareasAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddGradingSystemToEntregas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "Calificacion",
                table: "Entregas",
                type: "decimal(65,30)",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "FechaCalificacion",
                table: "Entregas",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProfesorId",
                table: "Entregas",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RetroalimentacionProfesor",
                table: "Entregas",
                type: "varchar(1000)",
                maxLength: 1000,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Entregas_ProfesorId",
                table: "Entregas",
                column: "ProfesorId");

            migrationBuilder.AddForeignKey(
                name: "FK_Entregas_Usuarios_ProfesorId",
                table: "Entregas",
                column: "ProfesorId",
                principalTable: "Usuarios",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Entregas_Usuarios_ProfesorId",
                table: "Entregas");

            migrationBuilder.DropIndex(
                name: "IX_Entregas_ProfesorId",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Calificacion",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "FechaCalificacion",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "ProfesorId",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "RetroalimentacionProfesor",
                table: "Entregas");
        }
    }
}
