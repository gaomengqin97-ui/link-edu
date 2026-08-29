<template>
  <div class="training-page">
    <section class="stage stage--fill">
      <video
        v-show="!cameraOn"
        class="stage-video"
        src="/assets/login-bg.mp4"
        poster="/assets/login-bg.png"
        autoplay
        muted
        loop
        playsinline
      ></video>
      <video v-show="cameraOn" ref="camRef" class="stage-video" autoplay muted playsinline></video>
      <div class="scanline" aria-hidden="true"></div>

      <header class="train-hud">
        <div>
          <small>{{ cameraOn ? '镜头监测中' : '演示舞台' }}</small>
          <strong>{{ courseTitle }}</strong>
        </div>
        <div class="hud-meta">
          <span>{{ modeLabel }}</span>
          <span>{{ liveScene }}</span>
          <span>{{ cameraOn ? '摄像头已开' : '未开镜头' }}</span>
        </div>
      </header>

      <div class="monitor-strip" aria-label="训练监测">
        <article v-for="meter in meters" :key="meter.label">
          <em>{{ meter.label }}</em>
          <b>{{ meter.value }}</b>
          <i><s :style="{ width: `${meter.percent}%` }"></s></i>
        </article>
      </div>

      <StageWave :active="running" :progress="progress" />

      <div class="train-dock">
        <div class="timer-block">
          <p>{{ running ? '剩余' : '时长' }}</p>
          <div class="timer-digits">
            <NumberFlow :value="minutes" :format="{ minimumIntegerDigits: 2 }" />
            <span>:</span>
            <NumberFlow :value="seconds" :format="{ minimumIntegerDigits: 2 }" />
          </div>
        </div>

        <div v-if="!running" class="dock-setup">
          <div class="mode-picks">
            <button type="button" :class="{ active: mode === 'fragment' }" @click="mode = 'fragment'">片段 8 分钟</button>
            <button type="button" :class="{ active: mode === 'full' }" @click="mode = 'full'">完整 10 分钟</button>
          </div>
          <div v-if="mode === 'fragment'" class="scene-picks">
            <button
              v-for="item in scenes"
              :key="item.id"
              type="button"
              :class="{ active: scene === item.id }"
              @click="scene = item.id"
            >{{ item.id }}</button>
          </div>
          <p v-else class="dock-hint">完整课会按导入 → 提问 → 板书 → 互动自动推进，不必先选环节。</p>
          <blockquote>{{ prompt }}</blockquote>
        </div>
        <blockquote v-else>{{ prompt }}</blockquote>

        <div class="dock-actions">
          <Magnet>
            <button v-if="!running" class="primary train-cta" type="button" @click="begin">
              开始{{ mode === 'full' ? ' 10 分钟' : ' 8 分钟' }}
            </button>
            <button v-else class="primary train-cta" type="button" @click="finish">结束并生成评课</button>
          </Magnet>
          <button v-if="!running" type="button" class="ghost-link" @click="toggleCamera">
            {{ cameraOn ? '关闭镜头' : '打开镜头观察教态' }}
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import NumberFlow from '@number-flow/vue'
import { useUserMedia } from '@vueuse/core'
import Magnet from '../components/fx/Magnet.vue'
import StageWave from '../components/fx/StageWave.vue'
import { completeTraining, fetchCourses, patchTraining, startTraining } from '../services/dashboard'
import { loadSettings } from '../utils/settings'

const FRAGMENT = 8 * 60
const FULL = 10 * 60
const FULL_PHASES = [
  { id: '导入', until: 0.25 },
  { id: '提问', until: 0.5 },
  { id: '板书', until: 0.75 },
  { id: '互动', until: 1 },
]

const route = useRoute()
const router = useRouter()
const camRef = ref(null)
const cameraOn = ref(false)
const scene = ref('导入')
const mode = ref('fragment')
const running = ref(false)
const remain = ref(FRAGMENT)
const sessionId = ref(null)
const courseId = ref(Number(route.query.courseId) || 1)
const courseTitle = ref('课堂导入与提问设计')
let tick = null
let startedAt = 0

const scenes = [
  { id: '导入', line: '同学们好。今天我们从生活里的一个问题开始——请先看黑板。' },
  { id: '提问', line: '如果把这个现象反过来，会发生什么？请先想 8 秒，再举手。' },
  { id: '板书', line: '请看左侧结构：目标 → 过程 → 结论。例子写在右侧。' },
  { id: '互动', line: '同桌讨论 30 秒。结束后请一组分享，我做 10 秒全班回收。' },
]

const totalSeconds = computed(() => (mode.value === 'full' ? FULL : FRAGMENT))
const modeLabel = computed(() => (mode.value === 'full' ? '完整 10 分钟' : '片段练习'))
const elapsedRatio = computed(() => {
  const spent = totalSeconds.value - remain.value
  return Math.min(1, Math.max(0, spent / totalSeconds.value))
})
const liveScene = computed(() => {
  if (mode.value !== 'full') return scene.value
  const ratio = elapsedRatio.value
  return FULL_PHASES.find((item) => ratio <= item.until)?.id || '互动'
})
const prompt = computed(() => {
  const id = running.value ? liveScene.value : (mode.value === 'full' ? '导入' : scene.value)
  if (mode.value === 'full' && !running.value) {
    return '完整课从导入走到互动。镜头打开后，舞台会铺满整个工作区，便于观察教态。'
  }
  return scenes.find((item) => item.id === id)?.line || ''
})
const minutes = computed(() => Math.floor(remain.value / 60))
const seconds = computed(() => remain.value % 60)
const progress = computed(() => Math.round(elapsedRatio.value * 100))
const elapsedMinutes = computed(() => Math.max(1, Math.round((totalSeconds.value - remain.value) / 60)))
const meters = computed(() => {
  const ratio = elapsedRatio.value
  const camera = cameraOn.value ? 86 : 34
  return [
    { label: '镜头覆盖', value: cameraOn.value ? '已开' : '演示', percent: camera },
    { label: '环节进度', value: `${progress.value}%`, percent: progress.value },
    { label: '等待窗口', value: liveScene.value === '提问' ? '请停 8 秒' : '跟进中', percent: liveScene.value === '提问' ? 72 : 48 + ratio * 30 },
    { label: '回收提示', value: liveScene.value === '互动' ? '全班回收' : '稍后', percent: liveScene.value === '互动' ? 80 : 28 + ratio * 20 },
  ]
})

const { stream, start: startCam, stop: stopCam } = useUserMedia({
  constraints: { video: true, audio: false },
  enabled: false,
})

watch(stream, (value) => {
  if (camRef.value) camRef.value.srcObject = value || null
  cameraOn.value = Boolean(value)
})

watch(
  () => route.query.courseId,
  (value) => {
    if (value) courseId.value = Number(value) || courseId.value
  },
)

watch(mode, (value) => {
  if (!running.value) remain.value = value === 'full' ? FULL : FRAGMENT
})

async function loadCourse() {
  try {
    const items = await fetchCourses()
    const match = items.find((item) => item.id === courseId.value) || items[0]
    if (match) {
      courseId.value = match.id
      courseTitle.value = match.title
    }
  } catch {
    courseTitle.value = '课堂导入与提问设计'
  }
}

loadCourse()

onMounted(async () => {
  const prefs = loadSettings()
  mode.value = prefs.mode === 'full' ? 'full' : 'fragment'
  if (scenes.some((item) => item.id === prefs.scene)) scene.value = prefs.scene
  remain.value = mode.value === 'full' ? FULL : FRAGMENT
  if (prefs.cameraDefault) {
    try {
      await startCam()
    } catch {
      cameraOn.value = false
    }
  }
})

async function toggleCamera() {
  if (cameraOn.value) {
    stopCam()
    return
  }
  try {
    await startCam()
  } catch {
    cameraOn.value = false
  }
}

async function begin() {
  try {
    const session = await startTraining(courseId.value)
    sessionId.value = session.id
  } catch {
    sessionId.value = null
  }
  running.value = true
  remain.value = totalSeconds.value
  startedAt = Date.now()
  tick = setInterval(async () => {
    const spent = Math.floor((Date.now() - startedAt) / 1000)
    remain.value = Math.max(0, totalSeconds.value - spent)
    if (remain.value <= 0) {
      await finish()
      return
    }
    if (spent % 30 === 0 && sessionId.value) {
      patchTraining(sessionId.value, {
        progress_percent: progress.value,
        duration_minutes: elapsedMinutes.value,
      }).catch(() => {})
    }
  }, 1000)
}

async function finish() {
  if (!running.value) return
  running.value = false
  clearInterval(tick)
  tick = null
  stopCam()
  const payload = {
    duration_minutes: elapsedMinutes.value,
    scene: mode.value === 'full' ? '完整' : scene.value,
    mode: mode.value,
  }
  if (!sessionId.value) {
    router.push('/ai-review')
    return
  }
  try {
    const { feedback } = await completeTraining(sessionId.value, payload)
    router.push({ path: '/ai-review', query: { sessionId: sessionId.value, feedbackId: feedback?.id } })
  } catch {
    router.push('/ai-review')
  }
}

onUnmounted(() => {
  clearInterval(tick)
  stopCam()
})
</script>
