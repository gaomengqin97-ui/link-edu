<template>
  <div class="click-spark" @click="handleClick">
    <canvas ref="canvasRef" class="click-spark__canvas" aria-hidden="true"></canvas>
    <slot />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps({
  sparkColor: { type: String, default: '#ffffff' },
  sparkSize: { type: Number, default: 10 },
  sparkRadius: { type: Number, default: 15 },
  sparkCount: { type: Number, default: 8 },
  duration: { type: Number, default: 400 },
  easing: {
    type: String,
    default: 'ease-out',
    validator: (value) => ['linear', 'ease-in', 'ease-out', 'ease-in-out'].includes(value)
  },
  extraScale: { type: Number, default: 1 }
})

const canvasRef = ref(null)
const sparks = ref([])
const startTime = ref(null)

let resizeObserver
let resizeTimeout
let animationId

function ease(t) {
  switch (props.easing) {
    case 'linear':
      return t
    case 'ease-in':
      return t * t
    case 'ease-in-out':
      return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    default:
      return t * (2 - t)
  }
}

function resizeCanvas() {
  const canvas = canvasRef.value
  const parent = canvas?.parentElement
  if (!canvas || !parent) return

  const { width, height } = parent.getBoundingClientRect()
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width
    canvas.height = height
  }
}

function scheduleResize() {
  clearTimeout(resizeTimeout)
  resizeTimeout = setTimeout(resizeCanvas, 100)
}

function draw(timestamp) {
  const canvas = canvasRef.value
  if (!canvas) return

  const ctx = canvas.getContext('2d')
  if (!ctx) return

  if (!startTime.value) {
    startTime.value = timestamp
  }

  ctx.clearRect(0, 0, canvas.width, canvas.height)

  sparks.value = sparks.value.filter((spark) => {
    const elapsed = timestamp - spark.startTime
    if (elapsed >= props.duration) {
      return false
    }

    const progress = elapsed / props.duration
    const eased = ease(progress)
    const distance = eased * props.sparkRadius * props.extraScale
    const lineLength = props.sparkSize * (1 - eased)

    const x1 = spark.x + distance * Math.cos(spark.angle)
    const y1 = spark.y + distance * Math.sin(spark.angle)
    const x2 = spark.x + (distance + lineLength) * Math.cos(spark.angle)
    const y2 = spark.y + (distance + lineLength) * Math.sin(spark.angle)

    ctx.strokeStyle = props.sparkColor
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.moveTo(x1, y1)
    ctx.lineTo(x2, y2)
    ctx.stroke()

    return true
  })

  animationId = requestAnimationFrame(draw)
}

function handleClick(event) {
  const canvas = canvasRef.value
  if (!canvas) return

  const rect = canvas.getBoundingClientRect()
  const x = event.clientX - rect.left
  const y = event.clientY - rect.top
  const now = performance.now()

  const nextSparks = Array.from({ length: props.sparkCount }, (_, index) => ({
    x,
    y,
    angle: (2 * Math.PI * index) / props.sparkCount,
    startTime: now
  }))

  sparks.value.push(...nextSparks)
}

function startAnimation() {
  cancelAnimationFrame(animationId)
  animationId = requestAnimationFrame(draw)
}

function stopAnimation() {
  cancelAnimationFrame(animationId)
  animationId = 0
}

onMounted(() => {
  const canvas = canvasRef.value
  const parent = canvas?.parentElement
  if (!parent) return

  resizeCanvas()
  resizeObserver = new ResizeObserver(scheduleResize)
  resizeObserver.observe(parent)
  startAnimation()
})

onUnmounted(() => {
  stopAnimation()
  resizeObserver?.disconnect()
  clearTimeout(resizeTimeout)
})

watch(
  () => [props.sparkColor, props.sparkSize, props.sparkRadius, props.duration, props.easing, props.extraScale],
  () => {
    if (!animationId) {
      startAnimation()
    }
  }
)
</script>

<style scoped>
.click-spark {
  position: relative;
  width: 100%;
  min-height: 100%;
}

.click-spark__canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 9999;
}
</style>
