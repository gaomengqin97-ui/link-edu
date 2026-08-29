import axios from 'axios'
import { useBusyStore } from '../stores/busy'

export const api = axios.create({ baseURL: '/api' })

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('link_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  try {
    useBusyStore().begin()
  } catch {
    /* pinia 尚未就绪时忽略 */
  }
  return config
})

function releaseBusy() {
  try {
    useBusyStore().end()
  } catch {
    /* pinia 尚未就绪时忽略 */
  }
}

api.interceptors.response.use(
  (response) => {
    releaseBusy()
    return response
  },
  (error) => {
    releaseBusy()
    return Promise.reject(error)
  },
)

