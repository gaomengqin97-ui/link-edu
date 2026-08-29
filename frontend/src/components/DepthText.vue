<template>
  <span
    ref="rootRef"
    class="depth-text"
    :style="rootStyle"
  >
    <span ref="stageRef" class="depth-text__stage">
      <span
        v-for="layer in depthLayers"
        :key="layer.index"
        class="depth-text__layer"
        aria-hidden="true"
        :style="{ color: layer.color, transform: layer.transform }"
      >{{ text }}</span>
      <span class="depth-text__face">{{ text }}</span>
    </span>
  </span>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'

const MAX_LAYERS = 64
const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

const props = defineProps({
  text: { type: String, default: 'Elevate' },
  layers: { type: Number, default: 34 },
  depth: { type: Number, default: 2.4 },
  faceColor: { type: String, default: '#f8fafc' },
  depthColor: { type: String, default: '#7c3aed' },
  tilt: { type: Number, default: 7.5 },
  pointerTracking: { type: Boolean, default: true },
  smoothing: { type: Number, default: 0.14 },
  perspective: { type: Number, default: 900 },
  autoOrbit: { type: Boolean, default: true },
  orbitSpeed: { type: Number, default: 0.35 },
  fontSize: { type: String, default: 'clamp(3rem, 12vw, 7rem)' },
  fontWeight: { type: [Number, String], default: 900 },
  fontFamily: { type: String, default: '' },
  letterSpacing: { type: String, default: '-0.065em' },
  lineHeight: { type: [Number, String], default: 0.86 },
  shearX: { type: Number, default: 0.38 },
  shearY: { type: Number, default: 0.38 },
  shadow: { type: Boolean, default: true },
  track: { type: String, default: 'viewport' }
})

const rootRef = ref(null)
const stageRef = ref(null)

const safeLayers = computed(() => clamp(Math.round(Number(props.layers) || 1), 2, MAX_LAYERS))
const safeDepth = computed(() => clamp(Number(props.depth) || 0, 0, 12))
const safeTilt = computed(() => clamp(Number(props.tilt) || 0, 0, 28))
const safeSmoothing = computed(() => clamp(Number(props.smoothing) || 0.14, 0.02, 0.4))
const safePerspective = computed(() => clamp(Number(props.perspective) || 900, 300, 2000))
const safeOrbitSpeed = computed(() => clamp(Number(props.orbitSpeed) || 0, 0, 2))
const baseRotation = computed(() => ({
  x: -safeTilt.value * 0.28,
  y: safeTilt.value * 0.36
}))

function getLayerColor(index, total) {
  const progress = total <= 1 ? 1 : index / total
  const eased = progress * progress
  const faceMix = Math.round((1 - eased) * 72 + 4)
  return `color-mix(in srgb, ${props.faceColor} ${faceMix}%, ${props.depthColor})`
}

const depthLayers = computed(() =>
  Array.from({ length: safeLayers.value }, (_, layerIndex) => {
    const index = safeLayers.value - layerIndex
    const x = index * safeDepth.value * props.shearX
    const y = index * safeDepth.value * props.shearY
    return {
      index,
      color: getLayerColor(index, safeLayers.value),
      transform: `translate3d(${x}px, ${y}px, ${-index * safeDepth.value}px)`
    }
  })
)

const rootStyle = computed(() => ({
  '--depth-text-perspective': `${safePerspective.value}px`,
  '--depth-text-font-size': props.fontSize,
  '--depth-text-font-weight': String(props.fontWeight),
  '--depth-text-font-family': props.fontFamily || 'inherit',
  '--depth-text-letter-spacing': props.letterSpacing,
  '--depth-text-line-height': String(props.lineHeight),
  '--depth-text-face-color': props.faceColor,
  '--depth-text-depth-color': props.depthColor,
  '--depth-text-shadow': props.shadow
    ? `0 18px 28px color-mix(in srgb, ${props.depthColor} 30%, transparent), 0 3px 6px rgba(0, 0, 0, 0.24)`
    : 'none'
}))

function getTransform(rotateX, rotateY) {
  return `rotateX(${rotateX.toFixed(2)}deg) rotateY(${rotateY.toFixed(2)}deg)`
}

function getTrackingRect(root) {
  if (props.track === 'self') return root.getBoundingClientRect()
  if (props.track === 'hero') {
    const hero = root.closest('.hero')
    if (hero) return hero.getBoundingClientRect()
  }
  return {
    left: 0,
    top: 0,
    width: window.innerWidth || 1,
    height: window.innerHeight || 1
  }
}

let stopMotion = null

function startMotion() {
  stopMotion?.()
  const root = rootRef.value
  const stage = stageRef.value
  if (!root || !stage) return

  // 鼠标跟随是交互核心，不因系统 reduce-motion 关闭
  const canTrackPointer = !!props.pointerTracking
  const canOrbit = !!props.autoOrbit && !window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const origin = baseRotation.value
  const followTilt = safeTilt.value

  let frameId = 0
  let activePointer = false
  let lastPointerAt = 0
  let lastMoveAt = 0
  const startTime = performance.now()
  const current = { x: origin.x, y: origin.y }
  const target = { x: origin.x, y: origin.y }

  const applyTransform = () => {
    stage.style.transform = getTransform(current.x, current.y)
  }

  const syncTargetFromEvent = (event) => {
    const rect = getTrackingRect(root)
    if (!rect.width || !rect.height) return false
    const inside = event.clientX >= rect.left && event.clientX <= rect.right
      && event.clientY >= rect.top && event.clientY <= rect.bottom
    if (!inside) {
      activePointer = false
      target.x = origin.x
      target.y = origin.y
      return false
    }
    const nx = clamp((event.clientX - (rect.left + rect.width / 2)) / (rect.width * 0.5), -1, 1)
    const ny = clamp((event.clientY - (rect.top + rect.height / 2)) / (rect.height * 0.5), -1, 1)
    activePointer = true
    lastPointerAt = performance.now()
    target.x = -ny * followTilt
    target.y = nx * followTilt
    return true
  }

  const tick = (now) => {
    const pointerIsFresh = activePointer && now - lastPointerAt < 1600
    if (!pointerIsFresh) {
      if (canOrbit) {
        const elapsed = (now - startTime) / 1000
        const orbit = elapsed * safeOrbitSpeed.value * Math.PI * 2
        target.x = origin.x + Math.sin(orbit) * followTilt * 0.16
        target.y = origin.y + Math.cos(orbit * 0.85) * followTilt * 0.16
      } else {
        target.x = origin.x
        target.y = origin.y
      }
    }
    const ease = pointerIsFresh ? Math.min(0.3, safeSmoothing.value + 0.12) : safeSmoothing.value
    current.x += (target.x - current.x) * ease
    current.y += (target.y - current.y) * ease
    applyTransform()
    const settled = Math.abs(target.x - current.x) < 0.02 && Math.abs(target.y - current.y) < 0.02
    if (canOrbit || pointerIsFresh || !settled) {
      frameId = requestAnimationFrame(tick)
    } else {
      frameId = 0
    }
  }

  const ensureTick = () => {
    if (!frameId) frameId = requestAnimationFrame(tick)
  }

  if (canTrackPointer) {
    const onMove = (event) => {
      const now = performance.now()
      if (now - lastMoveAt < 16) return
      lastMoveAt = now
      syncTargetFromEvent(event)
      ensureTick()
    }
    const onLeave = () => {
      activePointer = false
      target.x = origin.x
      target.y = origin.y
      ensureTick()
    }
    // window 监听最稳，不被其它层挡住
    window.addEventListener('pointermove', onMove, { passive: true })
    window.addEventListener('blur', onLeave)
    stopMotion = () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('blur', onLeave)
      cancelAnimationFrame(frameId)
      frameId = 0
      stopMotion = null
    }
  } else {
    stopMotion = () => {
      cancelAnimationFrame(frameId)
      frameId = 0
      stopMotion = null
    }
  }

  applyTransform()
  if (canOrbit) ensureTick()
}

onMounted(() => { nextTick(startMotion) })
onUnmounted(() => stopMotion?.())
watch(
  () => [
    props.autoOrbit,
    props.pointerTracking,
    props.track,
    safeTilt.value,
    safeSmoothing.value,
    safeOrbitSpeed.value,
    baseRotation.value.x,
    baseRotation.value.y
  ],
  () => nextTick(startMotion)
)
</script>

<style>
.depth-text {
  display: inline-block;
  perspective: var(--depth-text-perspective);
  perspective-origin: 50% 48%;
  isolation: isolate;
  text-shadow: none;
  vertical-align: top;
  pointer-events: none;
}

.depth-text__stage {
  position: relative;
  display: inline-grid;
  place-items: center;
  transform-style: preserve-3d;
  transform: rotateX(-2.4deg) rotateY(3.15deg);
  transform-origin: 50% 50%;
  will-change: transform;
}

.depth-text__layer,
.depth-text__face {
  grid-area: 1 / 1;
  display: inline-block;
  font-family: var(--depth-text-font-family);
  font-size: var(--depth-text-font-size);
  font-weight: var(--depth-text-font-weight);
  line-height: var(--depth-text-line-height);
  letter-spacing: var(--depth-text-letter-spacing);
  white-space: nowrap;
  user-select: none;
  transform-style: preserve-3d;
  backface-visibility: hidden;
}

.depth-text__layer {
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}

.depth-text__face {
  position: relative;
  z-index: 1;
  color: var(--depth-text-face-color);
  text-shadow: var(--depth-text-shadow);
  transform: translateZ(0.6px);
}
</style>
