import { authFetch } from './auth.js'

const BASE_URL = '/api/v1/admin'

// 获取监控面板统计数据
export async function getStats() {
  const res = await authFetch(`${BASE_URL}/stats`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 获取系统状态
export async function getSystemStatus() {
  const res = await authFetch(`${BASE_URL}/system/status`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 获取连接状态
export async function getConnectionStatus() {
  const res = await authFetch(`${BASE_URL}/connections`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 获取最近活动记录
export async function getActivity() {
  const res = await authFetch(`${BASE_URL}/activity`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
