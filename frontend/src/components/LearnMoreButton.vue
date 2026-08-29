<template>
  <button class="learn-more" type="button" @click="$emit('click', $event)">
    <span class="circle" aria-hidden="true">
      <span class="icon arrow"></span>
    </span>
    <span class="button-text"><slot /></span>
  </button>
</template>

<script setup>
defineEmits(['click'])
</script>
