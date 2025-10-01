# Pinia - Comprehensive Guide

**Technology**: Pinia
**Category**: State Management
**Official Docs**: https://pinia.vuejs.org

---

## Overview

Pinia is the official state management library for Vue 3. It provides a simple, type-safe, and modular approach to managing application state with excellent TypeScript support and DevTools integration.

### Key Features
- **Intuitive API** - Simple and straightforward
- **Type Safety** - Full TypeScript support with type inference
- **DevTools Support** - Time-travel debugging and state inspection
- **Modular** - Multiple stores instead of single monolithic store
- **Composition API Style** - Consistent with Vue 3
- **Server-Side Rendering** - SSR support out of the box
- **Hot Module Replacement** - Preserve state during development
- **No Mutations** - Direct state modifications (simpler than Vuex)

---

## Design Patterns

### 1. Options Store Pattern

**Purpose**: Organize store with options-style API similar to Vue Options API

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'
import type { Document } from '@/types/document'
import { documentService } from '@/services/documentService'

export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [] as Document[],
    selectedDocument: null as Document | null,
    loading: false,
    error: null as string | null
  }),

  getters: {
    // Get documents by folder ID
    documentsByFolder: (state) => (folderId: string) => {
      return state.documents.filter(doc => doc.folderId === folderId)
    },

    // Count total documents
    documentCount: (state) => state.documents.length,

    // Check if any documents are loading
    isLoading: (state) => state.loading,

    // Get documents sorted by date
    sortedDocuments: (state) => {
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
        const response = await documentService.getAll()
        this.documents = response.data
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to fetch documents'
      } finally {
        this.loading = false
      }
    },

    async fetchDocument(id: string) {
      this.loading = true
      this.error = null

      try {
        const response = await documentService.getById(id)
        this.selectedDocument = response.data
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to fetch document'
      } finally {
        this.loading = false
      }
    },

    async createDocument(document: Omit<Document, 'id' | 'uploadedAt'>) {
      this.loading = true
      this.error = null

      try {
        const response = await documentService.create(document)
        this.documents.push(response.data)
        return response.data
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to create document'
        throw err
      } finally {
        this.loading = false
      }
    },

    async deleteDocument(id: string) {
      this.loading = true
      this.error = null

      try {
        await documentService.delete(id)
        this.documents = this.documents.filter(doc => doc.id !== id)

        if (this.selectedDocument?.id === id) {
          this.selectedDocument = null
        }
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to delete document'
        throw err
      } finally {
        this.loading = false
      }
    },

    selectDocument(document: Document | null) {
      this.selectedDocument = document
    },

    clearError() {
      this.error = null
    }
  }
})
```

### 2. Setup Store Pattern (Composition API Style)

**Purpose**: Use Composition API style for more flexibility

```typescript
// stores/folderStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import type { Folder } from '@/types/folder'
import { folderService } from '@/services/folderService'

export const useFolderStore = defineStore('folder', () => {
  // State (refs)
  const folders = ref<Folder[]>([])
  const selectedFolder = ref<Folder | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters (computed)
  const folderCount = computed(() => folders.value.length)

  const rootFolders = computed(() =>
    folders.value.filter(folder => !folder.parentId)
  )

  const folderTree = computed(() => {
    const buildTree = (parentId: string | null): Folder[] => {
      return folders.value
        .filter(folder => folder.parentId === parentId)
        .map(folder => ({
          ...folder,
          children: buildTree(folder.id)
        }))
    }
    return buildTree(null)
  })

  const getFolderById = computed(() => (id: string) =>
    folders.value.find(folder => folder.id === id)
  )

  // Actions (functions)
  async function fetchFolders() {
    loading.value = true
    error.value = null

    try {
      const response = await folderService.getAll()
      folders.value = response.data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch folders'
    } finally {
      loading.value = false
    }
  }

  async function createFolder(folder: Omit<Folder, 'id' | 'createdAt'>) {
    loading.value = true
    error.value = null

    try {
      const response = await folderService.create(folder)
      folders.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to create folder'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateFolder(id: string, updates: Partial<Folder>) {
    loading.value = true
    error.value = null

    try {
      const response = await folderService.update(id, updates)
      const index = folders.value.findIndex(f => f.id === id)
      if (index !== -1) {
        folders.value[index] = response.data
      }
      return response.data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to update folder'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteFolder(id: string) {
    loading.value = true
    error.value = null

    try {
      await folderService.delete(id)
      folders.value = folders.value.filter(f => f.id !== id)

      if (selectedFolder.value?.id === id) {
        selectedFolder.value = null
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to delete folder'
      throw err
    } finally {
      loading.value = false
    }
  }

  function selectFolder(folder: Folder | null) {
    selectedFolder.value = folder
  }

  function clearError() {
    error.value = null
  }

  return {
    // State
    folders,
    selectedFolder,
    loading,
    error,
    // Getters
    folderCount,
    rootFolders,
    folderTree,
    getFolderById,
    // Actions
    fetchFolders,
    createFolder,
    updateFolder,
    deleteFolder,
    selectFolder,
    clearError
  }
})
```

### 3. Store Composition Pattern

**Purpose**: Compose stores together for related functionality

```typescript
// stores/searchStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useDocumentStore } from './documentStore'
import { useFolderStore } from './folderStore'

export const useSearchStore = defineStore('search', () => {
  const documentStore = useDocumentStore()
  const folderStore = useFolderStore()

  // State
  const query = ref('')
  const searchType = ref<'all' | 'documents' | 'folders'>('all')
  const recentSearches = ref<string[]>([])

  // Getters
  const searchResults = computed(() => {
    if (!query.value) return { documents: [], folders: [] }

    const lowerQuery = query.value.toLowerCase()

    const documents = searchType.value !== 'folders'
      ? documentStore.documents.filter(doc =>
          doc.name.toLowerCase().includes(lowerQuery) ||
          doc.metadata?.description?.toLowerCase().includes(lowerQuery)
        )
      : []

    const folders = searchType.value !== 'documents'
      ? folderStore.folders.filter(folder =>
          folder.name.toLowerCase().includes(lowerQuery)
        )
      : []

    return { documents, folders }
  })

  const hasResults = computed(() =>
    searchResults.value.documents.length > 0 ||
    searchResults.value.folders.length > 0
  )

  // Actions
  function setQuery(newQuery: string) {
    query.value = newQuery

    if (newQuery && !recentSearches.value.includes(newQuery)) {
      recentSearches.value.unshift(newQuery)
      if (recentSearches.value.length > 10) {
        recentSearches.value.pop()
      }
    }
  }

  function setSearchType(type: 'all' | 'documents' | 'folders') {
    searchType.value = type
  }

  function clearSearch() {
    query.value = ''
  }

  function clearRecentSearches() {
    recentSearches.value = []
  }

  return {
    query,
    searchType,
    recentSearches,
    searchResults,
    hasResults,
    setQuery,
    setSearchType,
    clearSearch,
    clearRecentSearches
  }
})
```

---

## Best Practices

### 1. Use TypeScript for Type Safety

**Do**:
```typescript
interface DocumentState {
  documents: Document[]
  loading: boolean
  error: string | null
}

export const useDocumentStore = defineStore('document', {
  state: (): DocumentState => ({
    documents: [],
    loading: false,
    error: null
  })
})
```

**Don't**:
```typescript
// No types - hard to maintain
export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [],
    loading: false,
    error: null
  })
})
```

### 2. Keep Stores Focused

**Do**: Create separate stores for different domains
```typescript
useDocumentStore()  // Document operations
useFolderStore()    // Folder operations
useAuthStore()      // Authentication
useUIStore()        // UI state
```

**Don't**: Create one massive store
```typescript
useAppStore()  // Everything mixed together
```

### 3. Use Actions for Async Operations

**Do**:
```typescript
actions: {
  async fetchDocuments() {
    this.loading = true
    try {
      const response = await api.getDocuments()
      this.documents = response.data
    } finally {
      this.loading = false
    }
  }
}
```

**Don't**: Mutate state directly from components
```typescript
// In component - DON'T DO THIS
const store = useDocumentStore()
store.loading = true
const response = await api.getDocuments()
store.documents = response.data
```

### 4. Use Getters for Derived State

**Do**:
```typescript
getters: {
  documentsByFolder: (state) => (folderId: string) => {
    return state.documents.filter(doc => doc.folderId === folderId)
  }
}
```

**Don't**: Compute in component
```typescript
// In component - less efficient
const filtered = store.documents.filter(doc => doc.folderId === folderId)
```

### 5. Reset State Properly

```typescript
export const useDocumentStore = defineStore('document', {
  state: () => ({
    documents: [],
    loading: false,
    error: null
  }),

  actions: {
    $reset() {
      this.documents = []
      this.loading = false
      this.error = null
    }
  }
})
```

---

## Common Patterns for Document Manager

### 1. UI State Store

```typescript
// stores/uiStore.ts
import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useUIStore = defineStore('ui', () => {
  // Navigation
  const drawerOpen = ref(true)
  const drawerRail = ref(false)

  // Dialogs
  const uploadDialogOpen = ref(false)
  const previewDialogOpen = ref(false)
  const confirmDialogOpen = ref(false)

  // Theme
  const darkMode = ref(false)

  // Notifications
  interface Notification {
    id: string
    type: 'success' | 'error' | 'info' | 'warning'
    message: string
    timeout?: number
  }

  const notifications = ref<Notification[]>([])

  // Actions
  function toggleDrawer() {
    drawerOpen.value = !drawerOpen.value
  }

  function toggleDrawerRail() {
    drawerRail.value = !drawerRail.value
  }

  function openUploadDialog() {
    uploadDialogOpen.value = true
  }

  function closeUploadDialog() {
    uploadDialogOpen.value = false
  }

  function toggleTheme() {
    darkMode.value = !darkMode.value
    localStorage.setItem('darkMode', String(darkMode.value))
  }

  function showNotification(
    type: Notification['type'],
    message: string,
    timeout = 5000
  ) {
    const id = crypto.randomUUID()
    notifications.value.push({ id, type, message, timeout })

    if (timeout > 0) {
      setTimeout(() => {
        dismissNotification(id)
      }, timeout)
    }
  }

  function dismissNotification(id: string) {
    notifications.value = notifications.value.filter(n => n.id !== id)
  }

  // Initialize from localStorage
  const savedDarkMode = localStorage.getItem('darkMode')
  if (savedDarkMode !== null) {
    darkMode.value = savedDarkMode === 'true'
  }

  return {
    drawerOpen,
    drawerRail,
    uploadDialogOpen,
    previewDialogOpen,
    confirmDialogOpen,
    darkMode,
    notifications,
    toggleDrawer,
    toggleDrawerRail,
    openUploadDialog,
    closeUploadDialog,
    toggleTheme,
    showNotification,
    dismissNotification
  }
})
```

### 2. Cache Store Pattern

```typescript
// stores/cacheStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

interface CacheEntry<T> {
  data: T
  timestamp: number
  ttl: number
}

export const useCacheStore = defineStore('cache', () => {
  const cache = ref<Map<string, CacheEntry<any>>>(new Map())

  function set<T>(key: string, data: T, ttl = 300000) { // 5 min default
    cache.value.set(key, {
      data,
      timestamp: Date.now(),
      ttl
    })
  }

  function get<T>(key: string): T | null {
    const entry = cache.value.get(key)

    if (!entry) return null

    const isExpired = Date.now() - entry.timestamp > entry.ttl

    if (isExpired) {
      cache.value.delete(key)
      return null
    }

    return entry.data as T
  }

  function has(key: string): boolean {
    return get(key) !== null
  }

  function remove(key: string) {
    cache.value.delete(key)
  }

  function clear() {
    cache.value.clear()
  }

  function invalidateByPrefix(prefix: string) {
    for (const key of cache.value.keys()) {
      if (key.startsWith(prefix)) {
        cache.value.delete(key)
      }
    }
  }

  const size = computed(() => cache.value.size)

  return {
    set,
    get,
    has,
    remove,
    clear,
    invalidateByPrefix,
    size
  }
})
```

### 3. Upload Progress Store

```typescript
// stores/uploadStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

interface UploadProgress {
  id: string
  fileName: string
  progress: number
  status: 'pending' | 'uploading' | 'completed' | 'error'
  error?: string
}

export const useUploadStore = defineStore('upload', () => {
  const uploads = ref<Map<string, UploadProgress>>(new Map())

  const activeUploads = computed(() =>
    Array.from(uploads.value.values()).filter(
      u => u.status === 'uploading' || u.status === 'pending'
    )
  )

  const completedUploads = computed(() =>
    Array.from(uploads.value.values()).filter(u => u.status === 'completed')
  )

  const failedUploads = computed(() =>
    Array.from(uploads.value.values()).filter(u => u.status === 'error')
  )

  const hasActiveUploads = computed(() => activeUploads.value.length > 0)

  function startUpload(id: string, fileName: string) {
    uploads.value.set(id, {
      id,
      fileName,
      progress: 0,
      status: 'uploading'
    })
  }

  function updateProgress(id: string, progress: number) {
    const upload = uploads.value.get(id)
    if (upload) {
      upload.progress = progress
    }
  }

  function completeUpload(id: string) {
    const upload = uploads.value.get(id)
    if (upload) {
      upload.status = 'completed'
      upload.progress = 100
    }
  }

  function failUpload(id: string, error: string) {
    const upload = uploads.value.get(id)
    if (upload) {
      upload.status = 'error'
      upload.error = error
    }
  }

  function removeUpload(id: string) {
    uploads.value.delete(id)
  }

  function clearCompleted() {
    for (const [id, upload] of uploads.value.entries()) {
      if (upload.status === 'completed') {
        uploads.value.delete(id)
      }
    }
  }

  function clearAll() {
    uploads.value.clear()
  }

  return {
    uploads,
    activeUploads,
    completedUploads,
    failedUploads,
    hasActiveUploads,
    startUpload,
    updateProgress,
    completeUpload,
    failUpload,
    removeUpload,
    clearCompleted,
    clearAll
  }
})
```

---

## Using Stores in Components

### 1. Basic Usage

```vue
<script setup lang="ts">
import { useDocumentStore } from '@/stores/documentStore'
import { storeToRefs } from 'pinia'
import { onMounted } from 'vue'

const documentStore = useDocumentStore()

// Use storeToRefs to maintain reactivity for state and getters
const { documents, loading, error } = storeToRefs(documentStore)

// Actions can be destructured directly
const { fetchDocuments, deleteDocument } = documentStore

onMounted(() => {
  fetchDocuments()
})
</script>

<template>
  <div>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    <div v-else>
      <div v-for="doc in documents" :key="doc.id">
        {{ doc.name }}
        <button @click="deleteDocument(doc.id)">Delete</button>
      </div>
    </div>
  </div>
</template>
```

### 2. Using Multiple Stores

```vue
<script setup lang="ts">
import { useDocumentStore } from '@/stores/documentStore'
import { useFolderStore } from '@/stores/folderStore'
import { useUIStore } from '@/stores/uiStore'
import { storeToRefs } from 'pinia'

const documentStore = useDocumentStore()
const folderStore = useFolderStore()
const uiStore = useUIStore()

const { documents } = storeToRefs(documentStore)
const { selectedFolder } = storeToRefs(folderStore)
const { showNotification } = uiStore

async function handleDelete(id: string) {
  try {
    await documentStore.deleteDocument(id)
    showNotification('success', 'Document deleted successfully')
  } catch (err) {
    showNotification('error', 'Failed to delete document')
  }
}
</script>
```

### 3. Store with Getters

```vue
<script setup lang="ts">
import { useDocumentStore } from '@/stores/documentStore'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

const documentStore = useDocumentStore()
const { documents, documentsByFolder } = storeToRefs(documentStore)

const currentFolderId = ref('folder-123')

// Use getter with parameter
const currentDocuments = computed(() =>
  documentsByFolder.value(currentFolderId.value)
)
</script>

<template>
  <div v-for="doc in currentDocuments" :key="doc.id">
    {{ doc.name }}
  </div>
</template>
```

---

## Persisting State

### 1. Using Pinia Plugin Persist

```typescript
// main.ts
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)

// stores/authStore.ts
export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null
  }),

  persist: {
    key: 'auth',
    storage: localStorage,
    paths: ['user', 'token'] // Only persist these fields
  }
})
```

### 2. Manual Persistence

```typescript
export const useSettingsStore = defineStore('settings', () => {
  const settings = ref({
    theme: 'light',
    language: 'en',
    pageSize: 10
  })

  // Load from localStorage on init
  const savedSettings = localStorage.getItem('settings')
  if (savedSettings) {
    settings.value = JSON.parse(savedSettings)
  }

  // Watch and save changes
  watch(settings, (newSettings) => {
    localStorage.setItem('settings', JSON.stringify(newSettings))
  }, { deep: true })

  return { settings }
})
```

---

## Testing

### Unit Test Example (Vitest)

```typescript
import { setActivePinia, createPinia } from 'pinia'
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useDocumentStore } from '@/stores/documentStore'
import { documentService } from '@/services/documentService'

vi.mock('@/services/documentService')

describe('Document Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('fetches documents', async () => {
    const mockDocuments = [
      { id: '1', name: 'Doc 1', folderId: 'folder-1' },
      { id: '2', name: 'Doc 2', folderId: 'folder-2' }
    ]

    vi.mocked(documentService.getAll).mockResolvedValue({
      data: mockDocuments
    })

    const store = useDocumentStore()
    await store.fetchDocuments()

    expect(store.documents).toEqual(mockDocuments)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('handles fetch error', async () => {
    vi.mocked(documentService.getAll).mockRejectedValue(
      new Error('Network error')
    )

    const store = useDocumentStore()
    await store.fetchDocuments()

    expect(store.documents).toEqual([])
    expect(store.error).toBe('Network error')
  })

  it('filters documents by folder', () => {
    const store = useDocumentStore()
    store.documents = [
      { id: '1', name: 'Doc 1', folderId: 'folder-1' },
      { id: '2', name: 'Doc 2', folderId: 'folder-2' },
      { id: '3', name: 'Doc 3', folderId: 'folder-1' }
    ]

    const filtered = store.documentsByFolder('folder-1')

    expect(filtered).toHaveLength(2)
    expect(filtered[0].id).toBe('1')
    expect(filtered[1].id).toBe('3')
  })
})
```

---

## Common Pitfalls

### 1. Not Using storeToRefs

**Don't**:
```typescript
// Loses reactivity
const { documents, loading } = useDocumentStore()
```

**Do**:
```typescript
import { storeToRefs } from 'pinia'
const { documents, loading } = storeToRefs(useDocumentStore())
```

### 2. Mutating State Outside Actions (Options API)

**Don't**:
```typescript
// In component
store.documents.push(newDoc) // Bad practice
```

**Do**:
```typescript
// In store action
actions: {
  addDocument(doc: Document) {
    this.documents.push(doc)
  }
}

// In component
store.addDocument(newDoc)
```

### 3. Not Handling Errors

**Don't**:
```typescript
async fetchDocuments() {
  const response = await api.getDocuments()
  this.documents = response.data
}
```

**Do**:
```typescript
async fetchDocuments() {
  this.loading = true
  this.error = null
  try {
    const response = await api.getDocuments()
    this.documents = response.data
  } catch (err) {
    this.error = err.message
  } finally {
    this.loading = false
  }
}
```

### 4. Creating Store Instances Instead of Using Composable

**Don't**:
```typescript
import { documentStore } from '@/stores/documentStore'
```

**Do**:
```typescript
import { useDocumentStore } from '@/stores/documentStore'
const store = useDocumentStore()
```

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://pinia.vuejs.org
- **API Reference**: https://pinia.vuejs.org/api/
- **Cookbook**: https://pinia.vuejs.org/cookbook/

### Learning Resources
- **Vue Mastery Course**: https://www.vuemastery.com/courses/pinia/
- **Official Guide**: https://pinia.vuejs.org/introduction.html

### Community
- **Discord**: https://chat.vuejs.org (Vue Land)
- **GitHub**: https://github.com/vuejs/pinia
- **Stack Overflow**: Tag `pinia`

---

## Quick Reference

### Creating a Store

```typescript
// Options API style
export const useStore = defineStore('storeName', {
  state: () => ({ count: 0 }),
  getters: {
    doubled: (state) => state.count * 2
  },
  actions: {
    increment() {
      this.count++
    }
  }
})

// Setup style
export const useStore = defineStore('storeName', () => {
  const count = ref(0)
  const doubled = computed(() => count.value * 2)
  function increment() {
    count.value++
  }
  return { count, doubled, increment }
})
```

### Using in Components

```vue
<script setup lang="ts">
import { useStore } from '@/stores/store'
import { storeToRefs } from 'pinia'

const store = useStore()
const { count, doubled } = storeToRefs(store)
const { increment } = store
</script>
```

### Common Patterns

| Pattern | Use Case |
|---------|----------|
| Options Store | Traditional, Vuex-like structure |
| Setup Store | Composition API style, more flexible |
| Store Composition | Combine multiple stores |
| Persistent State | Save state to localStorage |
| Reset State | `store.$reset()` |

---

**For this project**: Use Pinia for all state management. Create focused stores for documents, folders, search, UI state, and uploads. Use TypeScript for type safety and the setup store pattern for maximum flexibility.

**Last Updated**: 2025-09-30
