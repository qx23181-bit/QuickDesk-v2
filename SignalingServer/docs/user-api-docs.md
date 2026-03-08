# QuickDesk 用户注册/登录 API 对接文档

## 1. 接口概览

| 接口 | 方法 | 路径 | 功能 | 权限 |
|------|------|------|------|------|
| 用户注册 | POST | `/api/v1/user/register` | 注册新用户 | 公开 |
| 用户登录 | POST | `/api/v1/user/login` | 用户登录获取token | 公开 |

## 2. 用户注册接口

### 请求参数

**请求方式**: POST
**请求路径**: `/api/v1/user/register`
**Content-Type**: `application/json`

| 参数名 | 类型 | 必选 | 描述 | 默认值 |
|--------|------|------|------|--------|
| username | string | 是 | 用户名 | - |
| password | string | 是 | 密码（至少6位） | - |
| phone | string | 否 | 手机号 | - |
| email | string | 否 | 邮箱 | - |
| level | string | 否 | 用户等级 | "V1" |
| channelType | string | 否 | 通道类型 | "全球" |

### 响应格式

**成功响应**:
```json
{
  "message": "注册成功",
  "user": {
    "id": 1,
    "username": "testuser",
    "phone": "13800138000",
    "email": "test@example.com",
    "level": "V1",
    "deviceCount": 0,
    "channelType": "全球",
    "status": true,
    "createdAt": "2026-03-08T10:00:00Z",
    "updatedAt": "2026-03-08T10:00:00Z"
  }
}
```

**失败响应**:
```json
{
  "error": "用户名已存在"
}
```

## 3. 用户登录接口

### 请求参数

**请求方式**: POST
**请求路径**: `/api/v1/user/login`
**Content-Type**: `application/json`

| 参数名 | 类型 | 必选 | 描述 |
|--------|------|------|------|
| username | string | 是 | 用户名 |
| password | string | 是 | 密码 |

### 响应格式

**成功响应**:
```json
{
  "token": "5f4dcc3b5aa765d61d8327deb882cf99",
  "user": {
    "id": 1,
    "username": "testuser",
    "phone": "13800138000",
    "email": "test@example.com",
    "level": "V1",
    "deviceCount": 0,
    "channelType": "全球",
    "status": true,
    "createdAt": "2026-03-08T10:00:00Z",
    "updatedAt": "2026-03-08T10:00:00Z"
  }
}
```

**失败响应**:
```json
{
  "error": "用户名或密码错误"
}
```

## 4. Token 使用说明

- **Token 有效期**: 7天
- **使用方式**: 在请求头中添加 `Authorization: Bearer {token}`
- **示例**: `Authorization: Bearer 5f4dcc3b5aa765d61d8327deb882cf99`

## 5. 代码示例

### JavaScript (Fetch API)

**注册示例**:
```javascript
async function register() {
  const response = await fetch('/api/v1/user/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      username: 'testuser',
      password: 'password123',
      phone: '13800138000',
      email: 'test@example.com',
      level: 'V1',
      channelType: '全球'
    })
  });
  
  const data = await response.json();
  console.log(data);
}
```

**登录示例**:
```javascript
async function login() {
  const response = await fetch('/api/v1/user/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      username: 'testuser',
      password: 'password123'
    })
  });
  
  const data = await response.json();
  if (data.token) {
    localStorage.setItem('userToken', data.token);
    localStorage.setItem('userInfo', JSON.stringify(data.user));
  }
  console.log(data);
}
```

### Python (requests)

**注册示例**:
```python
import requests

url = 'http://localhost:8000/api/v1/user/register'
data = {
    'username': 'testuser',
    'password': 'password123',
    'phone': '13800138000',
    'email': 'test@example.com',
    'level': 'V1',
    'channelType': '全球'
}

response = requests.post(url, json=data)
print(response.json())
```

**登录示例**:
```python
import requests

url = 'http://localhost:8000/api/v1/user/login'
data = {
    'username': 'testuser',
    'password': 'password123'
}

response = requests.post(url, json=data)
print(response.json())
```

## 6. 错误码说明

| 错误信息 | 说明 | HTTP状态码 |
|----------|------|------------|
| invalid request | 请求参数格式错误 | 400 |
| 用户名已存在 | 用户名已被注册 | 400 |
| 用户名或密码错误 | 用户名或密码不正确 | 401 |
| 账号已被禁用 | 用户账号状态为禁用 | 403 |
| 密码加密失败 | 服务器密码加密过程出错 | 500 |
| 创建用户失败 | 数据库操作失败 | 500 |

## 7. 注意事项

1. **密码安全**: 密码长度至少6位，建议使用强密码
2. **用户名唯一性**: 用户名不可重复
3. **Token管理**: 客户端应妥善保管token，避免泄露
4. **错误处理**: 客户端应处理各种错误响应
5. **HTTPS**: 生产环境建议使用HTTPS协议

## 8. 前端页面

系统提供了以下前端页面：
- **注册页面**: `http://localhost:8000/admin/#/register`
- **登录页面**: `http://localhost:8000/admin/#/user-login`

这些页面已经集成了上述API调用逻辑。