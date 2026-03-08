package handler

import (
	"net/http"
	"quickdesk/signaling/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SettingsHandler 设置处理器
type SettingsHandler struct {
	db *gorm.DB
}

// NewSettingsHandler 创建设置处理器
func NewSettingsHandler(db *gorm.DB) *SettingsHandler {
	return &SettingsHandler{db: db}
}

// GetSettings 获取系统设置
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	var settings models.Settings
	result := h.db.First(&settings)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			// 返回默认设置
			c.JSON(http.StatusOK, gin.H{
				"siteEnabled": true,
				"siteName":    "QuickDesk",
				"loginLogo":   "",
				"smallLogo":   "",
				"favicon":     "",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateSettings 更新系统设置
func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	var settings models.Settings
	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查是否已存在设置记录
	var existing models.Settings
	result := h.db.First(&existing)

	if result.Error != nil && result.Error != gorm.ErrRecordNotFound {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	if result.Error == gorm.ErrRecordNotFound {
		// 创建新记录
		if err := h.db.Create(&settings).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else {
		// 更新现有记录
		settings.ID = existing.ID
		if err := h.db.Save(&settings).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, settings)
}
