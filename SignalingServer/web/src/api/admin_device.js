/**
 * Admin Device API Client
 * 提供管理员设备管理的相关接口
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
    return localStorage.getItem('quickdesk_admin_token');
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
 * Get all devices (admin only)
 * @returns {Promise<Object>}
 */
export async function getDevices() {
    const response = await fetch(`${API_BASE_URL}/admin/devices`, {
        method: 'GET',
        headers: getAuthHeaders()
    });
    return await response.json();
}

/**
 * Get device status
 * @param {string} deviceId - Device ID
 * @returns {Promise<Object>}
 */
export async function getDeviceStatus(deviceId) {
    const response = await fetch(`${API_BASE_URL}/devices/${deviceId}/status`);
    return await response.json();
}
