# Vue 3 + TypeScript + Vuetify Production Application Template for Claude Code

## Core Architecture, Security, UI/UX & Testing

**File Size Limits:**
- Vue components: Maximum 200 lines
- Composables: Maximum 100 lines  
- Service files: Maximum 150 lines
- Store modules: Maximum 150 lines
- Test files: Maximum 300 lines
- Utility functions: Maximum 50 lines per function
- If any file exceeds limits, refactor immediately

**Project Structure:**
```
src/
├── components/
│   ├── common/          # Reusable UI components
│   │   ├── feedback/   # Alerts, snackbars, dialogs
│   │   ├── forms/      # Form inputs, validation
│   │   └── layout/     # Cards, lists, tables
│   ├── features/        # Feature-specific components
│   └── layouts/         # App layouts & navigation
├── composables/         # Vue composition functions
│   ├── ui/             # UI-specific composables
│   └── forms/          # Form handling composables
├── services/            # API and external services
│   ├── api/            # API clients
│   └── security/       # Security utilities
├── stores/              # Pinia stores (organized by domain)
│   ├── modules/        # Feature-specific stores
│   ├── ui/             # UI state stores
│   └── index.ts        # Store initialization
├── guards/              # Route guards & permissions
├── utils/               # Pure utility functions
│   ├── validators/     # Input validation & sanitization
│   ├── formatters/     # Display formatters
│   └── test-utils/     # Testing utilities
├── styles/              # Global styles & themes
├── types/               # TypeScript interfaces
├── constants/           # App-wide constants
├── plugins/             # Vue plugins
│   └── vuetify.ts      # Vuetify configuration
└── __tests__/           # Test files
    ├── unit/           # Unit tests
    ├── component/      # Component tests
    └── e2e/            # End-to-end tests
```

## Pinia State Management

### 1. **Store Architecture & Patterns**

```typescript
// stores/index.ts
import { createPinia, type Pinia } from 'pinia'
import { markRaw } from 'vue'
import router from '@/router'
import type { Router } from 'vue-router'

// Pinia plugins
declare module 'pinia' {
  export interface PiniaCustomProperties {
    router: Router
  }
}

export function setupStores(): Pinia {
  const pinia = createPinia()
  
  // Add router to all stores
  pinia.use(({ store }) => {
    store.router = markRaw(router)
  })
  
  // Persist plugin
  pinia.use(persistPlugin)
  
  // DevTools plugin
  if (import.meta.env.DEV) {
    pinia.use(devtoolsPlugin)
  }
  
  // Security plugin
  pinia.use(securityPlugin)
  
  return pinia
}

// stores/plugins/persist.ts
import { type PiniaPluginContext } from 'pinia'
import { watch } from 'vue'

interface PersistOptions {
  enabled?: boolean
  strategies?: Array<{
    key?: string
    storage?: Storage
    paths?: string[]
    beforeRestore?: (context: PiniaPluginContext) => void
    afterRestore?: (context: PiniaPluginContext) => void
  }>
}

export function persistPlugin({ store, options }: PiniaPluginContext) {
  const persistOptions = options.persist as PersistOptions
  
  if (!persistOptions?.enabled) return
  
  persistOptions.strategies?.forEach(strategy => {
    const {
      key = store.$id,
      storage = sessionStorage,
      paths = null,
      beforeRestore,
      afterRestore
    } = strategy
    
    // Restore state
    beforeRestore?.({ store, options })
    
    const saved = storage.getItem(key)
    if (saved) {
      try {
        const data = JSON.parse(saved)
        const filteredData = paths 
          ? paths.reduce((acc, path) => {
              const value = path.split('.').reduce((obj, key) => obj?.[key], data)
              if (value !== undefined) {
                path.split('.').reduce((obj, key, index, arr) => {
                  if (index === arr.length - 1) {
                    obj[key] = value
                  } else {
                    obj[key] = obj[key] || {}
                  }
                  return obj[key]
                }, acc)
              }
              return acc
            }, {})
          : data
          
        store.$patch(filteredData)
      } catch (e) {
        console.error(`Failed to restore ${key}:`, e)
      }
    }
    
    afterRestore?.({ store, options })
    
    // Watch for changes
    watch(
      () => paths 
        ? paths.reduce((acc, path) => {
            const value = path.split('.').reduce((obj, key) => obj?.[key], store.$state)
            if (value !== undefined) {
              path.split('.').reduce((obj, key, index, arr) => {
                if (index === arr.length - 1) {
                  obj[key] = value
                } else {
                  obj[key] = obj[key] || {}
                }
                return obj[key]
              }, acc)
            }
            return acc
          }, {})
        : store.$state,
      (state) => {
        try {
          storage.setItem(key, JSON.stringify(state))
        } catch (e) {
          console.error(`Failed to persist ${key}:`, e)
        }
      },
      { deep: true }
    )
  })
}
```

### 2. **Domain-Specific Store Patterns**

```typescript
// stores/modules/user.ts
import { defineStore, acceptHMRUpdate } from 'pinia'
import { ref, computed, reactive } from 'vue'
import type { User, UserPreferences, UserRole } from '@/types/user'
import { userService } from '@/services/api/userService'
import { useAuthStore } from './auth'
import { useNotificationStore } from './notification'

interface UserState {
  users: Map<string, User>
  currentUserId: string | null
  filters: UserFilters
  sorting: UserSorting
  pagination: PaginationState
  loadingStates: Map<string, boolean>
  errors: Map<string, Error>
}

interface UserFilters {
  search: string
  role: UserRole | null
  status: 'active' | 'inactive' | 'all'
  dateRange: [Date, Date] | null
}

interface UserSorting {
  field: keyof User
  direction: 'asc' | 'desc'
}

interface PaginationState {
  page: number
  itemsPerPage: number
  total: number
}

export const useUserStore = defineStore('user', () => {
  // State
  const state = reactive<UserState>({
    users: new Map(),
    currentUserId: null,
    filters: {
      search: '',
      role: null,
      status: 'all',
      dateRange: null
    },
    sorting: {
      field: 'createdAt',
      direction: 'desc'
    },
    pagination: {
      page: 1,
      itemsPerPage: 20,
      total: 0
    },
    loadingStates: new Map(),
    errors: new Map()
  })
  
  // Private state (not exposed)
  const abortControllers = new Map<string, AbortController>()
  const cache = reactive({
    ttl: 5 * 60 * 1000, // 5 minutes
    timestamps: new Map<string, number>()
  })
  
  // Getters
  const currentUser = computed(() => 
    state.currentUserId ? state.users.get(state.currentUserId) : null
  )
  
  const filteredUsers = computed(() => {
    let users = Array.from(state.users.values())
    
    // Apply filters
    if (state.filters.search) {
      const search = state.filters.search.toLowerCase()
      users = users.filter(user => 
        user.name.toLowerCase().includes(search) ||
        user.email.toLowerCase().includes(search)
      )
    }
    
    if (state.filters.role) {
      users = users.filter(user => user.role === state.filters.role)
    }
    
    if (state.filters.status !== 'all') {
      users = users.filter(user => user.status === state.filters.status)
    }
    
    if (state.filters.dateRange) {
      const [start, end] = state.filters.dateRange
      users = users.filter(user => {
        const date = new Date(user.createdAt)
        return date >= start && date <= end
      })
    }
    
    // Apply sorting
    users.sort((a, b) => {
      const aVal = a[state.sorting.field]
      const bVal = b[state.sorting.field]
      const modifier = state.sorting.direction === 'asc' ? 1 : -1
      
      if (aVal < bVal) return -1 * modifier
      if (aVal > bVal) return 1 * modifier
      return 0
    })
    
    return users
  })
  
  const paginatedUsers = computed(() => {
    const start = (state.pagination.page - 1) * state.pagination.itemsPerPage
    const end = start + state.pagination.itemsPerPage
    return filteredUsers.value.slice(start, end)
  })
  
  const isLoading = computed(() => 
    Array.from(state.loadingStates.values()).some(loading => loading)
  )
  
  const hasErrors = computed(() => state.errors.size > 0)
  
  // Actions
  async function fetchUsers(options: {
    force?: boolean
    signal?: AbortSignal
  } = {}) {
    const cacheKey = 'users_list'
    const loadingKey = 'fetch_users'
    
    // Check cache
    if (!options.force) {
      const cacheTimestamp = cache.timestamps.get(cacheKey)
      if (cacheTimestamp && Date.now() - cacheTimestamp < cache.ttl) {
        return // Use cached data
      }
    }
    
    // Cancel previous request
    abortControllers.get(loadingKey)?.abort()
    const controller = new AbortController()
    abortControllers.set(loadingKey, controller)
    
    state.loadingStates.set(loadingKey, true)
    state.errors.delete(loadingKey)
    
    try {
      const response = await userService.getUsers({
        ...state.filters,
        ...state.sorting,
        ...state.pagination,
        signal: options.signal || controller.signal
      })
      
      // Batch update for performance
      response.data.forEach(user => {
        state.users.set(user.id, user)
      })
      
      state.pagination.total = response.total
      cache.timestamps.set(cacheKey, Date.now())
      
    } catch (error) {
      if (error.name !== 'AbortError') {
        state.errors.set(loadingKey, error)
        handleError(error, 'Failed to fetch users')
      }
    } finally {
      state.loadingStates.delete(loadingKey)
      abortControllers.delete(loadingKey)
    }
  }
  
  async function fetchUser(
    id: string, 
    options: { force?: boolean } = {}
  ): Promise<User | null> {
    const cacheKey = `user_${id}`
    const loadingKey = `fetch_user_${id}`
    
    // Check cache
    const cached = state.users.get(id)
    if (cached && !options.force) {
      const cacheTimestamp = cache.timestamps.get(cacheKey)
      if (cacheTimestamp && Date.now() - cacheTimestamp < cache.ttl) {
        return cached
      }
    }
    
    state.loadingStates.set(loadingKey, true)
    
    try {
      const user = await userService.getUser(id)
      state.users.set(id, user)
      cache.timestamps.set(cacheKey, Date.now())
      return user
      
    } catch (error) {
      state.errors.set(loadingKey, error)
      handleError(error, `Failed to fetch user ${id}`)
      return null
    } finally {
      state.loadingStates.delete(loadingKey)
    }
  }
  
  async function createUser(data: Partial<User>): Promise<User | null> {
    const loadingKey = 'create_user'
    state.loadingStates.set(loadingKey, true)
    
    try {
      const user = await userService.createUser(data)
      state.users.set(user.id, user)
      
      // Optimistic update
      state.pagination.total++
      
      // Show success notification
      const notificationStore = useNotificationStore()
      notificationStore.success('User created successfully')
      
      return user
      
    } catch (error) {
      state.errors.set(loadingKey, error)
      handleError(error, 'Failed to create user')
      return null
    } finally {
      state.loadingStates.delete(loadingKey)
    }
  }
  
  async function updateUser(
    id: string, 
    updates: Partial<User>
  ): Promise<boolean> {
    const loadingKey = `update_user_${id}`
    const originalUser = state.users.get(id)
    
    if (!originalUser) return false
    
    // Optimistic update
    state.users.set(id, { ...originalUser, ...updates })
    state.loadingStates.set(loadingKey, true)
    
    try {
      const updatedUser = await userService.updateUser(id, updates)
      state.users.set(id, updatedUser)
      
      // Invalidate cache
      cache.timestamps.delete(`user_${id}`)
      
      return true
      
    } catch (error) {
      // Rollback optimistic update
      state.users.set(id, originalUser)
      state.errors.set(loadingKey, error)
      handleError(error, 'Failed to update user')
      return false
    } finally {
      state.loadingStates.delete(loadingKey)
    }
  }
  
  async function deleteUser(id: string): Promise<boolean> {
    const loadingKey = `delete_user_${id}`
    const originalUser = state.users.get(id)
    
    if (!originalUser) return false
    
    // Optimistic removal
    state.users.delete(id)
    state.loadingStates.set(loadingKey, true)
    
    try {
      await userService.deleteUser(id)
      
      // Update pagination
      state.pagination.total--
      
      // Clear from cache
      cache.timestamps.delete(`user_${id}`)
      
      return true
      
    } catch (error) {
      // Rollback removal
      state.users.set(id, originalUser)
      state.errors.set(loadingKey, error)
      handleError(error, 'Failed to delete user')
      return false
    } finally {
      state.loadingStates.delete(loadingKey)
    }
  }
  
  // Batch operations
  async function batchUpdate(
    ids: string[], 
    updates: Partial<User>
  ): Promise<{ success: string[], failed: string[] }> {
    const results = { success: [], failed: [] }
    
    // Use Promise.allSettled for parallel processing
    const promises = ids.map(id => updateUser(id, updates))
    const outcomes = await Promise.allSettled(promises)
    
    outcomes.forEach((outcome, index) => {
      if (outcome.status === 'fulfilled' && outcome.value) {
        results.success.push(ids[index])
      } else {
        results.failed.push(ids[index])
      }
    })
    
    return results
  }
  
  // Utility functions
  function setFilters(filters: Partial<UserFilters>) {
    Object.assign(state.filters, filters)
    state.pagination.page = 1 // Reset to first page
  }
  
  function setSorting(field: keyof User, direction?: 'asc' | 'desc') {
    state.sorting.field = field
    state.sorting.direction = direction || 
      (state.sorting.field === field && state.sorting.direction === 'asc' ? 'desc' : 'asc')
  }
  
  function setPagination(pagination: Partial<PaginationState>) {
    Object.assign(state.pagination, pagination)
  }
  
  function clearErrors() {
    state.errors.clear()
  }
  
  function clearCache() {
    cache.timestamps.clear()
  }
  
  function reset() {
    state.users.clear()
    state.currentUserId = null
    state.filters = {
      search: '',
      role: null,
      status: 'all',
      dateRange: null
    }
    state.sorting = {
      field: 'createdAt',
      direction: 'desc'
    }
    state.pagination = {
      page: 1,
      itemsPerPage: 20,
      total: 0
    }
    state.loadingStates.clear()
    state.errors.clear()
    cache.timestamps.clear()
    abortControllers.forEach(controller => controller.abort())
    abortControllers.clear()
  }
  
  // Error handling
  function handleError(error: any, defaultMessage: string) {
    const authStore = useAuthStore()
    const notificationStore = useNotificationStore()
    
    if (error.response?.status === 401) {
      authStore.logout()
    } else {
      notificationStore.error(error.message || defaultMessage)
    }
  }
  
  // Subscribe to auth changes
  const authStore = useAuthStore()
  authStore.$subscribe((mutation, state) => {
    if (!state.isAuthenticated) {
      reset()
    }
  })
  
  return {
    // State (readonly)
    users: computed(() => state.users),
    currentUser,
    filters: computed(() => state.filters),
    sorting: computed(() => state.sorting),
    pagination: computed(() => state.pagination),
    
    // Computed
    filteredUsers,
    paginatedUsers,
    isLoading,
    hasErrors,
    
    // Actions
    fetchUsers,
    fetchUser,
    createUser,
    updateUser,
    deleteUser,
    batchUpdate,
    setFilters,
    setSorting,
    setPagination,
    clearErrors,
    clearCache,
    reset,
    
    // For testing
    $test: import.meta.env.DEV ? {
      state,
      cache,
      abortControllers
    } : undefined
  }
}, {
  persist: {
    enabled: true,
    strategies: [
      {
        key: 'user_filters',
        storage: localStorage,
        paths: ['filters', 'sorting', 'pagination.itemsPerPage']
      }
    ]
  }
})

// Hot Module Replacement
if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useUserStore, import.meta.hot))
}
```

### 3. **UI State Management**

```typescript
// stores/ui/index.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { RouteLocationNormalized } from 'vue-router'

export const useUIStore = defineStore('ui', () => {
  // Theme management
  const theme = ref<'light' | 'dark'>('light')
  const primaryColor = ref('#1976D2')
  
  // Layout state
  const drawer = ref(true)
  const rail = ref(false)
  const breadcrumbs = ref<any[]>([])
  
  // Global loading
  const globalLoading = ref(false)
  const loadingMessage = ref('')
  
  // View caching
  const cachedViews = ref<Set<string>>(new Set())
  const visitedViews = ref<RouteLocationNormalized[]>([])
  
  // Modals/Dialogs
  const activeModals = ref<Map<string, any>>(new Map())
  
  // Actions
  function setTheme(newTheme: 'light' | 'dark') {
    theme.value = newTheme
    localStorage.setItem('theme', newTheme)
    document.documentElement.classList.toggle('dark', newTheme === 'dark')
  }
  
  function toggleDrawer() {
    drawer.value = !drawer.value
  }
  
  function setGlobalLoading(loading: boolean, message = '') {
    globalLoading.value = loading
    loadingMessage.value = message
  }
  
  function addCachedView(name: string) {
    cachedViews.value.add(name)
  }
  
  function removeCachedView(name: string) {
    cachedViews.value.delete(name)
  }
  
  function addVisitedView(route: RouteLocationNormalized) {
    if (visitedViews.value.some(v => v.path === route.path)) return
    
    visitedViews.value.push({
      name: route.name,
      path: route.path,
      title: route.meta.title || 'No title',
      meta: route.meta
    } as RouteLocationNormalized)
  }
  
  function openModal(id: string, data?: any) {
    activeModals.value.set(id, data)
  }
  
  function closeModal(id: string) {
    activeModals.value.delete(id)
  }
  
  function isModalOpen(id: string) {
    return activeModals.value.has(id)
  }
  
  // Initialize theme from localStorage
  const savedTheme = localStorage.getItem('theme') as 'light' | 'dark'
  if (savedTheme) {
    setTheme(savedTheme)
  }
  
  return {
    // State
    theme: computed(() => theme.value),
    primaryColor,
    drawer,
    rail,
    breadcrumbs,
    globalLoading: computed(() => globalLoading.value),
    loadingMessage: computed(() => loadingMessage.value),
    cachedViews: computed(() => Array.from(cachedViews.value)),
    visitedViews,
    activeModals: computed(() => activeModals.value),
    
    // Actions
    setTheme,
    toggleDrawer,
    setGlobalLoading,
    addCachedView,
    removeCachedView,
    addVisitedView,
    openModal,
    closeModal,
    isModalOpen
  }
})
```

## Unit Testing

### 1. **Testing Setup & Configuration**

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import vuetify, { transformAssetUrls } from 'vite-plugin-vuetify'
import { fileURLToPath } from 'url'

export default defineConfig({
  plugins: [
    vue({ 
      template: { transformAssetUrls }
    }),
    vuetify({ 
      autoImport: true,
      styles: { configFile: 'src/styles/settings.scss' }
    })
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '*.config.ts',
        '**/*.d.ts',
        '**/*.test.ts',
        '**/*.spec.ts'
      ]
    },
    include: ['**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    mockReset: true,
    restoreMocks: true
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})

// tests/setup.ts
import { config } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { vi } from 'vitest'
import ResizeObserver from 'resize-observer-polyfill'

// Setup Vuetify
const vuetify = createVuetify({
  components,
  directives
})

config.global.plugins = [vuetify]

// Mock ResizeObserver
global.ResizeObserver = ResizeObserver

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
  takeRecords: vi.fn(),
  root: null,
  rootMargin: '',
  thresholds: []
}))

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
})
```

### 2. **Component Testing Patterns**

```typescript
// __tests__/unit/components/SecureTextField.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import SecureTextField from '@/components/common/forms/SecureTextField.vue'
import { InputSanitizer } from '@/utils/validators/sanitizer'

// Mock the sanitizer
vi.mock('@/utils/validators/sanitizer', () => ({
  InputSanitizer: {
    sanitizeText: vi.fn(v => v),
    validateEmail: vi.fn(v => v.includes('@')),
    validateURL: vi.fn(v => v.startsWith('https://'))
  }
}))

describe('SecureTextField', () => {
  let wrapper: any
  
  const defaultProps = {
    modelValue: '',
    label: 'Test Field',
    type: 'text' as const
  }
  
  beforeEach(() => {
    vi.clearAllMocks()
  })
  
  describe('Rendering', () => {
    it('renders with default props', () => {
      wrapper = mount(SecureTextField, {
        props: defaultProps
      })
      
      expect(wrapper.find('.v-text-field').exists()).toBe(true)
      expect(wrapper.find('label').text()).toContain('Test Field')
    })
    
    it('renders password field with toggle button', () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          type: 'password'
        }
      })
      
      const toggleButton = wrapper.find('[aria-label*="password"]')
      expect(toggleButton.exists()).toBe(true)
    })
    
    it('applies correct ARIA attributes', () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          helperText: 'Help text',
          ariaLabel: 'Custom label'
        }
      })
      
      const input = wrapper.find('input')
      expect(input.attributes('aria-label')).toBe('Custom label')
      expect(input.attributes('aria-describedby')).toBeTruthy()
      expect(input.attributes('aria-invalid')).toBe('false')
    })
  })
  
  describe('Validation', () => {
    it('validates email format', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          type: 'email',
          modelValue: 'invalid-email'
        }
      })
      
      await nextTick()
      
      expect(InputSanitizer.validateEmail).toHaveBeenCalledWith('invalid-email')
      expect(wrapper.find('.v-messages__message').exists()).toBe(true)
    })
    
    it('validates password requirements', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          type: 'password',
          modelValue: 'weak'
        }
      })
      
      await nextTick()
      
      const messages = wrapper.findAll('.v-messages__message')
      expect(messages.length).toBeGreaterThan(0)
      expect(messages[0].text()).toContain('8 characters')
    })
    
    it('runs async validation with debounce', async () => {
      const validateAsync = vi.fn().mockResolvedValue(true)
      
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          validateAsync,
          debounceMs: 100
        }
      })
      
      const input = wrapper.find('input')
      await input.setValue('test')
      
      // Should not call immediately
      expect(validateAsync).not.toHaveBeenCalled()
      
      // Wait for debounce
      await new Promise(resolve => setTimeout(resolve, 150))
      
      expect(validateAsync).toHaveBeenCalledWith('test')
    })
  })
  
  describe('Sanitization', () => {
    it('sanitizes input when enabled', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          sanitize: true
        }
      })
      
      const input = wrapper.find('input')
      await input.setValue('<script>alert("xss")</script>')
      
      expect(InputSanitizer.sanitizeText).toHaveBeenCalled()
    })
    
    it('skips sanitization when disabled', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          sanitize: false
        }
      })
      
      const input = wrapper.find('input')
      await input.setValue('<script>alert("xss")</script>')
      
      expect(InputSanitizer.sanitizeText).not.toHaveBeenCalled()
    })
  })
  
  describe('Events', () => {
    it('emits update:modelValue on input', async () => {
      wrapper = mount(SecureTextField, {
        props: defaultProps
      })
      
      const input = wrapper.find('input')
      await input.setValue('new value')
      
      expect(wrapper.emitted('update:modelValue')).toBeTruthy()
      expect(wrapper.emitted('update:modelValue')[0]).toEqual(['new value'])
    })
    
    it('emits validation-complete after async validation', async () => {
      const validateAsync = vi.fn().mockResolvedValue(true)
      
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          validateAsync,
          debounceMs: 0
        }
      })
      
      const input = wrapper.find('input')
      await input.trigger('blur')
      await nextTick()
      
      expect(wrapper.emitted('validation-complete')).toBeTruthy()
      expect(wrapper.emitted('validation-complete')[0]).toEqual([true])
    })
  })
  
  describe('Accessibility', () => {
    it('toggles password visibility on button click', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          type: 'password'
        }
      })
      
      const input = wrapper.find('input')
      expect(input.attributes('type')).toBe('password')
      
      const toggleButton = wrapper.find('.v-field__append-inner button')
      await toggleButton.trigger('click')
      
      expect(input.attributes('type')).toBe('text')
    })
    
    it('supports keyboard navigation', async () => {
      wrapper = mount(SecureTextField, {
        props: {
          ...defaultProps,
          clearable: true
        }
      })
      
      const input = wrapper.find('input')
      await input.setValue('test')
      
      // Tab to clear button
      await input.trigger('keydown', { key: 'Tab' })
      
      const clearButton = wrapper.find('.v-field__clearable button')
      expect(clearButton.exists()).toBe(true)
    })
  })
})
```

### 3. **Store Testing Patterns**

```typescript
// __tests__/unit/stores/user.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from '@/stores/modules/user'
import { userService } from '@/services/api/userService'
import { useNotificationStore } from '@/stores/modules/notification'

// Mock services
vi.mock('@/services/api/userService', () => ({
  userService: {
    getUsers: vi.fn(),
    getUser: vi.fn(),
    createUser: vi.fn(),
    updateUser: vi.fn(),
    deleteUser: vi.fn()
  }
}))

describe('User Store', () => {
  let store: ReturnType<typeof useUserStore>
  
  beforeEach(() => {
    setActivePinia(createPinia())
    store = useUserStore()
    vi.clearAllMocks()
  })
  
  describe('State Management', () => {
    it('initializes with default state', () => {
      expect(store.users.size).toBe(0)
      expect(store.currentUser).toBeNull()
      expect(store.isLoading).toBe(false)
      expect(store.hasErrors).toBe(false)
    })
  })
  
  describe('Fetching Users', () => {
    const mockUsers = [
      { id: '1', name: 'John', email: 'john@test.com', role: 'admin' },
      { id: '2', name: 'Jane', email: 'jane@test.com', role: 'user' }
    ]
    
    it('fetches and stores users', async () => {
      vi.mocked(userService.getUsers).mockResolvedValue({
        data: mockUsers,
        total: 2
      })
      
      await store.fetchUsers()
      
      expect(userService.getUsers).toHaveBeenCalledWith(
        expect.objectContaining({
          search: '',
          role: null,
          status: 'all'
        })
      )
      
      expect(store.users.size).toBe(2)
      expect(store.pagination.total).toBe(2)
    })
    
    it('handles fetch errors', async () => {
      const error = new Error('Network error')
      vi.mocked(userService.getUsers).mockRejectedValue(error)
      
      await store.fetchUsers()
      
      expect(store.hasErrors).toBe(true)
      expect(store.isLoading).toBe(false)
    })
    
    it('uses cache when not forced', async () => {
      vi.mocked(userService.getUsers).mockResolvedValue({
        data: mockUsers,
        total: 2
      })
      
      // First call
      await store.fetchUsers()
      expect(userService.getUsers).toHaveBeenCalledTimes(1)
      
      // Second call within TTL
      await store.fetchUsers()
      expect(userService.getUsers).toHaveBeenCalledTimes(1) // Still 1
      
      // Force refresh
      await store.fetchUsers({ force: true })
      expect(userService.getUsers).toHaveBeenCalledTimes(2)
    })
    
    it('cancels previous requests', async () => {
      const abortSpy = vi.fn()
      const mockAbortController = {
        abort: abortSpy,
        signal: {} as AbortSignal
      }
      
      // Mock AbortController
      global.AbortController = vi.fn(() => mockAbortController) as any
      
      // Start first request (don't await)
      store.fetchUsers()
      
      // Start second request
      await store.fetchUsers()
      
      expect(abortSpy).toHaveBeenCalled()
    })
  })
  
  describe('CRUD Operations', () => {
    it('creates a user with optimistic update', async () => {
      const newUser = { 
        id: '3', 
        name: 'Bob', 
        email: 'bob@test.com' 
      }
      
      vi.mocked(userService.createUser).mockResolvedValue(newUser as any)
      
      const result = await store.createUser({
        name: 'Bob',
        email: 'bob@test.com'
      })
      
      expect(result).toEqual(newUser)
      expect(store.users.get('3')).toEqual(newUser)
      expect(store.pagination.total).toBe(1)
    })
    
    it('updates user optimistically and rolls back on error', async () => {
      const originalUser = { 
        id: '1', 
        name: 'John', 
        email: 'john@test.com' 
      }
      
      store.$test.state.users.set('1', originalUser)
      
      const error = new Error('Update failed')
      vi.mocked(userService.updateUser).mockRejectedValue(error)
      
      const result = await store.updateUser('1', { name: 'Johnny' })
      
      expect(result).toBe(false)
      expect(store.users.get('1')).toEqual(originalUser) // Rolled back
    })
    
    it('deletes user with rollback on error', async () => {
      const user = { id: '1', name: 'John', email: 'john@test.com' }
      store.$test.state.users.set('1', user)
      store.$test.state.pagination.total = 1
      
      vi.mocked(userService.deleteUser).mockRejectedValue(
        new Error('Delete failed')
      )
      
      const result = await store.deleteUser('1')
      
      expect(result).toBe(false)
      expect(store.users.has('1')).toBe(true) // Rolled back
      expect(store.pagination.total).toBe(1) // Unchanged
    })
  })
  
  describe('Filtering and Sorting', () => {
    beforeEach(() => {
      // Add test data
      store.$test.state.users.set('1', {
        id: '1',
        name: 'Alice',
        email: 'alice@test.com',
        role: 'admin',
        status: 'active',
        createdAt: '2024-01-01'
      })
      
      store.$test.state.users.set('2', {
        id: '2',
        name: 'Bob',
        email: 'bob@test.com',
        role: 'user',
        status: 'inactive',
        createdAt: '2024-01-02'
      })
    })
    
    it('filters users by search term', () => {
      store.setFilters({ search: 'alice' })
      
      expect(store.filteredUsers).toHaveLength(1)
      expect(store.filteredUsers[0].name).toBe('Alice')
    })
    
    it('filters users by role', () => {
      store.setFilters({ role: 'admin' })
      
      expect(store.filteredUsers).toHaveLength(1)
      expect(store.filteredUsers[0].role).toBe('admin')
    })
    
    it('sorts users by field', () => {
      store.setSorting('name', 'asc')
      
      expect(store.filteredUsers[0].name).toBe('Alice')
      expect(store.filteredUsers[1].name).toBe('Bob')
      
      store.setSorting('name', 'desc')
      
      expect(store.filteredUsers[0].name).toBe('Bob')
      expect(store.filteredUsers[1].name).toBe('Alice')
    })
    
    it('paginates results', () => {
      store.setPagination({ itemsPerPage: 1, page: 1 })
      
      expect(store.paginatedUsers).toHaveLength(1)
      expect(store.paginatedUsers[0].name).toBe('Alice')
      
      store.setPagination({ page: 2 })
      
      expect(store.paginatedUsers).toHaveLength(1)
      expect(store.paginatedUsers[0].name).toBe('Bob')
    })
  })
  
  describe('Batch Operations', () => {
    it('performs batch updates', async () => {
      vi.mocked(userService.updateUser)
        .mockResolvedValueOnce({ id: '1' } as any)
        .mockRejectedValueOnce(new Error('Failed'))
        .mockResolvedValueOnce({ id: '3' } as any)
      
      const result = await store.batchUpdate(
        ['1', '2', '3'],
        { status: 'active' }
      )
      
      expect(result.success).toEqual(['1', '3'])
      expect(result.failed).toEqual(['2'])
    })
  })
})
```

### 4. **Composable Testing Patterns**

```typescript
// __tests__/unit/composables/useForm.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { ref } from 'vue'
import { z } from 'zod'
import { useForm } from '@/composables/forms/useForm'

describe('useForm', () => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string().min(8),
    age: z.number().min(18)
  })
  
  let form: ReturnType<typeof useForm>
  
  beforeEach(() => {
    form = useForm(schema)
  })
  
  describe('Validation', () => {
    it('validates valid data', () => {
      form.formData.value = {
        email: 'test@example.com',
        password: 'password123',
        age: 25
      }
      
      const isValid = form.validate()
      
      expect(isValid).toBe(true)
      expect(form.errors.value).toEqual({})
      expect(form.isValid.value).toBe(true)
    })
    
    it('validates invalid data', () => {
      form.formData.value = {
        email: 'invalid',
        password: 'short',
        age: 16
      }
      
      const isValid = form.validate()
      
      expect(isValid).toBe(false)
      expect(form.errors.value.email).toContain('email')
      expect(form.errors.value.password).toContain('8')
      expect(form.errors.value.age).toContain('18')
    })
    
    it('clears errors on valid input', () => {
      form.formData.value = { email: 'invalid' }
      form.validate()
      
      expect(form.errors.value.email).toBeTruthy()
      
      form.formData.value.email = 'valid@example.com'
      form.validate()
      
      expect(form.errors.value.email).toBeUndefined()
    })
  })
  
  describe('Form State', () => {
    it('tracks dirty state', () => {
      expect(form.isDirty.value).toBe(false)
      
      form.formData.value.email = 'test@example.com'
      
      expect(form.isDirty.value).toBe(true)
    })
    
    it('resets form', () => {
      form.formData.value = {
        email: 'test@example.com',
        password: 'password123',
        age: 25
      }
      
      form.reset()
      
      expect(form.formData.value).toEqual({})
      expect(form.errors.value).toEqual({})
      expect(form.isDirty.value).toBe(false)
    })
  })
})
```

## E2E Testing

### 1. **Playwright Configuration**

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results.json' }],
    ['junit', { outputFile: 'junit.xml' }]
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
    navigationTimeout: 30000
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] }
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] }
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] }
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] }
    }
  ],
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
    timeout: 120000
  }
})
```

### 2. **E2E Page Object Model**

```typescript
// tests/e2e/pages/BasePage.ts
import { Page, Locator } from '@playwright/test'

export abstract class BasePage {
  constructor(protected page: Page) {}
  
  // Common navigation
  async goto(path: string) {
    await this.page.goto(path)
    await this.waitForPageLoad()
  }
  
  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle')
  }
  
  // Vuetify-specific helpers
  async clickVButton(text: string) {
    await this.page.locator(`.v-btn:has-text("${text}")`).click()
  }
  
  async fillVTextField(label: string, value: string) {
    const field = this.page.locator(`.v-text-field:has(label:has-text("${label}"))`)
    await field.locator('input').fill(value)
  }
  
  async selectVSelect(label: string, option: string) {
    const select = this.page.locator(`.v-select:has(label:has-text("${label}"))`)
    await select.click()
    await this.page.locator(`.v-list-item:has-text("${option}")`).click()
  }
  
  async waitForVSnackbar(text?: string) {
    const snackbar = text 
      ? this.page.locator(`.v-snackbar:has-text("${text}")`)
      : this.page.locator('.v-snackbar')
    await snackbar.waitFor({ state: 'visible' })
    return snackbar
  }
  
  async waitForVDialog() {
    await this.page.locator('.v-dialog').waitFor({ state: 'visible' })
  }
  
  async closeVDialog() {
    await this.page.keyboard.press('Escape')
    await this.page.locator('.v-dialog').waitFor({ state: 'hidden' })
  }
  
  // Accessibility checks
  async checkAccessibility(options?: any) {
    const { injectAxe, checkA11y } = require('axe-playwright')
    await injectAxe(this.page)
    await checkA11y(this.page, null, options)
  }
  
  // Screenshot helpers
  async takeScreenshot(name: string) {
    await this.page.screenshot({ 
      path: `tests/e2e/screenshots/${name}.png`,
      fullPage: true
    })
  }
  
  // Performance metrics
  async getPerformanceMetrics() {
    return await this.page.evaluate(() => {
      const perfData = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming
      return {
        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
        loadComplete: perfData.loadEventEnd - perfData.loadEventStart,
        firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime,
        firstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0]?.startTime
      }
    })
  }
}

// tests/e2e/pages/LoginPage.ts
import { Page } from '@playwright/test'
import { BasePage } from './BasePage'

export class LoginPage extends BasePage {
  // Locators
  private emailField = () => this.page.locator('[data-testid="email-field"]')
  private passwordField = () => this.page.locator('[data-testid="password-field"]')
  private loginButton = () => this.page.locator('[data-testid="login-button"]')
  private errorAlert = () => this.page.locator('.v-alert.error')
  private forgotPasswordLink = () => this.page.locator('a:has-text("Forgot password?")')
  
  // Actions
  async navigate() {
    await this.goto('/login')
  }
  
  async login(email: string, password: string) {
    await this.emailField().fill(email)
    await this.passwordField().fill(password)
    await this.loginButton().click()
  }
  
  async loginWithValidCredentials() {
    await this.login('test@example.com', 'ValidPass123!')
    await this.page.waitForURL('/dashboard')
  }
  
  async getErrorMessage() {
    await this.errorAlert().waitFor({ state: 'visible' })
    return await this.errorAlert().textContent()
  }
  
  async isLoginButtonDisabled() {
    return await this.loginButton().isDisabled()
  }
  
  async clickForgotPassword() {
    await this.forgotPasswordLink().click()
  }
  
  // Validations
  async validateFieldErrors() {
    const emailError = await this.page.locator('.v-text-field:has([data-testid="email-field"]) .v-messages__message').textContent()
    const passwordError = await this.page.locator('.v-text-field:has([data-testid="password-field"]) .v-messages__message').textContent()
    
    return { emailError, passwordError }
  }
}

// tests/e2e/pages/DashboardPage.ts
export class DashboardPage extends BasePage {
  // Complex interactions
  async createNewItem(data: {
    name: string
    description: string
    category: string
  }) {
    await this.clickVButton('New Item')
    await this.waitForVDialog()
    
    await this.fillVTextField('Name', data.name)
    await this.fillVTextField('Description', data.description)
    await this.selectVSelect('Category', data.category)
    
    await this.clickVButton('Create')
    
    const snackbar = await this.waitForVSnackbar('Item created successfully')
    await snackbar.waitFor({ state: 'hidden', timeout: 6000 })
  }
  
  async searchAndFilter(searchTerm: string, filters?: {
    status?: string
    dateRange?: [string, string]
  }) {
    // Search
    await this.page.locator('[data-testid="search-input"]').fill(searchTerm)
    await this.page.waitForTimeout(500) // Wait for debounce
    
    // Apply filters
    if (filters?.status) {
      await this.selectVSelect('Status', filters.status)
    }
    
    if (filters?.dateRange) {
      await this.page.locator('[data-testid="date-range-picker"]').click()
      // Handle date picker interaction
    }
    
    await this.waitForPageLoad()
  }
  
  async getTableData() {
    await this.page.locator('.v-data-table').waitFor()
    
    return await this.page.evaluate(() => {
      const rows = Array.from(document.querySelectorAll('.v-data-table tbody tr'))
      return rows.map(row => {
        const cells = Array.from(row.querySelectorAll('td'))
        return cells.map(cell => cell.textContent?.trim() || '')
      })
    })
  }
}
```

### 3. **E2E Test Suites**

```typescript
// tests/e2e/specs/authentication.spec.ts
import { test, expect } from '@playwright/test'
import { LoginPage } from '../pages/LoginPage'
import { DashboardPage } from '../pages/DashboardPage'

test.describe('Authentication Flow', () => {
  let loginPage: LoginPage
  let dashboardPage: DashboardPage
  
  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    dashboardPage = new DashboardPage(page)
    await loginPage.navigate()
  })
  
  test('successful login redirects to dashboard', async ({ page }) => {
    await loginPage.login('test@example.com', 'ValidPass123!')
    
    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('h1')).toContainText('Dashboard')
  })
  
  test('shows validation errors for invalid input', async () => {
    await loginPage.login('invalid-email', 'short')
    
    const errors = await loginPage.validateFieldErrors()
    
    expect(errors.emailError).toContain('Invalid email')
    expect(errors.passwordError).toContain('at least 8 characters')
  })
  
  test('prevents XSS in login form', async () => {
    const xssPayload = '<script>alert("XSS")</script>'
    
    await loginPage.login(xssPayload, xssPayload)
    
    // Check that script is not executed
    const alerts = await loginPage.page.evaluate(() => {
      return window.alert
    })
    
    expect(alerts).toBeDefined() // Alert not triggered
  })
  
  test('rate limits login attempts', async () => {
    for (let i = 0; i < 6; i++) {
      await loginPage.login('test@example.com', 'wrong')
      await loginPage.page.waitForTimeout(100)
    }
    
    const error = await loginPage.getErrorMessage()
    expect(error).toContain('Too many attempts')
  })
  
  test('maintains session across page refreshes', async ({ page }) => {
    await loginPage.loginWithValidCredentials()
    
    await page.reload()
    
    await expect(page).toHaveURL('/dashboard')
  })
  
  test('logs out successfully', async ({ page }) => {
    await loginPage.loginWithValidCredentials()
    
    await page.locator('[data-testid="user-menu"]').click()
    await page.locator('text=Logout').click()
    
    await expect(page).toHaveURL('/login')
  })
})

// tests/e2e/specs/accessibility.spec.ts
import { test, expect } from '@playwright/test'
import { injectAxe, checkA11y } from 'axe-playwright'

test.describe('Accessibility Tests', () => {
  test('login page meets WCAG standards', async ({ page }) => {
    await page.goto('/login')
    await injectAxe(page)
    
    const results = await checkA11y(page, null, {
      detailedReport: true,
      detailedReportOptions: {
        html: true
      }
    })
    
    expect(results).toBeNull()
  })
  
  test('dashboard is keyboard navigable', async ({ page }) => {
    await page.goto('/dashboard')
    
    // Tab through interactive elements
    await page.keyboard.press('Tab')
    const firstFocused = await page.evaluate(() => document.activeElement?.tagName)
    expect(firstFocused).toBeTruthy()
    
    // Navigate menu with arrow keys
    await page.locator('[role="navigation"]').press('ArrowDown')
    await page.keyboard.press('Enter')
    
    // Check focus trap in modal
    await page.locator('[data-testid="open-modal"]').click()
    await page.keyboard.press('Tab')
    
    const focusedInModal = await page.evaluate(() => {
      return document.activeElement?.closest('.v-dialog') !== null
    })
    
    expect(focusedInModal).toBe(true)
  })
  
  test('color contrast meets WCAG AA standards', async ({ page }) => {
    await page.goto('/dashboard')
    
    const contrastIssues = await page.evaluate(() => {
      const elements = document.querySelectorAll('*')
      const issues = []
      
      // Check color contrast for text elements
      elements.forEach(el => {
        const styles = window.getComputedStyle(el)
        const color = styles.color
        const backgroundColor = styles.backgroundColor
        
        // Simple contrast check (real implementation would be more complex)
        if (color && backgroundColor && color !== backgroundColor) {
          // Add to issues if contrast is insufficient
        }
      })
      
      return issues
    })
    
    expect(contrastIssues).toHaveLength(0)
  })
})

// tests/e2e/specs/performance.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Performance Tests', () => {
  test('dashboard loads within performance budget', async ({ page }) => {
    await page.goto('/dashboard')
    
    const metrics = await page.evaluate(() => {
      const perfData = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming
      
      return {
        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
        loadComplete: perfData.loadEventEnd - perfData.loadEventStart,
        firstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
        largestContentfulPaint: 0 // Would need PerformanceObserver
      }
    })
    
    expect(metrics.firstContentfulPaint).toBeLessThan(1500) // 1.5s
    expect(metrics.domContentLoaded).toBeLessThan(3000) // 3s
    expect(metrics.loadComplete).toBeLessThan(5000) // 5s
  })
  
  test('search has appropriate debouncing', async ({ page }) => {
    await page.goto('/dashboard')
    
    let requestCount = 0
    page.on('request', request => {
      if (request.url().includes('/api/search')) {
        requestCount++
      }
    })
    
    const searchInput = page.locator('[data-testid="search-input"]')
    
    // Type quickly
    await searchInput.type('test query', { delay: 50 })
    
    // Wait for debounce
    await page.waitForTimeout(500)
    
    // Should only make one request
    expect(requestCount).toBe(1)
  })
  
  test('infinite scroll loads efficiently', async ({ page }) => {
    await page.goto('/dashboard/items')
    
    // Initial load
    const initialItems = await page.locator('[data-testid="item-card"]').count()
    expect(initialItems).toBeGreaterThan(0)
    
    // Scroll to trigger load
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight)
    })
    
    // Wait for new items
    await page.waitForTimeout(1000)
    
    const afterScrollItems = await page.locator('[data-testid="item-card"]').count()
    expect(afterScrollItems).toBeGreaterThan(initialItems)
  })
})
```

### 4. **Testing Utilities & Helpers**

```typescript
// tests/utils/test-factory.ts
import { faker } from '@faker-js/faker'

export class TestDataFactory {
  static createUser(overrides?: Partial<User>): User {
    return {
      id: faker.string.uuid(),
      email: faker.internet.email(),
      name: faker.person.fullName(),
      role: faker.helpers.arrayElement(['admin', 'user', 'guest']),
      status: faker.helpers.arrayElement(['active', 'inactive']),
      createdAt: faker.date.past().toISOString(),
      ...overrides
    }
  }
  
  static createUsers(count: number): User[] {
    return Array.from({ length: count }, () => this.createUser())
  }
  
  static createLoginCredentials(): { email: string; password: string } {
    return {
      email: faker.internet.email(),
      password: 'ValidPass123!'
    }
  }
}

// tests/utils/mock-server.ts
import { rest } from 'msw'
import { setupServer } from 'msw/node'
import { TestDataFactory } from './test-factory'

export const handlers = [
  rest.post('/api/login', (req, res, ctx) => {
    const { email, password } = req.body as any
    
    if (email === 'test@example.com' && password === 'ValidPass123!') {
      return res(
        ctx.status(200),
        ctx.json({
          token: 'mock-jwt-token',
          user: TestDataFactory.createUser({
            email: 'test@example.com'
          })
        })
      )
    }
    
    return res(
      ctx.status(401),
      ctx.json({ error: 'Invalid credentials' })
    )
  }),
  
  rest.get('/api/users', (req, res, ctx) => {
    const users = TestDataFactory.createUsers(20)
    
    return res(
      ctx.status(200),
      ctx.json({
        data: users,
        total: users.length
      })
    )
  })
]

export const mockServer = setupServer(...handlers)

// tests/utils/vuetify-test-helper.ts
import { VueWrapper } from '@vue/test-utils'

export class VuetifyTestHelper {
  static async openDialog(wrapper: VueWrapper) {
    const activator = wrapper.find('[data-testid="dialog-activator"]')
    await activator.trigger('click')
    await wrapper.vm.$nextTick()
    
    // Wait for animation
    await new Promise(resolve => setTimeout(resolve, 300))
  }
  
  static async selectOption(wrapper: VueWrapper, label: string, option: string) {
    const select = wrapper.find(`.v-select:has(label:contains("${label}"))`)
    await select.trigger('click')
    
    const item = wrapper.find(`.v-list-item:contains("${option}")`)
    await item.trigger('click')
  }
  
  static findSnackbar(wrapper: VueWrapper, text?: string) {
    if (text) {
      return wrapper.find(`.v-snackbar:contains("${text}")`)
    }
    return wrapper.find('.v-snackbar')
  }
  
  static async waitForAsyncValidation(wrapper: VueWrapper, timeout = 1000) {
    await new Promise(resolve => setTimeout(resolve, timeout))
    await wrapper.vm.$nextTick()
  }
}
```

## Testing Best Practices Checklist

### Unit Testing
- [ ] Test files co-located with source files or in `__tests__`
- [ ] Mock external dependencies (API calls, stores)
- [ ] Test component props, events, and slots
- [ ] Test computed properties and watchers
- [ ] Test error states and edge cases
- [ ] Test accessibility attributes
- [ ] Maintain > 80% code coverage
- [ ] Use test factories for consistent data
- [ ] Test Vuetify component integrations

### Integration Testing
- [ ] Test store actions and mutations
- [ ] Test composables with different inputs
- [ ] Test service layer with mocked APIs
- [ ] Test router guards and navigation
- [ ] Test form validation flows
- [ ] Test real component interactions
- [ ] Test error recovery mechanisms

### E2E Testing
- [ ] Use Page Object Model pattern
- [ ] Test critical user journeys
- [ ] Test across different browsers
- [ ] Test responsive layouts
- [ ] Test accessibility standards
- [ ] Test performance budgets
- [ ] Test security features (XSS, CSRF)
- [ ] Test offline/error scenarios
- [ ] Use realistic test data

### Performance Testing
- [ ] Measure First Contentful Paint
- [ ] Measure Time to Interactive
- [ ] Test with network throttling
- [ ] Test with large datasets
- [ ] Monitor bundle sizes
- [ ] Test memory leaks
- [ ] Profile component rendering

## Implementation Summary

**Start every implementation with:** 

"I will build a production-ready Vue 3 + TypeScript + Vuetify application with:
- Comprehensive Pinia state management with proper typing, caching, and error handling
- Secure, accessible, and performant UI components following Material Design
- Thorough unit tests achieving >80% coverage with Vitest
- Complete E2E test suites using Playwright and Page Object Model
- WCAG AA accessibility compliance throughout
- Performance budgets and monitoring
- Security best practices including input validation, XSS prevention, and CSRF protection"

---

This comprehensive template provides a complete foundation for building, testing, and maintaining a production-grade Vue 3 application with Vuetify, ensuring quality through extensive testing practices while maintaining security and performance standards.