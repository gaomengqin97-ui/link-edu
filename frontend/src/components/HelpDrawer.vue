<template>
  <aside class="help-drawer" :class="{ open }" role="dialog" aria-label="帮助中心" :aria-hidden="!open">
    <header>
      <div>
        <p>HELP</p>
        <h2>帮助中心</h2>
      </div>
      <button type="button" class="close-x" aria-label="关闭" @click="$emit('close')">×</button>
    </header>
    <ol>
      <li v-for="item in faqs" :key="item.q">
        <h3>{{ item.q }}</h3>
        <p>{{ item.a }}</p>
      </li>
    </ol>
  </aside>
  <div v-if="open" class="help-mask" @click="$emit('close')"></div>
</template>

<script setup>
defineProps({
  open: { type: Boolean, default: false },
})
defineEmits(['close'])

const faqs = [
  { q: '如何开始一次微格训练？', a: '课程中心按大纲九项技能分项选课，再进入综合模拟或教资试讲。专项 8 分钟，综合 10 分钟。' },
  { q: 'AI 评课看哪些维度？', a: '综合分之外，还有表达、节奏、互动、教态、提问、结构六项，并给出书面分析。结束训练后自动生成。' },
  { q: '一次训练要多久？', a: '片段练习 8 分钟，完整课 10 分钟。演示时可随时结束并生成评课。' },
  { q: '资源如何使用？', a: '资源库提供教案模板与提问素材。本轮演示为占位下载，上传即将开放。' },
]
</script>
