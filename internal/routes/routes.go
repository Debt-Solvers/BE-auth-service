package routes

import (
	"github.com/Debt-Solvers/BE-auth-service/internal/controller"
	"github.com/Debt-Solvers/BE-auth-service/internal/middleware"
	"github.com/Debt-Solvers/BE-auth-service/internal/tests"

	"github.com/gin-gonic/gin"
)

// Add the health check route to your main router
func AddHealthCheckRoute(server *gin.Engine) {
	server.GET("/health", tests.HealthCheck)
}


func RegisterRoutes(server *gin.Engine) {
	// Public routes
	server.POST("/api/v1/signup", controller.Signup) // User signup - No middleware needed
	server.POST("/api/v1/login", controller.Login)     // User login - No middleware needed
	server.POST("/api/v1/password-reset", controller.ResetPassword) // Request password reset - No middleware needed
	server.POST("/api/v1/password-reset/confirm", controller.ConfirmResetPassword) // Confirm password reset - No middleware needed

	// Protected routes (requires authentication)
	protected := server.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware()) // Apply middleware to all routes in this group
	protected.POST("/logout", controller.Logout)   

	protected.PUT("/change-password", controller.UpdatePassword)                        
	protected.PUT("/user/update", controller.UpdateUserInfo)            
	protected.GET("/user", controller.GetUserInfo)                  
}

