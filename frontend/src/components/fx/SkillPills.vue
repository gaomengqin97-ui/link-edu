<template>
  <div class="skill-pills" role="tablist">
    <button
      v-for="item in items"
      :key="item.id"
      type="button"
      role="tab"
      :aria-selected="isActive(item.id)"
      :class="{ active: isActive(item.id) }"
      @click="$emit('update:modelValue', item.id)"
    >{{ item.label }}</button>
  </div>
</template>

<script setup>
const props = defineProps({
  items: { type: Array, default: () => [] },
  modelValue: { type: [String, Number], default: '' },
})

defineEmits(['update:modelValue'])

function isActive(id) {
  return String(props.modelValue) === String(id)
}
</script>
