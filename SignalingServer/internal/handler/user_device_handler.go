package handler

import (
	"net/http"
	"quickdesk/signaling/internal/models"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// UserDeviceHandler 用户设备绑定处理器
type UserDeviceHandler struct {
	db *gorm.DB
}

// NewUserDeviceHandler 创建用户设备绑定处理器
func NewUserDeviceHandler(db *gorm.DB) *UserDeviceHandler {
	return &UserDeviceHandler{db: db}
}

// BindDeviceRequest 绑定设备请求
type BindDeviceRequest struct {
	UserID     uint   `json:"user_id" binding:"required"`   // 用户ID
	DeviceID   string `json:"device_id" binding:"required"` // 设备ID（9位数字）
	DeviceName string `json:"device_name"`                  // 设备名称（可选）
	BindType   string `json:"bind_type"`                    // 绑定类型: manual/auto
}

// BindDevice 绑定设备到用户
// 当用户通过远程连接成功连接设备后调用此接口
func (h *UserDeviceHandler) BindDevice(c *gin.Context) {
	var req BindDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 验证用户是否存在
	var user models.User
	if result := h.db.First(&user, req.UserID); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	// 验证设备是否存在
	var device models.Device
	if result := h.db.Where("device_id = ?", req.DeviceID).First(&device); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "设备不存在"})
		return
	}

	// 检查是否已绑定
	var existingBinding models.UserDevice
	result := h.db.Where("user_id = ? AND device_id = ? AND status = ?", req.UserID, req.DeviceID, true).First(&existingBinding)
	if result.Error == nil {
		// 已存在绑定，更新最后连接时间
		existingBinding.LastConnect = time.Now()
		existingBinding.ConnectCount++
		h.db.Save(&existingBinding)

		// 记录连接日志
		h.logConnection(req.UserID, req.DeviceID, "success", "", c.ClientIP())

		c.JSON(http.StatusOK, gin.H{
			"message": "设备已绑定，更新连接记录",
			"binding": existingBinding,
		})
		return
	}

	// 设置默认值
	bindType := req.BindType
	if bindType == "" {
		bindType = "auto"
	}

	deviceName := req.DeviceName
	if deviceName == "" {
		deviceName = "设备-" + req.DeviceID
	}

	// 创建新绑定
	binding := models.UserDevice{
		UserID:       req.UserID,
		DeviceID:     req.DeviceID,
		DeviceName:   deviceName,
		BindType:     bindType,
		Status:       true,
		LastConnect:  time.Now(),
		ConnectCount: 1,
	}

	if result := h.db.Create(&binding); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "绑定设备失败: " + result.Error.Error()})
		return
	}

	// 更新用户设备数量
	h.db.Model(&models.User{}).Where("id = ?", req.UserID).Update("device_count", gorm.Expr("device_count + 1"))

	// 记录连接日志
	h.logConnection(req.UserID, req.DeviceID, "success", "", c.ClientIP())

	c.JSON(http.StatusOK, gin.H{
		"message": "设备绑定成功",
		"binding": binding,
	})
}

// UnbindDevice 解绑设备
func (h *UserDeviceHandler) UnbindDevice(c *gin.Context) {
	var req struct {
		UserID   uint   `json:"user_id" binding:"required"`
		DeviceID string `json:"device_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 查找绑定记录
	var binding models.UserDevice
	result := h.db.Where("user_id = ? AND device_id = ? AND status = ?", req.UserID, req.DeviceID, true).First(&binding)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "绑定记录不存在"})
		return
	}

	// 更新绑定状态为无效
	binding.Status = false
	h.db.Save(&binding)

	// 更新用户设备数量
	h.db.Model(&models.User{}).Where("id = ?", req.UserID).Update("device_count", gorm.Expr("device_count - 1"))

	c.JSON(http.StatusOK, gin.H{"message": "设备解绑成功"})
}

// GetUserDevices 获取用户的所有绑定设备
// 从devices表查询用户绑定的设备
func (h *UserDeviceHandler) GetUserDevices(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID不能为空"})
		return
	}

	var devices []models.Device
	result := h.db.Where("user_id = ?", userID).Find(&devices)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"devices": devices,
		"count":   len(devices),
	})
}

// GetDeviceUsers 获取设备的所有绑定用户
func (h *UserDeviceHandler) GetDeviceUsers(c *gin.Context) {
	deviceID := c.Param("device_id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "设备ID不能为空"})
		return
	}

	var bindings []models.UserDevice
	result := h.db.Preload("User").Where("device_id = ? AND status = ?", deviceID, true).Find(&bindings)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"users": bindings,
		"count": len(bindings),
	})
}

// UpdateDeviceName 更新设备名称
func (h *UserDeviceHandler) UpdateDeviceName(c *gin.Context) {
	var req struct {
		UserID     uint   `json:"user_id" binding:"required"`
		DeviceID   string `json:"device_id" binding:"required"`
		DeviceName string `json:"device_name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := h.db.Model(&models.UserDevice{}).
		Where("user_id = ? AND device_id = ? AND status = ?", req.UserID, req.DeviceID, true).
		Update("device_name", req.DeviceName)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "绑定记录不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "设备名称更新成功"})
}

// GetUserDeviceLogs 获取用户的设备连接日志（近3天）
func (h *UserDeviceHandler) GetUserDeviceLogs(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID不能为空"})
		return
	}

	// 查询近3天的连接历史
	threeDaysAgo := time.Now().AddDate(0, 0, -3)
	var logs []models.ConnectionHistory
	result := h.db.Where("user_id = ? AND created_at >= ?", userID, threeDaysAgo).
		Order("created_at DESC").
		Limit(100).
		Find(&logs)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"logs":  logs,
		"count": len(logs),
	})
}

// GetAllBindings 获取所有用户设备绑定关系（管理员接口）
func (h *UserDeviceHandler) GetAllBindings(c *gin.Context) {
	var bindings []models.UserDevice
	result := h.db.Preload("User").Find(&bindings)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"bindings": bindings,
		"count":    len(bindings),
	})
}

// logConnection 记录连接日志
func (h *UserDeviceHandler) logConnection(userID uint, deviceID, status, errorMsg, connectIP string) {
	log := models.UserDeviceLog{
		UserID:    userID,
		DeviceID:  deviceID,
		ConnectIP: connectIP,
		Status:    status,
		ErrorMsg:  errorMsg,
	}
	h.db.Create(&log)
}

// RecordConnection 记录设备连接（WebClient调用）
// 当WebClient成功连接设备后，通过此接口记录连接信息
func (h *UserDeviceHandler) RecordConnection(c *gin.Context) {
	var req struct {
		UserID   uint   `json:"user_id" binding:"required"`
		DeviceID string `json:"device_id" binding:"required"`
		Duration int    `json:"duration"`  // 连接时长（秒）
		Status   string `json:"status"`    // success/failed/timeout
		ErrorMsg string `json:"error_msg"` // 错误信息
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 记录连接日志
	h.logConnection(req.UserID, req.DeviceID, req.Status, req.ErrorMsg, c.ClientIP())

	// 如果连接成功，更新绑定记录的最后连接时间
	if req.Status == "success" {
		h.db.Model(&models.UserDevice{}).
			Where("user_id = ? AND device_id = ? AND status = ?", req.UserID, req.DeviceID, true).
			Updates(map[string]interface{}{
				"last_connect":  time.Now(),
				"connect_count": gorm.Expr("connect_count + 1"),
			})
	}

	c.JSON(http.StatusOK, gin.H{"message": "连接记录已保存"})
}

// CheckDeviceBinding 检查用户是否已绑定设备
func (h *UserDeviceHandler) CheckDeviceBinding(c *gin.Context) {
	userID := c.Query("user_id")
	deviceID := c.Query("device_id")

	if userID == "" || deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID和设备ID不能为空"})
		return
	}

	var binding models.UserDevice
	result := h.db.Where("user_id = ? AND device_id = ? AND status = ?", userID, deviceID, true).First(&binding)

	isBound := result.Error == nil
	c.JSON(http.StatusOK, gin.H{
		"is_bound": isBound,
		"binding":  binding,
	})
}

// QuickConnectBind 快速连接绑定
// 用户通过快速连接功能连接设备时，将设备名称、访问码和用户ID绑定到devices表
func (h *UserDeviceHandler) QuickConnectBind(c *gin.Context) {
	var req struct {
		UserID     uint   `json:"user_id" binding:"required"`
		DeviceID   string `json:"device_id" binding:"required"`
		DeviceName string `json:"device_name"`
		AccessCode string `json:"access_code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 验证用户是否存在
	var user models.User
	if result := h.db.First(&user, req.UserID); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	// 验证设备是否存在
	var device models.Device
	if result := h.db.Where("device_id = ?", req.DeviceID).First(&device); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "设备不存在"})
		return
	}

	// 更新devices表，绑定用户ID、设备名称和访问码
	updates := map[string]interface{}{
		"user_id": req.UserID,
	}

	if req.DeviceName != "" {
		updates["device_name"] = req.DeviceName
	} else if device.DeviceName == "" {
		updates["device_name"] = "设备-" + req.DeviceID
	}

	// 保存访问码
	if req.AccessCode != "" {
		updates["access_code"] = req.AccessCode
	}

	result := h.db.Model(&models.Device{}).
		Where("device_id = ?", req.DeviceID).
		Updates(updates)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "绑定设备失败: " + result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "设备绑定成功",
		"device":  device,
	})
}
