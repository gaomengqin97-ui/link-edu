<template>
  <h1 class="split-title" :aria-label="text">
    <span
      v-for="(char, index) in chars"
      :key="`${char}-${index}`"
      class="split-title__char"
      :style="{ animationDelay: `${index * 28}ms` }"
    >{{ char === ' ' ? '\u00a0' : char }}</span>
  </h1>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  text: { type: String, default: '' },
})

const chars = computed(() => Array.from(props.text || ''))
</script>
