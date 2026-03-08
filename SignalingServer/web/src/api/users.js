import { authFetch } from './auth.js'

const BASE_URL = '/api/v1/admin/user-list'

// 获取用户列表
export async function getUsers() {
  const res = await authFetch(BASE_URL)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 获取单个用户
export async function getUser(id) {
  const res = await authFetch(`${BASE_URL}/${id}`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 创建用户
export async function createUser(data) {
  const res = await authFetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.error || `HTTP ${res.status}`)
  }
  return res.json()
}

// 更新用户
export async function updateUser(id, data) {
  const res = await authFetch(`${BASE_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.error || `HTTP ${res.status}`)
  }
  return res.json()
}

// 删除用户
export async function deleteUser(id) {
  const res = await authFetch(`${BASE_URL}/${id}`, {
    method: 'DELETE'
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

// 更新用户设备数量
export async function updateUserDeviceCount(id, deviceCount) {
  const res = await authFetch(`${BASE_URL}/${id}/device-count`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deviceCount })
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
