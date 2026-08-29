<template>
  <div
    ref="containerRef"
    class="logoloop"
    :class="rootClass"
    :style="rootStyle"
    role="region"
    :aria-label="ariaLabel"
    @mouseenter="onEnter"
    @mouseleave="onLeave"
  >
    <div v-if="fadeOut" class="logoloop-fade logoloop-fade--start" aria-hidden="true"></div>
    <div v-if="fadeOut" class="logoloop-fade logoloop-fade--end" aria-hidden="true"></div>
    <div ref="trackRef" class="logoloop-track">
      <ul
        v-for="copyIndex in copyCount"
        :key="copyIndex"
        class="logoloop-list"
        :ref="copyIndex === 1 ? setSeqRef : undefined"
        :aria-hidden="copyIndex > 1 ? 'true' : undefined"
      >
        <li v-for="(item, itemIndex) in logos" :key="`${copyIndex}-${itemIndex}`" class="logoloop-item">
          <component :is="item.href ? 'a' : 'div'" class="logoloop-link" v-bind="linkProps(item)">
            <img
              v-if="item.src"
              class="logoloop-img"
              :src="item.src"
              :alt="item.alt || item.title || ''"
              :title="item.title"
              loading="lazy"
              decoding="async"
              draggable="false"
            />
            <span v-else class="logoloop-node" :title="item.title">
              <component :is="item.node" v-if="item.node" />
              <span v-else>{{ item.title }}</span>
            </span>
          </component>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps({
  logos: { type: Array, required: true },
  speed: { type: Number, default: 100 },
  direction: { type: String, default: 'left' },
  width: { type: [Number, String], default: '100%' },
  logoHeight: { type: Number, default: 48 },
  gap: { type: Number, default: 48 },
  pauseOnHover: { type: Boolean, default: undefined },
  hoverSpeed: { type: Number, default: undefined },
  fadeOut: { type: Boolean, default: false },
  fadeOutColor: { type: String, default: '#030305' },
  scaleOnHover: { type: Boolean, default: false },
  ariaLabel: { type: String, default: '合作与能力标识' }
})

const MIN_COPIES = 2
const COPY_HEADROOM = 2
const SMOOTH_TAU = 0.25

const containerRef = ref(null)
const trackRef = ref(null)
const seqRef = ref(null)
const copyCount = ref(MIN_COPIES)
const seqWidth = ref(0)
const seqHeight = ref(0)
const isHovered = ref(false)

let rafId = 0
let lastTs = null
let offset = 0
let velocity = 0
let resizeObserver

const isVertical = computed(() => props.direction === 'up' || props.direction === 'down')
const effectiveHoverSpeed = computed(() => {
  if (props.hoverSpeed !== undefined) return props.hoverSpeed
  if (props.pauseOnHover === true) return 0
  if (props.pauseOnHover === false) return undefined
  return 0
})

const targetVelocity = computed(() => {
  const magnitude = Math.abs(props.speed)
  const dirMul = isVertical.value
    ? (props.direction === 'up' ? 1 : -1)
    : (props.direction === 'left' ? 1 : -1)
  const speedMul = props.speed < 0 ? -1 : 1
  return magnitude * dirMul * speedMul
})

const rootClass = computed(() => ({
  'logoloop--vertical': isVertical.value,
  'logoloop--horizontal': !isVertical.value,
  'logoloop--fade': props.fadeOut,
  'logoloop--scale-hover': props.scaleOnHover
}))

const rootStyle = computed(() => ({
  width: typeof props.width === 'number' ? `${props.width}px` : props.width,
  '--logoloop-gap': `${props.gap}px`,
  '--logoloop-logoHeight': `${props.logoHeight}px`,
  '--logoloop-fadeColor': props.fadeOutColor
}))

function setSeqRef(el) {
  seqRef.value = el
}

function linkProps(item) {
  if (!item.href) return {}
  return {
    href: item.href,
    title: item.title,
    target: '_blank',
    rel: 'noreferrer noopener',
    'aria-label': item.ariaLabel || item.title || item.alt || 'logo'
  }
}

function onEnter() {
  if (effectiveHoverSpeed.value !== undefined) isHovered.value = true
}
function onLeave() {
  if (effectiveHoverSpeed.value !== undefined) isHovered.value = false
}

function updateDimensions() {
  const container = containerRef.value
  const seq = seqRef.value
  if (!container || !seq) return
  if (isVertical.value) {
    const parentH = container.parentElement?.clientHeight || 0
    if (parentH > 0) container.style.height = `${Math.ceil(parentH)}px`
    const h = Math.ceil(seq.getBoundingClientRect().height)
    if (h > 0) {
      seqHeight.value = h
      const viewport = container.clientHeight || parentH || h
      copyCount.value = Math.max(MIN_COPIES, Math.ceil(viewport / h) + COPY_HEADROOM)
    }
  } else {
    const w = Math.ceil(seq.getBoundingClientRect().width)
    if (w > 0) {
      seqWidth.value = w
      copyCount.value = Math.max(MIN_COPIES, Math.ceil(container.clientWidth / w) + COPY_HEADROOM)
    }
  }
  if (!rafId) startLoop()
}

function startLoop() {
  stopLoop()
  lastTs = null
  // Even with reduced-motion, keep a gentle crawl so the requested LogoLoop effect remains visible.
  rafId = requestAnimationFrame(animate)
}

function animate(ts) {
  const track = trackRef.value
  if (!track) return
  const seqSize = isVertical.value ? seqHeight.value : seqWidth.value
  if (lastTs == null) lastTs = ts
  const dt = Math.max(0, ts - lastTs) / 1000
  lastTs = ts

  const reduce = typeof window !== 'undefined'
    && window.matchMedia
    && window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const baseTarget = isHovered.value && effectiveHoverSpeed.value !== undefined
    ? effectiveHoverSpeed.value
    : targetVelocity.value
  const target = reduce ? baseTarget * 0.35 : baseTarget
  const easing = 1 - Math.exp(-dt / SMOOTH_TAU)
  velocity += (target - velocity) * easing

  if (seqSize > 0) {
    offset = ((offset + velocity * dt) % seqSize + seqSize) % seqSize
    track.style.transform = isVertical.value
      ? `translate3d(0, ${-offset}px, 0)`
      : `translate3d(${-offset}px, 0, 0)`
  }
  rafId = requestAnimationFrame(animate)
}

function stopLoop() {
  if (rafId) cancelAnimationFrame(rafId)
  rafId = 0
  lastTs = null
}

function bindImageLoads() {
  const root = containerRef.value
  if (!root) return
  root.querySelectorAll('img').forEach((img) => {
    if (img.dataset.loopBound) return
    img.dataset.loopBound = '1'
    if (img.complete) updateDimensions()
    else {
      img.addEventListener('load', updateDimensions, { once: true })
      img.addEventListener('error', updateDimensions, { once: true })
    }
  })
}

onMounted(async () => {
  await nextTick()
  updateDimensions()
  bindImageLoads()
  requestAnimationFrame(() => {
    updateDimensions()
    bindImageLoads()
  })
  window.setTimeout(() => {
    updateDimensions()
    bindImageLoads()
    startLoop()
  }, 160)
  if (typeof ResizeObserver !== 'undefined') {
    resizeObserver = new ResizeObserver(() => updateDimensions())
    if (containerRef.value) resizeObserver.observe(containerRef.value)
    if (seqRef.value) resizeObserver.observe(seqRef.value)
  } else {
    window.addEventListener('resize', updateDimensions)
  }
  startLoop()
})

onUnmounted(() => {
  stopLoop()
  resizeObserver?.disconnect()
  window.removeEventListener('resize', updateDimensions)
})

watch(() => [props.logos, props.gap, props.logoHeight, props.direction], async () => {
  await nextTick()
  bindImageLoads()
  updateDimensions()
  startLoop()
})
</script>

<style scoped>
.logoloop {
  position: relative;
  overflow: hidden;
  user-select: none;
}
.logoloop--horizontal { width: 100%; }
.logoloop--vertical { height: 100%; display: inline-block; }
.logoloop-track {
  display: flex;
  width: max-content;
  will-change: transform;
}
.logoloop--vertical .logoloop-track { flex-direction: column; height: max-content; width: auto; }
.logoloop-list {
  display: flex;
  align-items: center;
  list-style: none;
  margin: 0;
  padding: 0;
  gap: var(--logoloop-gap);
  padding-inline-end: var(--logoloop-gap);
}
.logoloop--vertical .logoloop-list {
  flex-direction: column;
  padding-inline-end: 0;
  padding-block-end: var(--logoloop-gap);
}
.logoloop-item {
  flex: none;
  display: grid;
  place-items: center;
  height: var(--logoloop-logoHeight);
}
.logoloop-link {
  color: inherit;
  text-decoration: none;
  display: grid;
  place-items: center;
  transition: transform .25s ease, opacity .25s ease, filter .25s ease;
  opacity: .92;
  filter: drop-shadow(0 0 12px rgba(180, 92, 255, .22));
}
.logoloop-link:hover { opacity: 1; }
.logoloop--scale-hover .logoloop-link:hover { transform: scale(1.18); }
.logoloop-img,
.logoloop-node :deep(svg) {
  height: var(--logoloop-logoHeight);
  width: auto;
  display: block;
}
.logoloop-node {
  display: grid;
  place-items: center;
  color: #ffffff;
}
.logoloop-node :deep(svg) {
  stroke-width: 1.6;
  color: #ffffff;
}
.logoloop-fade {
  position: absolute;
  z-index: 2;
  pointer-events: none;
}
.logoloop--horizontal .logoloop-fade {
  top: 0;
  bottom: 0;
  width: min(96px, 18%);
}
.logoloop--horizontal .logoloop-fade--start {
  left: 0;
  background: linear-gradient(90deg, var(--logoloop-fadeColor), transparent);
}
.logoloop--horizontal .logoloop-fade--end {
  right: 0;
  background: linear-gradient(270deg, var(--logoloop-fadeColor), transparent);
}
.logoloop--vertical .logoloop-fade {
  left: 0;
  right: 0;
  height: min(72px, 18%);
}
.logoloop--vertical .logoloop-fade--start {
  top: 0;
  background: linear-gradient(180deg, var(--logoloop-fadeColor), transparent);
}
.logoloop--vertical .logoloop-fade--end {
  bottom: 0;
  background: linear-gradient(0deg, var(--logoloop-fadeColor), transparent);
}
</style>
