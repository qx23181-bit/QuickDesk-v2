package models

import "time"

// User 用户管理
type User struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	Username     string    `gorm:"size:50;not null;uniqueIndex" json:"username"`
	Phone        string    `gorm:"size:20" json:"phone"`
	Email        string    `gorm:"size:100" json:"email"`
	Password     string    `gorm:"size:255" json:"-"` // 不返回密码
	Level        string    `gorm:"size:10;default:'V1'" json:"level"` // V1/V2/V3/V4/V5
	DeviceCount  int       `gorm:"default:0" json:"deviceCount"`
	ChannelType  string    `gorm:"size:20;default:'全球'" json:"channelType"` // 全球/中国大陆
	Status       bool      `gorm:"default:true" json:"status"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}
