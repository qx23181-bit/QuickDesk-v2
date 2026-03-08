import { authFetch } from './auth.js'

// 预设 API 基础路径
const BASE_URL = '/api/v1/admin/preset'

// 获取预设配置
// @returns {Promise} 返回预设配置对象
export async function getPreset() {
  const res = await authFetch(BASE_URL)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 更新预设配置
// @param {object} data - 预设配置数据
// @returns {Promise} 返回更新后的预设配置对象
export async function updatePreset(data) {
  const res = await authFetch(BASE_URL, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
