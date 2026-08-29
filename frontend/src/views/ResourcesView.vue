<template>
  <div class="sparse-page">
    <header class="page-head growth-head">
      <div>
        <p class="shiny-kicker">LIBRARY</p>
        <SplitTitle text="资源库" />
        <p class="page-lead">按教案、素材、报告、档案分类，对照师范技能训练使用。</p>
      </div>
    </header>

    <div class="resource-tabs">
      <button
        v-for="item in tabs"
        :key="item"
        type="button"
        :class="{ active: tab === item }"
        @click="tab = item"
      >{{ item }}</button>
    </div>

    <ul class="resource-list">
      <li v-for="item in visible" :key="item.id" class="glare-row">
        <div>
          <em>{{ item.category }}</em>
          <strong>{{ item.title }}</strong>
          <span>{{ item.description }}</span>
        </div>
        <button type="button" @click="open(item)">打开</button>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useMessage } from 'naive-ui'
import SplitTitle from '../components/fx/SplitTitle.vue'
import { fetchResources } from '../services/dashboard'

const message = useMessage()
const items = ref([])
const tab = ref('全部')
const tabs = ['全部', '教案', '素材', '报告', '档案']

const visible = computed(() => {
  if (tab.value === '全部') return items.value
  return items.value.filter((item) => item.category === tab.value)
})

function open(item) {
  if (item.file_url) {
    window.open(item.file_url, '_blank', 'noopener')
    return
  }
  message.info(`${item.title}：演示包暂无文件，可先对照说明使用。`)
}

onMounted(async () => {
  try {
    items.value = await fetchResources()
  } catch {
    items.value = [
      { id: 1, title: '微格教案模板', category: '教案', description: '适用于 10 分钟片段教学' },
      { id: 2, title: '课堂提问设计素材包', category: '素材', description: '导入、提问、总结三类场景' },
      { id: 3, title: 'AI 评课示例报告', category: '报告', description: '查看完整评课维度拆解' },
      { id: 4, title: '师范生成长档案样例', category: '档案', description: '训练记录与成长轨迹示例' },
    ]
  }
})
</script>
