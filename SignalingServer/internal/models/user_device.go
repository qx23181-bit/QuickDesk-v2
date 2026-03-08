package models

import (
	"time"
)

// UserDevice 用户设备绑定表
// 记录用户与设备的绑定关系，当用户通过远程连接成功连接设备后创建
type UserDevice struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	UserID       uint      `gorm:"not null;index" json:"user_id"`       // 用户ID
	DeviceID     string    `gorm:"size:9;not null;index" json:"device_id"` // 设备ID（9位数字）
	DeviceName   string    `gorm:"size:100" json:"device_name"`        // 设备名称（用户可自定义）
	BindType     string    `gorm:"size:20;default:'manual'" json:"bind_type"` // 绑定类型: manual(手动)/auto(自动)
	Status       bool      `gorm:"default:true" json:"status"`         // 绑定状态：true-有效, false-已解绑
	LastConnect  time.Time `json:"last_connect"`                       // 最后连接时间
	ConnectCount int       `gorm:"default:0" json:"connect_count"`     // 连接次数
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// 关联
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName 指定表名
func (UserDevice) TableName() string {
	return "user_devices"
}

// UserDeviceLog 用户设备连接日志表
// 记录每次连接的详细信息
type UserDeviceLog struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	UserID     uint      `gorm:"not null;index" json:"user_id"`      // 用户ID
	DeviceID   string    `gorm:"size:9;not null;index" json:"device_id"` // 设备ID
	ConnectIP  string    `gorm:"size:50" json:"connect_ip"`        // 连接IP地址
	Duration   int       `json:"duration"`                         // 连接时长（秒）
	Status     string    `gorm:"size:20" json:"status"`            // 连接状态: success/failed/timeout
	ErrorMsg   string    `gorm:"size:255" json:"error_msg"`        // 错误信息
	CreatedAt  time.Time `json:"created_at"`
}

// TableName 指定表名
func (UserDeviceLog) TableName() string {
	return "user_device_logs"
}
