package models

import (
	"time"
)

// Device represents a QuickDesk host device
type Device struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	DeviceID   string    `gorm:"uniqueIndex;size:9;not null" json:"device_id"` // 9位数字ID
	DeviceUUID string    `gorm:"uniqueIndex;not null" json:"device_uuid"`      // UUID
	OS         string    `gorm:"size:50" json:"os"`
	OSVersion  string    `gorm:"size:50" json:"os_version"`
	AppVersion string    `gorm:"size:20" json:"app_version"`
	UserID     uint      `gorm:"index" json:"user_id"`        // 绑定的用户ID
	DeviceName string    `gorm:"size:100" json:"device_name"` // 设备名称（用户自定义）
	Remark     string    `gorm:"size:255" json:"remark"`      // 设备备注
	AccessCode string    `gorm:"size:6" json:"access_code"`   // 访问码（6位数字）
	Online     bool      `gorm:"default:false" json:"online"`
	LastSeen   time.Time `json:"last_seen"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`

	// 关联
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName overrides the table name
func (Device) TableName() string {
	return "devices"
}
