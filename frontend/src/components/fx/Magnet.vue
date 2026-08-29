<template>
  <div
    ref="rootRef"
    class="magnet"
    @mousemove="onMove"
    @mouseleave="onLeave"
  >
    <slot />
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  strength: { type: Number, default: 0.22 },
})

const rootRef = ref(null)

function onMove(event) {
  const el = rootRef.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  const x = event.clientX - rect.left - rect.width / 2
  const y = event.clientY - rect.top - rect.height / 2
  el.style.transform = `translate(${x * props.strength}px, ${y * props.strength}px)`
}

function onLeave() {
  const el = rootRef.value
  if (!el) return
  el.style.transform = 'translate(0, 0)'
}
</script>
