import { defineStore } from 'pinia'
import { api } from '../services/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('link_token') || '',
    user: null,
  }),
  actions: {
    async login(payload) {
      const { data } = await api.post('/auth/login', payload, { timeout: 8000 })
      this.token = data.access_token
      this.user = data.user
      localStorage.setItem('link_token', this.token)
      return { access_token: this.token, user: this.user }
    },
    async register(payload) {
      const { data } = await api.post('/auth/register', payload, { timeout: 8000 })
      return data
    },
    async hydrate() {
      if (!this.token) return
      try {
        const { data } = await api.get('/auth/me')
        this.user = data
      } catch {
        /* keep local session so demo still works if API is briefly down */
      }
    },
    logout() {
      this.token = ''
      this.user = null
      localStorage.removeItem('link_token')
    },
  },
})
