import { authFetch } from './auth.js'

const PUBLIC_URL = '/api/v1/settings'
const ADMIN_URL = '/api/v1/admin/settings'

// 获取系统设置（公共API，无需登录）
export async function getSettings() {
  const res = await fetch(PUBLIC_URL)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 更新系统设置（需要管理员权限）
export async function updateSettings(data) {
  const res = await authFetch(ADMIN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
