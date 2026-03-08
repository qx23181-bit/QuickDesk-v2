package handler

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"quickdesk/signaling/internal/models"
	"sync"
	"time"

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

// GetUsers 获取用户列表（包含绑定的设备信息）
func (h *UserHandler) GetUsers(c *gin.Context) {
	var users []models.User
	result := h.db.Find(&users)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	// 获取每个用户绑定的设备
	type UserWithDevices struct {
		models.User
		Devices []models.UserDevice `json:"devices"`
	}

	var usersWithDevices []UserWithDevices
	for _, user := range users {
		var devices []models.UserDevice
		h.db.Where("user_id = ? AND status = ?", user.ID, true).Find(&devices)

		usersWithDevices = append(usersWithDevices, UserWithDevices{
			User:    user,
			Devices: devices,
		})
	}

	c.JSON(http.StatusOK, gin.H{"users": usersWithDevices})
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

const userTokenTTL = 7 * 24 * time.Hour

type UserAuth struct {
	db         *gorm.DB
	mu         sync.RWMutex
	tokens     map[string]time.Time
	tokenUsers map[string]uint // token -> user_id mapping
}

func NewUserAuth(db *gorm.DB) *UserAuth {
	return &UserAuth{
		db:         db,
		tokens:     make(map[string]time.Time),
		tokenUsers: make(map[string]uint),
	}
}

func (a *UserAuth) CleanupLoop() {
	ticker := time.NewTicker(time.Hour)
	defer ticker.Stop()
	for range ticker.C {
		a.mu.Lock()
		now := time.Now()
		for t, exp := range a.tokens {
			if now.After(exp) {
				delete(a.tokens, t)
				delete(a.tokenUsers, t)
			}
		}
		a.mu.Unlock()
	}
}

func (a *UserAuth) generateToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func (a *UserAuth) Login(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	var user models.User
	if result := a.db.Where("username = ?", req.Username).First(&user); result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户名或密码错误"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户名或密码错误"})
		return
	}

	if !user.Status {
		c.JSON(http.StatusForbidden, gin.H{"error": "账号已被禁用"})
		return
	}

	token := a.generateToken()
	a.mu.Lock()
	a.tokens[token] = time.Now().Add(userTokenTTL)
	a.tokenUsers[token] = user.ID
	a.mu.Unlock()

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"user": gin.H{
			"id":          user.ID,
			"username":    user.Username,
			"phone":       user.Phone,
			"email":       user.Email,
			"level":       user.Level,
			"deviceCount": user.DeviceCount,
			"channelType": user.ChannelType,
			"status":      user.Status,
			"createdAt":   user.CreatedAt,
			"updatedAt":   user.UpdatedAt,
		},
	})
}

func (a *UserAuth) Register(c *gin.Context) {
	var req struct {
		Username    string `json:"username" binding:"required"`
		Password    string `json:"password" binding:"required"`
		Phone       string `json:"phone"`
		Email       string `json:"email"`
		Level       string `json:"level"`
		ChannelType string `json:"channelType"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	var existingUser models.User
	if result := a.db.Where("username = ?", req.Username).First(&existingUser); result.Error == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户名已存在"})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
		return
	}

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

	if result := a.db.Create(&user); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建用户失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "注册成功",
		"user": gin.H{
			"id":          user.ID,
			"username":    user.Username,
			"phone":       user.Phone,
			"email":       user.Email,
			"level":       user.Level,
			"deviceCount": user.DeviceCount,
			"channelType": user.ChannelType,
			"status":      user.Status,
			"createdAt":   user.CreatedAt,
			"updatedAt":   user.UpdatedAt,
		},
	})
}

func (a *UserAuth) AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := ""
		auth := c.GetHeader("Authorization")
		if len(auth) > 7 && auth[:7] == "Bearer " {
			token = auth[7:]
		}
		if token == "" {
			token = c.Query("token")
		}

		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
			return
		}

		a.mu.RLock()
		expiry, ok := a.tokens[token]
		a.mu.RUnlock()

		if !ok || time.Now().After(expiry) {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token已过期"})
			return
		}

		c.Next()
	}
}

func (a *UserAuth) GetCurrentUser(c *gin.Context) *models.User {
	token := ""
	auth := c.GetHeader("Authorization")
	if len(auth) > 7 && auth[:7] == "Bearer " {
		token = auth[7:]
	}
	if token == "" {
		token = c.Query("token")
	}

	if token == "" {
		return nil
	}

	// Try to get user_id from tokenUsers map first
	a.mu.RLock()
	userID, ok := a.tokenUsers[token]
	a.mu.RUnlock()

	if ok {
		var user models.User
		a.db.First(&user, userID)
		return &user
	}

	// Fallback: try to find user by token as username (old behavior)
	var user models.User
	a.db.Where("username = ?", token).First(&user)
	return &user
}

// GetUserIDFromToken 从token获取用户ID
func (a *UserAuth) GetUserIDFromToken(c *gin.Context) uint {
	token := ""
	auth := c.GetHeader("Authorization")
	if len(auth) > 7 && auth[:7] == "Bearer " {
		token = auth[7:]
	}
	if token == "" {
		token = c.Query("token")
	}

	if token == "" {
		return 0
	}

	a.mu.RLock()
	userID, ok := a.tokenUsers[token]
	a.mu.RUnlock()

	if ok {
		return userID
	}

	return 0
}
