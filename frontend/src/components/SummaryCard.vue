<template>
  <article class="summary-card" :class="item.accent">
    <img
      class="summary-card__art"
      :src="artSrc"
      :alt="item.title || '训练战报'"
    />
    <div class="summary-card__meta">
      <small>{{ item.tag || '近 3 练战报' }}</small>
      <em>{{ item.range }}</em>
    </div>
    <div class="summary-card__head">
      <strong>{{ item.title }}</strong>
      <b>{{ item.highlight || `高光 ${item.avg_score || ''}` }}</b>
    </div>
    <p>{{ item.body }}</p>
    <span>{{ item.caption }}</span>
  </article>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  item: { type: Object, required: true },
})

const artSrc = computed(() => {
  const key = props.item?.image
  const allowed = { intro: 1, ask: 1, board: 1, interact: 1 }
  const name = allowed[key] ? key : 'intro'
  return `/assets/summaries/${name}.svg`
})
</script>
