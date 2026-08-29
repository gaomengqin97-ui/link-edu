import { defineStore } from 'pinia'

let hideTimer = 0
const SHOW_AFTER_MS = 320

export const useBusyStore = defineStore('busy', {
  state: () => ({
    pending: 0,
    visible: false,
  }),
  actions: {
    begin() {
      this.pending += 1
      if (this.pending === 1) {
        clearTimeout(hideTimer)
        hideTimer = window.setTimeout(() => {
          if (this.pending > 0) this.visible = true
        }, SHOW_AFTER_MS)
      }
    },
    end() {
      this.pending = Math.max(0, this.pending - 1)
      if (this.pending === 0) {
        clearTimeout(hideTimer)
        this.visible = false
      }
    },
  },
})
