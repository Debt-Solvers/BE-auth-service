package main

import (
	"auth-service/db"
	"auth-service/internal/routes"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)


func main() {
	// Initialize database connection
	if err := db.ConnectDatabase(); err != nil {
		log.Fatalf("Database connection error: %v", err)
	}

	// Execute Schema
	if err:= db.ExecuteSQLSchema("./db/schema.sql"); err != nil {
		log.Fatalf("Error executing schema: %v", err)
	}

	// Initialize Gin engine
	server := gin.Default()
	
	// Register routes
	routes.RegisterRoutes(server)

	// Check for environment Variable port
	port:= os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start th server
	if err := server.Run(":" + port); err != nil {
		log.Fatalf("Failed to start the server: %v", err)
	}
}