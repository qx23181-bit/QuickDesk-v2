package models

import (
	"time"
)

// ConnectionHistory 连接历史表
// 记录用户连接设备的历史记录
type ConnectionHistory struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	UserID     uint      `gorm:"not null;index" json:"user_id"`     // 用户ID
	DeviceID   string    `gorm:"size:9;not null;index" json:"device_id"` // 设备ID
	DeviceName string    `gorm:"size:100" json:"device_name"`        // 设备名称
	ConnectIP  string    `gorm:"size:50" json:"connect_ip"`        // 连接IP地址
	Duration   int       `json:"duration"`                         // 连接时长（秒）
	Status     string    `gorm:"size:20" json:"status"`            // 连接状态: success/failed/timeout
	ErrorMsg   string    `gorm:"size:255" json:"error_msg"`        // 错误信息
	CreatedAt  time.Time `json:"created_at"`

	// 关联
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName 指定表名
func (ConnectionHistory) TableName() string {
	return "connection_histories"
}
