import { authFetch } from './auth.js'

const BASE_URL = '/api/v1/admin/devices'

export async function getDevices() {
  const res = await authFetch(BASE_URL)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
