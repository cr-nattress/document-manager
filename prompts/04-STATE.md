# State Management with Pinia

**Area**: Global State, Store Patterns, Secure State Management
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [TypeScript](./07-TYPESCRIPT.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers Pinia store patterns with a focus on security, type safety, and state persistence for the Document Management System.

---

## Store Setup Patterns

### Options API Style (Recommended for Simplicity)

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'
import type { Document } from '@/types/models/document'

export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [] as Document[],
    selectedDocument: null as Document | null,
    loading: false,
    error: null as string | null
  }),

  getters: {
    documentCount(state): number {
      return state.documents.length
    },

    documentsByFolder: (state) => (folderId: string) => {
      return state.documents.filter(doc => doc.folderId === folderId)
    },

    sortedDocuments(state): Document[] {
      return [...state.documents].sort((a, b) =>
        new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime()
      )
    }
  },

  actions: {
    async fetchDocuments() {
      this.loading = true
      this.error = null

      try {
        const response = await fetch('/api/documents')
        this.documents = await response.json()
      } catch (err) {
        this.error = 'Failed to load documents'
        console.error(err)
      } finally {
        this.loading = false
      }
    },

    selectDocument(document: Document | null) {
      this.selectedDocument = document
    },

    addDocument(document: Document) {
      this.documents.push(document)
    }
  }
})
```

### Composition API Style (Setup Function)

```typescript
// stores/authStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import type { User, AuthToken } from '@/types/security/auth'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<AuthToken | null>(null)
  const loading = ref(false)

  // Getters
  const isAuthenticated = computed(() => user.value !== null)
  const isAdmin = computed(() => user.value?.role === 'admin')

  // Actions
  async function login(email: string, password: string) {
    loading.value = true

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      })

      const data = await response.json()
      user.value = data.user
      token.value = data.token
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  function logout() {
    user.value = null
    token.value = null
  }

  return {
    // State
    user,
    token,
    loading,
    // Getters
    isAuthenticated,
    isAdmin,
    // Actions
    login,
    logout
  }
})
```

---

## Secure State Management

### Never Store Sensitive Data in Plain State

**Bad - Exposed Credentials**:
```typescript
// ❌ NEVER DO THIS
export const useAuthStore = defineStore('auth', {
  state: () => ({
    password: '',          // ❌ Never store passwords
    ssn: '',              // ❌ Never store SSN
    creditCard: '',       // ❌ Never store payment info
    privateKey: ''        // ❌ Never store keys
  })
})
```

**Good - Secure Token Storage**:
```typescript
// ✅ Store tokens securely
export const useAuthStore = defineStore('auth', {
  state: () => ({
    // Only store non-sensitive user data
    userId: null as string | null,
    username: null as string | null,
    role: null as string | null,
    // Token stored in httpOnly cookie (backend)
    // Never in client state
  }),

  getters: {
    isAuthenticated(state): boolean {
      // Check token validity via API
      return state.userId !== null
    }
  },

  actions: {
    async verifyAuth() {
      // Verify with backend (httpOnly cookie sent automatically)
      const response = await fetch('/api/auth/verify', {
        credentials: 'include'
      })
      return response.ok
    }
  }
})
```

### Encrypt Sensitive Data in State (If Absolutely Required)

```typescript
// utils/security/encryption.ts
import CryptoJS from 'crypto-js'

export class StateEncryption {
  private static readonly KEY = import.meta.env.VITE_ENCRYPTION_KEY

  static encrypt(data: string): string {
    return CryptoJS.AES.encrypt(data, this.KEY).toString()
  }

  static decrypt(ciphertext: string): string {
    const bytes = CryptoJS.AES.decrypt(ciphertext, this.KEY)
    return bytes.toString(CryptoJS.enc.Utf8)
  }
}
```

```typescript
// stores/sensitiveStore.ts
import { defineStore } from 'pinia'
import { StateEncryption } from '@/utils/security/encryption'

export const useSensitiveStore = defineStore('sensitive', {
  state: () => ({
    encryptedData: null as string | null
  }),

  getters: {
    decryptedData(state): string | null {
      if (!state.encryptedData) return null
      return StateEncryption.decrypt(state.encryptedData)
    }
  },

  actions: {
    setData(plaintext: string) {
      this.encryptedData = StateEncryption.encrypt(plaintext)
    },

    clearData() {
      this.encryptedData = null
    }
  }
})
```

---

## Store Organization

### Keep Stores Under 150 Lines

**Strategy: Split by Domain**

```typescript
// ❌ Bad - Too many responsibilities (300+ lines)
export const useAppStore = defineStore('app', {
  state: () => ({
    documents: [],
    folders: [],
    users: [],
    tags: [],
    theme: {},
    notifications: []
    // ... 200+ more lines
  })
})

// ✅ Good - Separate stores
// stores/documentStore.ts (120 lines)
// stores/folderStore.ts (100 lines)
// stores/userStore.ts (80 lines)
// stores/tagStore.ts (60 lines)
// stores/uiStore.ts (90 lines)
```

---

## State Persistence

### Persist State with Validation

```typescript
// stores/uiStore.ts
import { defineStore } from 'pinia'
import { z } from 'zod'

// Schema for persisted state
const uiStateSchema = z.object({
  theme: z.enum(['light', 'dark']),
  sidebarOpen: z.boolean(),
  viewMode: z.enum(['list', 'grid']),
  pageSize: z.number().min(10).max(100)
})

type UIState = z.infer<typeof uiStateSchema>

export const useUIStore = defineStore('ui', {
  state: (): UIState => ({
    theme: 'light',
    sidebarOpen: true,
    viewMode: 'list',
    pageSize: 20
  }),

  actions: {
    // Load state from localStorage with validation
    loadFromStorage() {
      try {
        const stored = localStorage.getItem('ui-state')
        if (!stored) return

        const parsed = JSON.parse(stored)
        const validated = uiStateSchema.parse(parsed)

        // Only update state if validation passes
        this.$patch(validated)
      } catch (error) {
        console.error('Failed to load UI state:', error)
        // Clear invalid data
        localStorage.removeItem('ui-state')
      }
    },

    // Save state to localStorage
    saveToStorage() {
      try {
        const state = this.$state
        localStorage.setItem('ui-state', JSON.stringify(state))
      } catch (error) {
        console.error('Failed to save UI state:', error)
      }
    }
  }
})
```

### Auto-Persist with Plugin

```typescript
// plugins/persistPlugin.ts
import type { PiniaPluginContext } from 'pinia'
import { watch } from 'vue'
import { z } from 'zod'

export function createPersistPlugin(
  storeName: string,
  schema: z.ZodSchema
) {
  return ({ store }: PiniaPluginContext) => {
    if (store.$id !== storeName) return

    // Load on init
    const stored = localStorage.getItem(`pinia-${storeName}`)
    if (stored) {
      try {
        const parsed = JSON.parse(stored)
        const validated = schema.parse(parsed)
        store.$patch(validated)
      } catch (error) {
        console.error(`Failed to load ${storeName}:`, error)
        localStorage.removeItem(`pinia-${storeName}`)
      }
    }

    // Auto-save on state change
    watch(
      () => store.$state,
      (state) => {
        try {
          localStorage.setItem(
            `pinia-${storeName}`,
            JSON.stringify(state)
          )
        } catch (error) {
          console.error(`Failed to save ${storeName}:`, error)
        }
      },
      { deep: true }
    )
  }
}
```

---

## Auto-Logout on Inactivity

### Inactivity Timer Implementation

```typescript
// stores/authStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

const INACTIVITY_TIMEOUT = 15 * 60 * 1000 // 15 minutes

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const lastActivity = ref<number>(Date.now())
  let inactivityTimer: number | null = null

  const isAuthenticated = computed(() => user.value !== null)

  function updateActivity() {
    lastActivity.value = Date.now()
    resetInactivityTimer()
  }

  function resetInactivityTimer() {
    if (inactivityTimer) {
      clearTimeout(inactivityTimer)
    }

    if (isAuthenticated.value) {
      inactivityTimer = window.setTimeout(() => {
        logout('Logged out due to inactivity')
      }, INACTIVITY_TIMEOUT)
    }
  }

  function login(userData: User) {
    user.value = userData
    updateActivity()
  }

  function logout(reason?: string) {
    user.value = null
    lastActivity.value = 0

    if (inactivityTimer) {
      clearTimeout(inactivityTimer)
      inactivityTimer = null
    }

    if (reason) {
      console.log('Logout reason:', reason)
    }
  }

  return {
    user,
    isAuthenticated,
    lastActivity,
    login,
    logout,
    updateActivity
  }
})
```

### Track User Activity

```typescript
// composables/useInactivityTimer.ts
import { onMounted, onBeforeUnmount } from 'vue'
import { useAuthStore } from '@/stores/authStore'

export function useInactivityTimer() {
  const authStore = useAuthStore()

  const events = [
    'mousedown',
    'mousemove',
    'keypress',
    'scroll',
    'touchstart',
    'click'
  ]

  function handleActivity() {
    authStore.updateActivity()
  }

  onMounted(() => {
    events.forEach(event => {
      document.addEventListener(event, handleActivity, { passive: true })
    })
  })

  onBeforeUnmount(() => {
    events.forEach(event => {
      document.removeEventListener(event, handleActivity)
    })
  })
}
```

```vue
<!-- App.vue -->
<script setup lang="ts">
import { useInactivityTimer } from '@/composables/useInactivityTimer'

useInactivityTimer()
</script>
```

---

## Cross-Store Communication

### Store Composition

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'
import { useAuthStore } from './authStore'
import { useFolderStore } from './folderStore'

export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [] as Document[]
  }),

  actions: {
    async fetchDocuments() {
      // Access other stores
      const authStore = useAuthStore()
      const folderStore = useFolderStore()

      if (!authStore.isAuthenticated) {
        throw new Error('Not authenticated')
      }

      const folderId = folderStore.selectedFolder?.id
      // Fetch documents...
    }
  }
})
```

---

## Readonly State

### Expose Readonly State to Components

```typescript
// stores/configStore.ts
import { defineStore } from 'pinia'
import { readonly } from 'vue'

export const useConfigStore = defineStore('config', {
  state: () => ({
    apiUrl: import.meta.env.VITE_API_URL,
    maxFileSize: 100 * 1024 * 1024, // 100MB
    allowedFileTypes: ['.pdf', '.doc', '.docx', '.xls', '.xlsx']
  }),

  getters: {
    // Return readonly config to prevent mutations
    readonlyConfig(state) {
      return readonly(state)
    }
  }
})
```

---

## State Reset

### Reset Store to Initial State

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'

export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [] as Document[],
    selectedDocument: null as Document | null,
    loading: false
  }),

  actions: {
    $reset() {
      this.documents = []
      this.selectedDocument = null
      this.loading = false
    },

    logout() {
      // Reset all state on logout
      this.$reset()
    }
  }
})
```

### Reset All Stores on Logout

```typescript
// stores/authStore.ts
import { defineStore } from 'pinia'
import { useDocumentStore } from './documentStore'
import { useFolderStore } from './folderStore'
import { useSearchStore } from './searchStore'

export const useAuthStore = defineStore('auth', {
  actions: {
    logout() {
      // Clear auth state
      this.$reset()

      // Clear all other stores
      useDocumentStore().$reset()
      useFolderStore().$reset()
      useSearchStore().$reset()

      // Clear localStorage
      localStorage.clear()
    }
  }
})
```

---

## Action Error Handling

### Consistent Error Handling Pattern

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'

export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [] as Document[],
    loading: false,
    error: null as string | null
  }),

  actions: {
    async fetchDocuments() {
      this.loading = true
      this.error = null

      try {
        const response = await fetch('/api/documents')

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`)
        }

        this.documents = await response.json()
      } catch (err) {
        // Generic error message for users
        this.error = 'Failed to load documents. Please try again.'

        // Detailed error for logging
        console.error('Document fetch error:', err)

        // Re-throw for component handling if needed
        throw err
      } finally {
        this.loading = false
      }
    }
  }
})
```

---

## Store Testing

### Unit Test Pattern

```typescript
// stores/__tests__/documentStore.spec.ts
import { setActivePinia, createPinia } from 'pinia'
import { beforeEach, describe, it, expect } from 'vitest'
import { useDocumentStore } from '../documentStore'

describe('Document Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('initializes with empty documents', () => {
    const store = useDocumentStore()
    expect(store.documents).toEqual([])
    expect(store.selectedDocument).toBeNull()
  })

  it('adds document correctly', () => {
    const store = useDocumentStore()
    const doc = {
      id: '1',
      name: 'Test.pdf',
      folderId: 'root'
    }

    store.addDocument(doc)
    expect(store.documents).toHaveLength(1)
    expect(store.documents[0]).toEqual(doc)
  })

  it('filters documents by folder', () => {
    const store = useDocumentStore()
    store.documents = [
      { id: '1', name: 'Doc1', folderId: 'folder1' },
      { id: '2', name: 'Doc2', folderId: 'folder2' },
      { id: '3', name: 'Doc3', folderId: 'folder1' }
    ]

    const filtered = store.documentsByFolder('folder1')
    expect(filtered).toHaveLength(2)
  })
})
```

---

## Advanced Store Patterns

### Domain Store with Caching and Optimistic Updates

```typescript
// stores/modules/user.ts
import { defineStore, acceptHMRUpdate } from 'pinia'
import { ref, computed, reactive } from 'vue'
import type { User } from '@/types/models/user'
import { userService } from '@/services/api/userService'
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

  const isLoading = computed(() =>
    Array.from(state.loadingStates.values()).some(loading => loading)
  )

  // Actions with caching
  async function fetchUsers(options: { force?: boolean } = {}) {
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
        signal: controller.signal
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

  // Optimistic update
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

  function clearCache() {
    cache.timestamps.clear()
  }

  function handleError(error: any, defaultMessage: string) {
    const notificationStore = useNotificationStore()
    notificationStore.error(error.message || defaultMessage)
  }

  return {
    // State (readonly)
    users: computed(() => state.users),
    filters: computed(() => state.filters),
    sorting: computed(() => state.sorting),
    pagination: computed(() => state.pagination),

    // Computed
    filteredUsers,
    isLoading,

    // Actions
    fetchUsers,
    updateUser,
    batchUpdate,
    setFilters,
    clearCache
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

### Pinia Plugins

```typescript
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

```typescript
// stores/index.ts
import { createPinia, type Pinia } from 'pinia'
import { markRaw } from 'vue'
import router from '@/router'
import type { Router } from 'vue-router'
import { persistPlugin } from './plugins/persist'

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

  return pinia
}
```

---

## Store Size Limit Checklist

When a store exceeds 150 lines:

- [ ] Split by domain (documents, folders, users)
- [ ] Extract helper functions to utilities
- [ ] Move validation logic to separate files
- [ ] Create separate stores for unrelated concerns
- [ ] Consider composing stores instead of one large store

---

## Security Checklist

- [ ] No passwords stored in state
- [ ] No API keys in state
- [ ] Sensitive data encrypted if stored
- [ ] Tokens stored in httpOnly cookies (backend)
- [ ] State persistence validates on load
- [ ] Auto-logout on inactivity implemented
- [ ] All stores reset on logout
- [ ] Error messages don't expose sensitive data

---

## Related Guidelines

- **For security patterns**: See [Security](./02-SECURITY.md)
- **For TypeScript types**: See [TypeScript](./07-TYPESCRIPT.md)
- **For store organization**: See [Architecture](./01-ARCHITECTURE.md)
- **For API integration**: See [API](./05-API.md)

---

**Remember**: State is global and persistent. Secure it rigorously and keep stores focused and small.
