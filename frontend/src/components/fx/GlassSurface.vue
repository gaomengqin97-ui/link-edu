<template>
  <div class="glass-surface" :class="className" :style="boxStyle">
    <slot />
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  radius: { type: Number, default: 999 },
  width: { type: String, default: '' },
  height: { type: String, default: '' },
  className: { type: String, default: '' },
})

const boxStyle = computed(() => {
  const style = { borderRadius: `${props.radius}px` }
  if (props.width) style.width = props.width
  if (props.height) style.height = props.height
  return style
})
</script>
