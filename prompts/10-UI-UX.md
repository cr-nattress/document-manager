# UI/UX Patterns with Vuetify 3

**Area**: User Interface, User Experience, Material Design, Accessibility
**Related**: [MASTER](./MASTER.md), [Components](./03-COMPONENTS.md), [State](./04-STATE.md)
**Last Updated**: 2025-10-01

---

## Overview

This guide covers UI/UX patterns specific to Vuetify 3, including Material Design principles, component usage, theming, and accessibility best practices.

---

## UI State Management

### Global UI Store Pattern

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

---

## Vuetify Theme Configuration

### Dynamic Theme Switching

```typescript
// plugins/vuetify.ts
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles'

export default createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        dark: false,
        colors: {
          primary: '#1976D2',
          secondary: '#424242',
          accent: '#82B1FF',
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
          background: '#FFFFFF',
          surface: '#FFFFFF'
        }
      },
      dark: {
        dark: true,
        colors: {
          primary: '#2196F3',
          secondary: '#616161',
          accent: '#FF4081',
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
          background: '#121212',
          surface: '#1E1E1E'
        }
      }
    }
  },
  defaults: {
    VBtn: {
      variant: 'elevated',
      rounded: 'md'
    },
    VCard: {
      elevation: 2,
      rounded: 'lg'
    },
    VTextField: {
      variant: 'outlined',
      density: 'comfortable'
    },
    VSelect: {
      variant: 'outlined',
      density: 'comfortable'
    }
  }
})
```

### Theme Toggle Component

```vue
<script setup lang="ts">
import { useTheme } from 'vuetify'
import { useUIStore } from '@/stores/ui'

const theme = useTheme()
const uiStore = useUIStore()

function toggleTheme() {
  const newTheme = theme.global.current.value.dark ? 'light' : 'dark'
  theme.global.name.value = newTheme
  uiStore.setTheme(newTheme)
}

const isDark = computed(() => theme.global.current.value.dark)
</script>

<template>
  <v-btn
    :icon="isDark ? 'mdi-weather-sunny' : 'mdi-weather-night'"
    @click="toggleTheme"
    aria-label="Toggle theme"
  />
</template>
```

---

## Feedback Components

### Notification Snackbar System

```typescript
// stores/notification.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

interface Notification {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  timeout?: number
  action?: {
    text: string
    handler: () => void
  }
}

export const useNotificationStore = defineStore('notification', () => {
  const notifications = ref<Notification[]>([])

  function addNotification(
    type: Notification['type'],
    message: string,
    options?: { timeout?: number; action?: Notification['action'] }
  ) {
    const id = `notification-${Date.now()}-${Math.random()}`

    notifications.value.push({
      id,
      type,
      message,
      timeout: options?.timeout ?? 5000,
      action: options?.action
    })

    return id
  }

  function success(message: string, options?: any) {
    return addNotification('success', message, options)
  }

  function error(message: string, options?: any) {
    return addNotification('error', message, options)
  }

  function warning(message: string, options?: any) {
    return addNotification('warning', message, options)
  }

  function info(message: string, options?: any) {
    return addNotification('info', message, options)
  }

  function remove(id: string) {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index > -1) {
      notifications.value.splice(index, 1)
    }
  }

  function clear() {
    notifications.value = []
  }

  return {
    notifications,
    success,
    error,
    warning,
    info,
    remove,
    clear
  }
})
```

```vue
<!-- components/common/NotificationContainer.vue -->
<script setup lang="ts">
import { useNotificationStore } from '@/stores/notification'

const notificationStore = useNotificationStore()

function handleClose(id: string) {
  notificationStore.remove(id)
}

function getColor(type: string) {
  switch (type) {
    case 'success': return 'success'
    case 'error': return 'error'
    case 'warning': return 'warning'
    case 'info': return 'info'
    default: return 'primary'
  }
}

function getIcon(type: string) {
  switch (type) {
    case 'success': return 'mdi-check-circle'
    case 'error': return 'mdi-alert-circle'
    case 'warning': return 'mdi-alert'
    case 'info': return 'mdi-information'
    default: return 'mdi-bell'
  }
}
</script>

<template>
  <div class="notification-container">
    <v-snackbar
      v-for="notification in notificationStore.notifications"
      :key="notification.id"
      :model-value="true"
      :color="getColor(notification.type)"
      :timeout="notification.timeout"
      location="top right"
      multi-line
      @update:model-value="handleClose(notification.id)"
    >
      <div class="d-flex align-center">
        <v-icon :icon="getIcon(notification.type)" class="mr-3" />
        <span>{{ notification.message }}</span>
      </div>

      <template #actions>
        <v-btn
          v-if="notification.action"
          variant="text"
          @click="notification.action.handler"
        >
          {{ notification.action.text }}
        </v-btn>
        <v-btn
          icon="mdi-close"
          variant="text"
          @click="handleClose(notification.id)"
        />
      </template>
    </v-snackbar>
  </div>
</template>
```

---

## Loading States

### Global Loading Overlay

```vue
<!-- components/common/GlobalLoading.vue -->
<script setup lang="ts">
import { useUIStore } from '@/stores/ui'

const uiStore = useUIStore()
</script>

<template>
  <v-overlay
    :model-value="uiStore.globalLoading"
    persistent
    class="align-center justify-center"
    scrim="rgba(0, 0, 0, 0.7)"
  >
    <div class="text-center">
      <v-progress-circular
        indeterminate
        size="64"
        color="primary"
      />
      <p v-if="uiStore.loadingMessage" class="mt-4 text-h6">
        {{ uiStore.loadingMessage }}
      </p>
    </div>
  </v-overlay>
</template>
```

### Skeleton Loaders

```vue
<!-- components/common/DocumentCardSkeleton.vue -->
<template>
  <v-card>
    <v-skeleton-loader
      type="image, article, actions"
      :loading="true"
    />
  </v-card>
</template>
```

---

## Modal Management

### Centralized Modal System

```vue
<!-- components/common/ModalManager.vue -->
<script setup lang="ts">
import { useUIStore } from '@/stores/ui'
import { defineAsyncComponent } from 'vue'

const uiStore = useUIStore()

// Lazy load modal components
const modals = {
  'confirm-dialog': defineAsyncComponent(() => import('./ConfirmDialog.vue')),
  'upload-dialog': defineAsyncComponent(() => import('./UploadDialog.vue')),
  'edit-dialog': defineAsyncComponent(() => import('./EditDialog.vue'))
}

function handleClose(id: string) {
  uiStore.closeModal(id)
}
</script>

<template>
  <div class="modal-manager">
    <component
      v-for="[id, data] in uiStore.activeModals"
      :key="id"
      :is="modals[id]"
      :model-value="true"
      :data="data"
      @close="handleClose(id)"
      @update:model-value="!$event && handleClose(id)"
    />
  </div>
</template>
```

---

## Responsive Design Patterns

### Responsive Data Table

```vue
<script setup lang="ts">
import { useDisplay } from 'vuetify'

const { xs, sm, md } = useDisplay()

const headers = computed(() => {
  const baseHeaders = [
    { title: 'Name', key: 'name', sortable: true },
    { title: 'Email', key: 'email', sortable: true },
    { title: 'Role', key: 'role', sortable: true },
    { title: 'Status', key: 'status', sortable: true },
    { title: 'Actions', key: 'actions', sortable: false }
  ]

  // Hide columns on mobile
  if (xs.value) {
    return baseHeaders.filter(h => ['name', 'actions'].includes(h.key))
  }

  // Hide some columns on tablet
  if (sm.value) {
    return baseHeaders.filter(h => h.key !== 'email')
  }

  return baseHeaders
})
</script>

<template>
  <!-- Desktop view -->
  <v-data-table
    v-if="!xs"
    :headers="headers"
    :items="items"
    :loading="loading"
  >
    <template #item.actions="{ item }">
      <v-btn icon="mdi-pencil" size="small" @click="edit(item)" />
      <v-btn icon="mdi-delete" size="small" @click="remove(item)" />
    </template>
  </v-data-table>

  <!-- Mobile view - Card list -->
  <div v-else class="mobile-list">
    <v-card
      v-for="item in items"
      :key="item.id"
      class="mb-2"
    >
      <v-card-text>
        <div class="text-h6">{{ item.name }}</div>
        <div class="text-caption">{{ item.email }}</div>
      </v-card-text>
      <v-card-actions>
        <v-btn icon="mdi-pencil" @click="edit(item)" />
        <v-btn icon="mdi-delete" @click="remove(item)" />
      </v-card-actions>
    </v-card>
  </div>
</template>
```

---

## Accessibility Patterns

### Accessible Button

```vue
<script setup lang="ts">
interface Props {
  icon?: string
  text?: string
  ariaLabel?: string
  loading?: boolean
  disabled?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void
}>()

const computedAriaLabel = computed(() => {
  if (props.ariaLabel) return props.ariaLabel
  if (props.text) return props.text
  if (props.icon) return props.icon.replace('mdi-', '').replace(/-/g, ' ')
  return 'Button'
})
</script>

<template>
  <v-btn
    :icon="icon"
    :loading="loading"
    :disabled="disabled"
    :aria-label="computedAriaLabel"
    :aria-busy="loading"
    @click="emit('click', $event)"
  >
    <v-icon v-if="icon" :icon="icon" />
    <span v-if="text">{{ text }}</span>
  </v-btn>
</template>
```

### Focus Management

```typescript
// composables/ui/useFocusTrap.ts
import { ref, onMounted, onUnmounted } from 'vue'

export function useFocusTrap(enabled: Ref<boolean>) {
  const firstFocusable = ref<HTMLElement>()
  const lastFocusable = ref<HTMLElement>()

  function getFocusableElements(container: HTMLElement) {
    const selector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    return Array.from(container.querySelectorAll<HTMLElement>(selector))
      .filter(el => !el.hasAttribute('disabled'))
  }

  function handleTabKey(e: KeyboardEvent, container: HTMLElement) {
    if (!enabled.value) return

    const focusableElements = getFocusableElements(container)
    if (focusableElements.length === 0) return

    const first = focusableElements[0]
    const last = focusableElements[focusableElements.length - 1]

    if (e.shiftKey) {
      // Shift + Tab
      if (document.activeElement === first) {
        e.preventDefault()
        last.focus()
      }
    } else {
      // Tab
      if (document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  function activate(container: HTMLElement) {
    const focusableElements = getFocusableElements(container)
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    }
  }

  return {
    handleTabKey,
    activate
  }
}
```

---

## Animation Patterns

### Page Transitions

```vue
<!-- App.vue or router view -->
<template>
  <router-view v-slot="{ Component, route }">
    <transition
      :name="route.meta.transition || 'fade'"
      mode="out-in"
    >
      <component :is="Component" :key="route.path" />
    </transition>
  </router-view>
</template>

<style scoped>
/* Fade transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Slide transition */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from {
  transform: translateX(100%);
}

.slide-leave-to {
  transform: translateX(-100%);
}
</style>
```

---

## UI/UX Best Practices Checklist

- [ ] Consistent theme across all components
- [ ] Dark mode support
- [ ] Loading states for all async operations
- [ ] Error states with helpful messages
- [ ] Empty states with clear actions
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Touch-friendly targets (min 44x44px)
- [ ] Keyboard navigation support
- [ ] ARIA labels and roles
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA
- [ ] No reliance on color alone
- [ ] Smooth animations (60fps)
- [ ] Reduced motion preference respected
- [ ] Consistent spacing and typography

---

## Related Guidelines

- **For component patterns**: See [Components](./03-COMPONENTS.md)
- **For state management**: See [State](./04-STATE.md)
- **For testing UI**: See [Testing](./08-TESTING.md)
- **For accessibility**: See [Testing](./08-TESTING.md#accessibility-tests)

---

**Remember**: Good UI/UX is invisible. Focus on usability, accessibility, and performance.
