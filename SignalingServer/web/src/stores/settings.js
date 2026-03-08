import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getSettings } from '../api/settings.js'

export const useSettingsStore = defineStore('settings', () => {
  // 状态
  const siteName = ref('')
  const siteEnabled = ref(true)
  const loading = ref(true)

  // 加载设置
  async function loadSettings() {
    loading.value = true
    try {
      const data = await getSettings()
      siteName.value = data.siteName || 'QuickDesk'
      siteEnabled.value = data.siteEnabled !== false
    } catch (e) {
      console.error('加载设置失败:', e)
    } finally {
      loading.value = false
    }
  }

  // 更新设置
  function updateSettings(data) {
    if (data.siteName !== undefined) {
      siteName.value = data.siteName
    }
    if (data.siteEnabled !== undefined) {
      siteEnabled.value = data.siteEnabled
    }
  }

  return {
    siteName,
    siteEnabled,
    loading,
    loadSettings,
    updateSettings
  }
})
