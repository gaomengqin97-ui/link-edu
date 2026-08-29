import { loadSettings } from './settings'

export function timeGreeting(date = new Date()) {
  const hour = date.getHours()
  if (hour >= 5 && hour < 11) {
    return { zh: '早上好', en: 'GOOD MORNING' }
  }
  if (hour >= 11 && hour < 14) {
    return { zh: '中午好', en: 'GOOD NOON' }
  }
  if (hour >= 14 && hour < 18) {
    return { zh: '下午好', en: 'GOOD AFTERNOON' }
  }
  return { zh: '晚上好', en: 'GOOD EVENING' }
}

export function formatGreeting(name = '林晓', lang = loadSettings().greetingLang) {
  const { zh, en } = timeGreeting()
  if (lang === 'zh') {
    return { kicker: zh, title: `${zh}，${name}`, periodZh: zh, periodEn: zh }
  }
  if (lang === 'en') {
    return { kicker: en, title: `${en} · ${name}`, periodZh: en, periodEn: en }
  }
  return { kicker: en, title: `${zh}，${name}`, periodZh: zh, periodEn: en }
}
