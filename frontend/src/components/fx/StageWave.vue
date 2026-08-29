<template>
  <div ref="hostRef" class="stage-wave" aria-hidden="true">
    <canvas v-show="fallback" ref="canvasRef"></canvas>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import WaveSurfer from 'wavesurfer.js'

const props = defineProps({
  progress: { type: Number, default: 0 },
  active: { type: Boolean, default: false },
})

const hostRef = ref(null)
const canvasRef = ref(null)
const fallback = ref(false)
let wavesurfer = null
let raf = 0

const peaks = Array.from({ length: 96 }, (_, i) => 0.18 + Math.abs(Math.sin(i / 2.6)) * 0.72)

function drawFallback() {
  const canvas = canvasRef.value
  const host = hostRef.value
  if (!canvas || !host) return
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  const width = host.clientWidth || 320
  const height = 72
  canvas.width = width * dpr
  canvas.height = height * dpr
  canvas.style.width = `${width}px`
  canvas.style.height = `${height}px`
  const ctx = canvas.getContext('2d')
  ctx.scale(dpr, dpr)
  ctx.clearRect(0, 0, width, height)
  const gap = 3
  const bar = 2
  const count = Math.floor(width / (bar + gap))
  const filled = (props.progress / 100) * count
  for (let i = 0; i < count; i += 1) {
    const h = peaks[i % peaks.length] * height * 0.9
    ctx.fillStyle = i < filled ? '#ff7a18' : 'rgba(180,92,255,.42)'
    ctx.fillRect(i * (bar + gap), (height - h) / 2, bar, h)
  }
}

async function setup() {
  if (!hostRef.value) return
  try {
    wavesurfer = WaveSurfer.create({
      container: hostRef.value,
      height: 72,
      waveColor: 'rgba(180,92,255,.42)',
      progressColor: '#ff7a18',
      cursorWidth: 0,
      barWidth: 2,
      barGap: 3,
      barRadius: 0,
      interact: false,
      hideScrollbar: true,
    })
    await wavesurfer.load('', [peaks], 8)
    wavesurfer.setTime((props.progress / 100) * 8)
  } catch {
    fallback.value = true
    wavesurfer?.destroy()
    wavesurfer = null
    drawFallback()
  }
}

watch(
  () => props.progress,
  (value) => {
    if (wavesurfer) wavesurfer.setTime((value / 100) * 8)
    else drawFallback()
  },
)

onMounted(setup)
onUnmounted(() => {
  cancelAnimationFrame(raf)
  wavesurfer?.destroy()
})
</script>
