/**
 * User Device API Client
 * 提供用户设备绑定的相关接口
 */

// Get API base URL from localStorage or use default
function getApiBaseUrl() {
    const apiServer = localStorage.getItem('quickdesk_api_server') || 'http://localhost:8000';
    return `${apiServer}/api/v1`;
}

const API_BASE_URL = getApiBaseUrl();

/**
 * Get authentication token
 * @returns {string|null}
 */
function getAuthToken() {
    return localStorage.getItem('quickdesk_token');
}

/**
 * Get headers with authentication
 * @returns {Object}
 */
function getAuthHeaders() {
    const token = getAuthToken();
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
}

/**
 * Get user's bound devices
 * @returns {Promise<Object>}
 */
export async function getUserDevices() {
    const response = await fetch(`${API_BASE_URL}/user/devices`, {
        method: 'GET',
        headers: getAuthHeaders()
    });
    return await response.json();
}

/**
 * Bind device to user
 * @param {Object} data - Binding data
 * @param {number} data.user_id - User ID
 * @param {string} data.device_id - Device ID (9 digits)
 * @param {string} data.device_name - Device name (optional)
 * @param {string} data.bind_type - Bind type: manual/auto
 * @returns {Promise<Object>}
 */
export async function bindDevice(data) {
    const response = await fetch(`${API_BASE_URL}/user/devices/bind`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(data)
    });
    return await response.json();
}

/**
 * Unbind device from user
 * @param {Object} data - Unbinding data
 * @param {number} data.user_id - User ID
 * @param {string} data.device_id - Device ID
 * @returns {Promise<Object>}
 */
export async function unbindDevice(data) {
    const response = await fetch(`${API_BASE_URL}/user/devices/unbind`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(data)
    });
    return await response.json();
}

/**
 * Check if device is bound to user
 * @param {number} userId - User ID
 * @param {string} deviceId - Device ID
 * @returns {Promise<Object>}
 */
export async function checkDeviceBinding(userId, deviceId) {
    const response = await fetch(
        `${API_BASE_URL}/user/devices/check?user_id=${userId}&device_id=${deviceId}`,
        { headers: getAuthHeaders() }
    );
    return await response.json();
}

/**
 * Record device connection
 * @param {Object} data - Connection data
 * @param {number} data.user_id - User ID
 * @param {string} data.device_id - Device ID
 * @param {number} data.duration - Connection duration (seconds)
 * @param {string} data.status - Connection status: success/failed/timeout
 * @param {string} data.error_msg - Error message (optional)
 * @returns {Promise<Object>}
 */
export async function recordConnection(data) {
    const response = await fetch(`${API_BASE_URL}/user/devices/record`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(data)
    });
    return await response.json();
}

/**
 * Get user device connection logs
 * @returns {Promise<Object>}
 */
export async function getUserDeviceLogs() {
    const response = await fetch(`${API_BASE_URL}/user/devices/logs`, {
        method: 'GET',
        headers: getAuthHeaders()
    });
    return await response.json();
}
