package models

import "time"

// Settings 系统设置
type Settings struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	SiteEnabled bool      `gorm:"default:true" json:"siteEnabled"`
	SiteName    string    `gorm:"size:100" json:"siteName"`
	LoginLogo   string    `gorm:"size:500" json:"loginLogo"`
	SmallLogo   string    `gorm:"size:500" json:"smallLogo"`
	Favicon     string    `gorm:"size:500" json:"favicon"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// TableName 指定表名
func (Settings) TableName() string {
	return "settings"
}
