<template>
  <article
    class="spotlight-pane"
    :style="{ '--mx': `${mx}px`, '--my': `${my}px` }"
    @mousemove="onMove"
    @mouseleave="onLeave"
  >
    <slot />
  </article>
</template>

<script setup>
import { ref } from 'vue'

const mx = ref(80)
const my = ref(40)

function onMove(event) {
  const rect = event.currentTarget.getBoundingClientRect()
  mx.value = event.clientX - rect.left
  my.value = event.clientY - rect.top
}

function onLeave() {
  mx.value = 80
  my.value = 40
}
</script>
