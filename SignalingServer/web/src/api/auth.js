// 本地存储的 Token 键名
const TOKEN_KEY = 'quickdesk_admin_token'

// 获取存储的 Token
export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}

// 设置 Token 到本地存储
export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token)
}

// 从本地存储移除 Token
export function removeToken() {
  localStorage.removeItem(TOKEN_KEY)
}

// 登录请求
// @param {string} user - 用户名
// @param {string} password - 密码
// @returns {Promise} 返回登录结果
export async function login(user, password) {
  const res = await fetch('/api/v1/admin/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ user, password })
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || 'Login failed')
  setToken(data.token)
  return data
}

// 登出，清除本地存储的 Token
export function logout() {
  removeToken()
}

// 带认证的 fetch 封装
// 自动添加 Authorization 头，处理 401 未授权情况
// @param {string} url - 请求地址
// @param {object} options - fetch 选项
// @returns {Promise} 返回 fetch 响应
export async function authFetch(url, options = {}) {
  const token = getToken()
  const headers = { ...options.headers }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(url, { ...options, headers })

  if (res.status === 401) {
    removeToken()
    window.location.hash = '#/login'
    throw new Error('unauthorized')
  }

  return res
}
