package handler

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

// RegisterWebClientUI serves the WebClient static files from filesystem.
func RegisterWebClientUI(router *gin.Engine) {
	// Try to find WebClient directory
	webClientPaths := []string{
		"web/src/WebClient",                         // Relative to cmd/signaling (开发环境)
		"../web/src/WebClient",                      // Relative to cmd/signaling
		"../../web/src/WebClient",                   // Relative to executable
		"WebClient",                                 // Same directory
		"E:/EXD/QuickDesk-er/QuickDesk/QuickDesk/SignalingServer/web/src/WebClient", // Absolute path
	}

	var webClientPath string
	for _, path := range webClientPaths {
		if _, err := os.Stat(path); err == nil {
			// Check if remote.html exists in this directory
			if _, err := os.Stat(filepath.Join(path, "remote.html")); err == nil {
				webClientPath = path
				break
			}
		}
	}

	if webClientPath == "" {
		// WebClient not found, log warning but don't fail
		router.GET("/remote.html", func(c *gin.Context) {
			c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(`
<!DOCTYPE html>
<html>
<head><title>QuickDesk Remote</title></head>
<body>
<h1>WebClient Not Found</h1>
<p>Please ensure WebClient files are available.</p>
</body>
</html>`))
		})
		return
	}

	// Create file server for WebClient directory
	fileServer := http.FileServer(http.Dir(webClientPath))

	// Handle specific WebClient HTML files
	htmlFiles := []string{"remote.html", "login.html", "register.html", "user-login.html", "index.html"}
	for _, file := range htmlFiles {
		filePath := filepath.Join(webClientPath, file)
		if _, err := os.Stat(filePath); err == nil {
			// File exists, register route
			routePath := "/" + file
			router.GET(routePath, func(c *gin.Context) {
				// Re-read file on each request to support hot reload during development
				data, err := os.ReadFile(filePath)
				if err != nil {
					c.String(http.StatusInternalServerError, "Error reading file: "+err.Error())
					return
				}
				c.Data(http.StatusOK, "text/html; charset=utf-8", data)
			})
		}
	}

	// Serve static files from js/ directory
	router.GET("/js/*filepath", func(c *gin.Context) {
		path := strings.TrimPrefix(c.Param("filepath"), "/")
		fullPath := filepath.Join(webClientPath, "js", path)

		// Security check: ensure path is within js directory
		if !strings.HasPrefix(fullPath, filepath.Join(webClientPath, "js")) {
			c.String(http.StatusForbidden, "Access denied")
			return
		}

		data, err := os.ReadFile(fullPath)
		if err != nil {
			c.String(http.StatusNotFound, "File not found: "+path)
			return
		}

		// Set content type based on file extension
		contentType := "application/javascript"
		if strings.HasSuffix(path, ".css") {
			contentType = "text/css"
		} else if strings.HasSuffix(path, ".html") {
			contentType = "text/html"
		} else if strings.HasSuffix(path, ".json") {
			contentType = "application/json"
		}

		c.Data(http.StatusOK, contentType, data)
	})

	// Serve static files from images/ directory
	router.GET("/images/*filepath", func(c *gin.Context) {
		path := strings.TrimPrefix(c.Param("filepath"), "/")
		fullPath := filepath.Join(webClientPath, "images", path)

		// Security check
		if !strings.HasPrefix(fullPath, filepath.Join(webClientPath, "images")) {
			c.String(http.StatusForbidden, "Access denied")
			return
		}

		data, err := os.ReadFile(fullPath)
		if err != nil {
			c.String(http.StatusNotFound, "File not found: "+path)
			return
		}

		// Set content type based on file extension
		contentType := "image/png"
		if strings.HasSuffix(path, ".jpg") || strings.HasSuffix(path, ".jpeg") {
			contentType = "image/jpeg"
		} else if strings.HasSuffix(path, ".gif") {
			contentType = "image/gif"
		} else if strings.HasSuffix(path, ".svg") {
			contentType = "image/svg+xml"
		} else if strings.HasSuffix(path, ".ico") {
			contentType = "image/x-icon"
		}

		c.Data(http.StatusOK, contentType, data)
	})

	// Serve favicon.ico
	router.GET("/favicon.ico", func(c *gin.Context) {
		faviconPath := filepath.Join(webClientPath, "favicon.ico")
		data, err := os.ReadFile(faviconPath)
		if err != nil {
			c.String(http.StatusNotFound, "favicon.ico not found")
			return
		}
		c.Data(http.StatusOK, "image/x-icon", data)
	})

	// Serve other static files (CSS, etc.)
	router.GET("/assets/*filepath", func(c *gin.Context) {
		path := strings.TrimPrefix(c.Param("filepath"), "/")
		fullPath := filepath.Join(webClientPath, "assets", path)

		data, err := os.ReadFile(fullPath)
		if err != nil {
			c.String(http.StatusNotFound, "File not found: "+path)
			return
		}

		// Set content type
		contentType := "application/octet-stream"
		if strings.HasSuffix(path, ".css") {
			contentType = "text/css"
		} else if strings.HasSuffix(path, ".js") {
			contentType = "application/javascript"
		}

		c.Data(http.StatusOK, contentType, data)
	})

	// Use file server for any other requests
	_ = fileServer
}
