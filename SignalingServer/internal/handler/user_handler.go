package handler

import (
	"net/http"
	"quickdesk/signaling/internal/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// UserHandler 用户管理处理器
type UserHandler struct {
	db *gorm.DB
}

// NewUserHandler 创建用户管理处理器
func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{db: db}
}

// GetUsers 获取用户列表
func (h *UserHandler) GetUsers(c *gin.Context) {
	var users []models.User
	result := h.db.Find(&users)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req struct {
		Username    string `json:"username" binding:"required"`
		Phone       string `json:"phone"`
		Email       string `json:"email"`
		Password    string `json:"password" binding:"required"`
		Level       string `json:"level"`
		ChannelType string `json:"channelType"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户名是否已存在
	var existingUser models.User
	if result := h.db.Where("username = ?", req.Username).First(&existingUser); result.Error == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户名已存在"})
		return
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
		return
	}

	// 设置默认值
	level := req.Level
	if level == "" {
		level = "V1"
	}
	channelType := req.ChannelType
	if channelType == "" {
		channelType = "全球"
	}

	user := models.User{
		Username:    req.Username,
		Phone:       req.Phone,
		Email:       req.Email,
		Password:    string(hashedPassword),
		Level:       level,
		ChannelType: channelType,
		Status:      true,
	}

	if result := h.db.Create(&user); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "用户创建成功", "user": user})
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if result := h.db.First(&user, id); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	var req struct {
		Username    string `json:"username"`
		Phone       string `json:"phone"`
		Email       string `json:"email"`
		Password    string `json:"password"`
		Level       string `json:"level"`
		DeviceCount int    `json:"deviceCount"`
		ChannelType string `json:"channelType"`
		Status      *bool  `json:"status"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 更新字段
	if req.Username != "" {
		user.Username = req.Username
	}
	if req.Phone != "" {
		user.Phone = req.Phone
	}
	if req.Email != "" {
		user.Email = req.Email
	}
	if req.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
			return
		}
		user.Password = string(hashedPassword)
	}
	if req.Level != "" {
		user.Level = req.Level
	}
	if req.ChannelType != "" {
		user.ChannelType = req.ChannelType
	}
	if req.Status != nil {
		user.Status = *req.Status
	}
	user.DeviceCount = req.DeviceCount

	if result := h.db.Save(&user); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "用户更新成功", "user": user})
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	id := c.Param("id")
	if result := h.db.Delete(&models.User{}, id); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "用户删除成功"})
}

// GetUser 获取单个用户
func (h *UserHandler) GetUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if result := h.db.First(&user, id); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}
	c.JSON(http.StatusOK, user)
}

// UpdateUserDeviceCount 更新用户设备数量
func (h *UserHandler) UpdateUserDeviceCount(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		DeviceCount int `json:"deviceCount"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if result := h.db.Model(&models.User{}).Where("id = ?", id).Update("device_count", req.DeviceCount); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "设备数量更新成功"})
}
