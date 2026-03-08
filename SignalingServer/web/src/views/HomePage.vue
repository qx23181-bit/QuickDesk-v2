<template>
  <div class="home-page" v-loading="loading">
    <div class="page-header">
      <h2>监控面板</h2>
      <el-button
        type="primary"
        size="small"
        @click="loadStats"
        :icon="Refresh"
      >
        刷新数据
      </el-button>
    </div>

    <!-- 概览卡片 -->
    <div class="overview-cards">
      <div class="overview-card purple">
        <div class="overview-icon">
          <el-icon><Monitor /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.totalDevices }}</div>
          <div class="overview-label">总设备数</div>
          <div class="overview-desc">系统中注册的设备总数</div>
        </div>
      </div>
      <div class="overview-card blue">
        <div class="overview-icon">
          <el-icon><Connection /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.totalConnections }}</div>
          <div class="overview-label">总连接数</div>
          <div class="overview-desc">当前活跃的连接总数</div>
        </div>
      </div>
      <div class="overview-card green">
        <div class="overview-icon">
          <el-icon><Connection /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.webSocketConnections }}</div>
          <div class="overview-label">WebSocket连接</div>
          <div class="overview-desc">当前WebSocket连接数</div>
        </div>
      </div>
      <div class="overview-card orange">
        <div class="overview-icon">
          <el-icon><DataLine /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.apiRequests }}</div>
          <div class="overview-label">API请求数</div>
          <div class="overview-desc">今日API请求总数</div>
        </div>
      </div>
    </div>

    <!-- 最近活动表格 -->
    <el-card class="activity-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <el-icon class="card-icon"><Timer /></el-icon>
          <span>最近活动</span>
          <el-button
            type="primary"
            size="small"
            @click="loadActivity"
            :icon="Refresh"
          >
            刷新
          </el-button>
        </div>
      </template>
      <el-table :data="activityList" stripe style="width: 100%" :row-class-name="rowClassName">
        <el-table-column prop="time" label="时间" width="180" />
        <el-table-column prop="deviceId" label="设备ID" width="120" />
        <el-table-column prop="action" label="活动" width="150" />
        <el-table-column prop="details" label="详情" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'success' ? 'success' : 'warning'" size="small">
              {{ row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div v-if="activityList.length === 0 && !loading" class="empty-state">
        <el-empty description="暂无活动记录" />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Monitor, Cpu, Connection, Timer, Refresh, House, DataLine } from '@element-plus/icons-vue'
import { getStats, getSystemStatus, getConnectionStatus, getActivity } from '../api/stats.js'

const loading = ref(false)

// 概览数据
const overview = ref({
  totalDevices: 0,
  totalConnections: 0,
  webSocketConnections: 0,
  apiRequests: 0
})

// 设备状态统计
const stats = ref({
  totalDevices: 0,
  onlineDevices: 0,
  offlineDevices: 0,
  onlineRate: 0
})

// 系统状态
const systemStatus = ref({
  status: 'online',
  statusText: '运行中',
  uptime: '00:00:00',
  apiVersion: 'v1',
  dbStatus: 'connected',
  dbStatusText: '已连接',
  cpu: '0%',
  memory: '0%',
  disk: '0%',
  network: '未知',
  systemVersion: '未知',
  ip: '未知',
  uploadSpeed: 0,
  downloadSpeed: 0,
  uploadTotal: 0,
  downloadTotal: 0
})

// 连接状态
const connectionStatus = ref({
  currentConnections: 0,
  todayConnections: 0,
  webSocketConnections: 0,
  apiRequests: 0
})

// 最近活动
const activityList = ref([
  {
    time: '2026-03-06 14:45:35',
    deviceId: '642407192',
    action: '设备登录',
    details: '设备 642407192 成功登录',
    status: 'success'
  },
  {
    time: '2026-03-06 14:40:12',
    deviceId: '123456789',
    action: '设备注册',
    details: '新设备 123456789 注册成功',
    status: 'success'
  },
  {
    time: '2026-03-06 14:35:45',
    deviceId: '987654321',
    action: '密码验证',
    details: '设备 987654321 密码验证失败',
    status: 'failed'
  }
])

// 根据在线率获取颜色
function getOnlineRateColor(rate) {
  if (rate >= 80) return '#67c23a'
  if (rate >= 50) return '#e6a23c'
  return '#f56c6c'
}

// 格式化流量速度
function formatSpeed(speed) {
  if (speed === undefined || speed === null) return '0 KB/s'
  if (speed < 1024) {
    return `${speed} KB/s`
  } else if (speed < 1024 * 1024) {
    return `${(speed / 1024).toFixed(2)} MB/s`
  } else {
    return `${(speed / 1024 / 1024).toFixed(2)} GB/s`
  }
}

// 为表格行添加类名
function rowClassName({ row }) {
  return row.status === 'success' ? 'success-row' : 'failed-row'
}

// 从API加载活动数据
async function loadActivity() {
  loading.value = true
  try {
    const data = await getActivity()
    activityList.value = data.activity || []
    ElMessage.success('活动数据已更新')
  } catch (e) {
    ElMessage.error('加载活动数据失败: ' + e.message)
  } finally {
    loading.value = false
  }
}

// 从API加载设备统计数据
async function loadStats() {
  loading.value = true
  try {
    // 并行获取所有数据
    const [statsData, systemData, connectionData] = await Promise.all([
      getStats(),
      getSystemStatus(),
      getConnectionStatus()
    ])

    // 更新状态数据
    stats.value = statsData
    systemStatus.value = systemData
    connectionStatus.value = connectionData

    // 更新概览数据
    updateOverview(systemData)

    ElMessage.success('统计数据已更新')
  } catch (e) {
    ElMessage.error('加载统计数据失败: ' + e.message)
  } finally {
    loading.value = false
  }
}

// 更新概览数据
function updateOverview(systemData) {
  // 总设备数
  overview.value.totalDevices = stats.value.totalDevices || 0

  // 总连接数
  overview.value.totalConnections = connectionStatus.value.currentConnections || 0

  // WebSocket连接数
  overview.value.webSocketConnections = connectionStatus.value.webSocketConnections || 0

  // API请求数
  overview.value.apiRequests = connectionStatus.value.apiRequests || 0
}

// 仅刷新系统状态（毫秒级后台刷新）
let systemStatusTimer = null
async function refreshSystemStatus() {
  try {
    const systemData = await getSystemStatus()
    systemStatus.value = systemData
    // 同时更新概览数据
    updateOverview(systemData)
  } catch (e) {
    console.error('刷新系统状态失败:', e.message)
  }
}

// 启动系统状态自动刷新（每1秒刷新一次）
function startSystemStatusAutoRefresh() {
  if (systemStatusTimer) {
    clearInterval(systemStatusTimer)
  }
  systemStatusTimer = setInterval(refreshSystemStatus, 1000)
}

// 停止系统状态自动刷新
function stopSystemStatusAutoRefresh() {
  if (systemStatusTimer) {
    clearInterval(systemStatusTimer)
    systemStatusTimer = null
  }
}

onMounted(() => {
  loadStats()
  loadActivity()
  // 启动系统状态毫秒级后台刷新
  startSystemStatusAutoRefresh()
})

onUnmounted(() => {
  // 组件卸载时停止自动刷新
  stopSystemStatusAutoRefresh()
})
</script>

<style scoped>
.home-page {
  width: 100%;
  padding: 20px;
  box-sizing: border-box;
  overflow: hidden;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #303133;
}

/* 概览卡片样式 */
.overview-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

.overview-card {
  display: flex;
  align-items: center;
  padding: 20px;
  border-radius: 12px;
  color: white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.overview-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.overview-card.purple {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.overview-card.blue {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.overview-card.green {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.overview-card.orange {
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
}

.overview-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  font-size: 28px;
}

.overview-content {
  flex: 1;
}

.overview-value {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 4px;
}

.overview-label {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 4px;
  opacity: 0.95;
}

.overview-desc {
  font-size: 12px;
  opacity: 0.8;
}

.overview-sub {
  font-size: 12px;
  margin-top: 4px;
  opacity: 0.9;
}

@media (max-width: 1200px) {
  .overview-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .overview-cards {
    grid-template-columns: 1fr;
  }
}

.stats-container {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  margin-bottom: 20px;
}

.stats-card {
  flex: 1;
  min-width: 300px;
  min-height: 400px;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.stats-card:hover {
  box-shadow: 0 4px 16px 0 rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.device-card {
  border-top: 4px solid #409eff;
}

.system-card {
  border-top: 4px solid #67c23a;
}

.connection-card {
  border-top: 4px solid #e6a23c;
}

.activity-card {
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  padding: 15px 20px;
  border-bottom: 1px solid #f0f0f0;
}

.card-icon {
  font-size: 18px;
  color: #409eff;
}

.card-header .el-button {
  margin-left: auto;
}

.stats-content {
  padding: 20px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.stat-item:last-child {
  border-bottom: none;
}

.stat-label {
  color: #606266;
  font-size: 14px;
  font-weight: 500;
}

.stat-value {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.stat-value.online {
  color: #67c23a;
}

.stat-value.offline {
  color: #909399;
}

.stat-value.upload {
  color: #409eff;
}

.stat-value.download {
  color: #67c23a;
}

.stat-value.rate {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 8px;
}

.online-rate-container {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  width: 120px;
}

.empty-state {
  padding: 40px 0;
}

/* 表格行样式 */
:deep(.success-row) {
  background-color: rgba(103, 194, 58, 0.05) !important;
}

:deep(.failed-row) {
  background-color: rgba(245, 108, 108, 0.05) !important;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .home-page {
    padding: 10px;
  }
  
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .stats-container {
    flex-direction: column;
  }
  
  .stats-card {
    flex: 100%;
    min-width: 100%;
    min-height: auto;
    margin-bottom: 0;
  }
  
  .online-rate-container {
    width: 100%;
    align-items: flex-end;
  }
  
  .stat-item {
    padding: 8px 0;
  }
  
  .stat-value {
    font-size: 16px;
  }
  
  .stat-label {
    font-size: 13px;
  }
}

@media (max-width: 480px) {
  .home-page {
    padding: 8px;
  }
  
  .page-header h2 {
    font-size: 20px;
  }
  
  .stats-content {
    padding: 15px;
  }
  
  .stat-item {
    padding: 10px 0;
  }
  
  .stat-value {
    font-size: 16px;
  }
  
  .stat-value.rate {
    font-size: 18px;
  }
}

/* 实时标签样式 */
.live-tag {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 4px;
}

.live-dot {
  width: 6px;
  height: 6px;
  background-color: #67c23a;
  border-radius: 50%;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.2);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}
</style>
