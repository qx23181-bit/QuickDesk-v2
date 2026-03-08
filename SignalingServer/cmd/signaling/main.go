package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	signaling "quickdesk/signaling"
	"quickdesk/signaling/internal/config"
	"quickdesk/signaling/internal/database"
	"quickdesk/signaling/internal/handler"
	"quickdesk/signaling/internal/middleware"
	"quickdesk/signaling/internal/models"
	"quickdesk/signaling/internal/repository"
	"quickdesk/signaling/internal/service"
)

func main() {
	log.Println("Starting QuickDesk Signaling Server...")

	// Load configuration
	cfg := config.Load()

	// Initialize databases
	log.Println("Connecting to databases...")
	db := database.InitPostgreSQL(cfg)
	redisClient := database.InitRedis(cfg)

	// Auto-migrate models
	log.Println("Running database migrations...")
	if err := db.AutoMigrate(&models.Device{}, &models.Preset{}, &models.AdminUser{}, &models.Settings{}, &models.User{}, &models.UserDevice{}, &models.UserDeviceLog{}, &models.ConnectionHistory{}); err != nil {
		log.Printf("Warning: migration error (continuing anyway): %v", err)
	}

	// Initialize repositories
	deviceRepo := repository.NewDeviceRepository(db)
	presetRepo := repository.NewPresetRepository(db)
	adminUserRepo := repository.NewAdminUserRepository(db)

	// Initialize services
	deviceService := service.NewDeviceService(deviceRepo, redisClient)
	authService := service.NewAuthService(redisClient)
	presetService := service.NewPresetService(presetRepo)
	adminUserService := service.NewAdminUserService(adminUserRepo)

	// Create initial admin user if not exists
	ctx := context.Background()
	_, err := adminUserRepo.GetByUsername(ctx, "admin")
	if err != nil {
		log.Println("Creating initial admin user...")
		initialAdmin := &models.AdminUser{
			Username: "admin",
			Password: "admin123",
			Email:    "admin@quickdesk.com",
			Role:     "super_admin",
			Status:   true,
		}

		hashedPassword, err := service.HashPassword(initialAdmin.Password)
		if err != nil {
			log.Fatalf("Failed to hash initial admin password: %v", err)
		}
		initialAdmin.Password = hashedPassword

		if err := adminUserRepo.Create(ctx, initialAdmin); err != nil {
			log.Fatalf("Failed to create initial admin user: %v", err)
		}
		log.Println("Initial admin user created successfully")
	}

	// Initialize handlers
	apiHandler := handler.NewAPIHandler(deviceService, authService, presetService, cfg)
	wsHandler := handler.NewWSHandler(deviceService, authService)

	// Set WSHandler reference for API handler (needed for online status checks)
	apiHandler.SetWSHandler(wsHandler)

	// Create Gin router
	gin.SetMode(gin.DebugMode)
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.LoggerMiddleware())
	router.Use(middleware.CORSMiddleware(cfg.Security.AllowedOrigins))

	// API Key authentication middleware
	apiKeyAuth := middleware.NewAPIKeyAuth(cfg.Security.APIKey, cfg.Security.AllowedOrigins)

	// Health check endpoint (no API key required)
	router.GET("/health", apiHandler.HealthCheck)

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Preset is public so old clients (without API key) can still
		// fetch min_version and show the force-upgrade prompt.
		v1.GET("/preset", apiHandler.GetPreset)

		// Client-facing APIs require API key
		clientAPI := v1.Group("")
		clientAPI.Use(apiKeyAuth.Required())
		{
			clientAPI.POST("/devices/register", apiHandler.RegisterDevice)
			clientAPI.GET("/devices/:device_id", apiHandler.GetDevice)
			clientAPI.GET("/devices/:device_id/status", apiHandler.GetDeviceStatus)
			clientAPI.POST("/auth/verify", apiHandler.VerifyPassword)
			clientAPI.GET("/ice-config", apiHandler.GetIceConfig)
		}

		// User authentication (public, no API key required)
		userAuth := handler.NewUserAuth(db)
		go userAuth.CleanupLoop()
		v1.POST("/user/register", userAuth.Register)
		v1.POST("/user/login", userAuth.Login)

		// User device binding APIs (需要用户登录)
		userDeviceHandler := handler.NewUserDeviceHandler(db)
		userAPI := v1.Group("/user")
		userAPI.Use(userAuth.AuthRequired())
		{
			userAPI.GET("/devices", func(c *gin.Context) {
				// 从token获取用户ID
				userID := userAuth.GetUserIDFromToken(c)
				if userID == 0 {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "无法获取用户信息"})
					return
				}
				// 调用GetUserDevices接口
				c.Request.URL.RawQuery = "user_id=" + fmt.Sprintf("%d", userID)
				userDeviceHandler.GetUserDevices(c)
			})
			userAPI.POST("/devices/bind", userDeviceHandler.BindDevice)
			userAPI.POST("/devices/unbind", userDeviceHandler.UnbindDevice)
			userAPI.POST("/devices/quick-connect", userDeviceHandler.QuickConnectBind)
			userAPI.GET("/devices/check", userDeviceHandler.CheckDeviceBinding)
			userAPI.POST("/devices/record", userDeviceHandler.RecordConnection)
			userAPI.GET("/devices/logs", func(c *gin.Context) {
				// 从token获取用户ID
				userID := userAuth.GetUserIDFromToken(c)
				if userID == 0 {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "无法获取用户信息"})
					return
				}
				// 调用GetUserDeviceLogs接口
				c.Request.URL.RawQuery = "user_id=" + fmt.Sprintf("%d", userID)
				userDeviceHandler.GetUserDeviceLogs(c)
			})
		}

		// Admin authentication
		adminAuth := middleware.NewAdminAuth(adminUserService)
		v1.POST("/admin/login", adminAuth.Login)

		// Public settings API (no auth required for reading)
		settingsHandler := handler.NewSettingsHandler(db)
		v1.GET("/settings", settingsHandler.GetSettings)

		// Admin API (requires admin token, no API key needed)
		admin := v1.Group("/admin")
		admin.Use(adminAuth.AuthRequired())
		{
			admin.GET("/preset", apiHandler.GetAdminPreset)
			admin.PUT("/preset", apiHandler.UpdateAdminPreset)
			admin.GET("/stats", apiHandler.GetAdminStats)
			admin.GET("/system/status", apiHandler.GetSystemStatus)
			admin.GET("/connections", apiHandler.GetConnectionStatus)
			admin.GET("/activity", apiHandler.GetActivity)
			admin.GET("/devices", apiHandler.GetAdminDevices)

			// Admin user management
			adminUserHandler := handler.NewAdminUserHandler(adminUserService)
			admin.GET("/users", adminUserHandler.GetAdminUsers)
			admin.POST("/users", adminUserHandler.CreateAdminUser)
			admin.PUT("/users/:id", adminUserHandler.UpdateAdminUser)
			admin.DELETE("/users/:id", adminUserHandler.DeleteAdminUser)

			// User management (普通用户管理)
			userHandler := handler.NewUserHandler(db)
			admin.GET("/user-list", userHandler.GetUsers)
			admin.GET("/user-list/:id", userHandler.GetUser)
			admin.POST("/user-list", userHandler.CreateUser)
			admin.PUT("/user-list/:id", userHandler.UpdateUser)
			admin.DELETE("/user-list/:id", userHandler.DeleteUser)
			admin.PUT("/user-list/:id/device-count", userHandler.UpdateUserDeviceCount)

			// User device binding management (用户设备绑定管理)
			userDeviceHandler := handler.NewUserDeviceHandler(db)
			admin.GET("/user-devices", userDeviceHandler.GetAllBindings)
			admin.GET("/user-devices/user/:user_id", userDeviceHandler.GetUserDevices)
			admin.GET("/user-devices/device/:device_id", userDeviceHandler.GetDeviceUsers)
			admin.POST("/user-devices/bind", userDeviceHandler.BindDevice)
			admin.POST("/user-devices/unbind", userDeviceHandler.UnbindDevice)
			admin.PUT("/user-devices/name", userDeviceHandler.UpdateDeviceName)
			admin.GET("/user-devices/logs/:user_id", userDeviceHandler.GetUserDeviceLogs)

			// Settings management (update requires auth)
			admin.POST("/settings", settingsHandler.UpdateSettings)
		}
	}

	// WebSocket routes (API key checked inside handler before upgrade)
	wsHandler.SetAPIKeyAuth(apiKeyAuth)
	router.GET("/signal/:device_id", wsHandler.HandleWebSocket)

	// Legacy route for backward compatibility with existing tests
	router.GET("/host/:device_id", wsHandler.HandleWebSocket)
	router.GET("/client/:device_id/:access_code", func(c *gin.Context) {
		// Extract access_code from path
		accessCode := c.Param("access_code")

		// Set access_code as query parameter
		c.Request.URL.RawQuery = fmt.Sprintf("access_code=%s", accessCode)

		// Forward to standard WebSocket handler
		wsHandler.HandleWebSocket(c)
	})

	// Root path redirect to admin
	router.GET("/", func(c *gin.Context) {
		c.Redirect(302, "/admin/")
	})

	// Admin UI (embedded Vue frontend)
	handler.RegisterAdminUI(router, signaling.WebDistFS)

	// WebClient static files (remote.html, etc.)
	handler.RegisterWebClientUI(router)

	// Start server
	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)
	log.Printf("Server starting on %s", addr)
	log.Printf("API: http://%s/api/v1", addr)
	log.Printf("Admin: http://%s/admin/", addr)
	log.Printf("WebSocket: ws://%s/signal/{device_id}?access_code={code}", addr)
	log.Println("Ready to accept connections.")

	if err := router.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
