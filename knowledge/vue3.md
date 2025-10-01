# Vue 3 - Comprehensive Guide

**Technology**: Vue 3
**Category**: Frontend Framework
**Official Docs**: https://vuejs.org

---

## Overview

Vue 3 is a progressive JavaScript framework for building user interfaces. It features the Composition API, improved TypeScript support, better performance, and a modular architecture.

### Key Features
- **Composition API** - Better logic reuse and TypeScript support
- **Reactive System** - Proxy-based reactivity
- **Virtual DOM** - Efficient UI updates
- **Component-Based** - Reusable UI components
- **Single File Components (SFC)** - `.vue` files
- **Progressive** - Can be adopted incrementally

---

## Design Patterns

### 1. Composition API Pattern

**Purpose**: Organize logic by feature rather than by option type

```typescript
// composables/useCounter.ts
import { ref, computed } from 'vue'

export function useCounter(initialValue = 0) {
  const count = ref(initialValue)
  const doubled = computed(() => count.value * 2)

  function increment() {
    count.value++
  }

  function decrement() {
    count.value--
  }

  return {
    count,
    doubled,
    increment,
    decrement
  }
}

// Component using the composable
<script setup lang="ts">
import { useCounter } from '@/composables/useCounter'

const { count, doubled, increment, decrement } = useCounter(0)
</script>

<template>
  <div>
    <p>Count: {{ count }}</p>
    <p>Doubled: {{ doubled }}</p>
    <button @click="increment">+</button>
    <button @click="decrement">-</button>
  </div>
</template>
```

### 2. Provide/Inject Pattern

**Purpose**: Pass data to deeply nested components

```typescript
// Parent component
<script setup lang="ts">
import { provide, ref } from 'vue'

const theme = ref('dark')
provide('theme', theme)
</script>

// Child component (any level deep)
<script setup lang="ts">
import { inject } from 'vue'

const theme = inject('theme')
</script>
```

### 3. Composable Pattern

**Purpose**: Extract and reuse stateful logic

```typescript
// composables/useApi.ts
import { ref } from 'vue'
import axios from 'axios'

export function useApi<T>(url: string) {
  const data = ref<T | null>(null)
  const error = ref<Error | null>(null)
  const loading = ref(false)

  async function fetch() {
    loading.value = true
    error.value = null

    try {
      const response = await axios.get<T>(url)
      data.value = response.data
    } catch (e) {
      error.value = e as Error
    } finally {
      loading.value = false
    }
  }

  return { data, error, loading, fetch }
}

// Usage in component
<script setup lang="ts">
import { useApi } from '@/composables/useApi'
import { onMounted } from 'vue'

interface User {
  id: number
  name: string
}

const { data: users, loading, error, fetch } = useApi<User[]>('/api/users')

onMounted(() => {
  fetch()
})
</script>
```

---

## Best Practices

### 1. Use `<script setup>` Syntax

**Do**:
```vue
<script setup lang="ts">
import { ref } from 'vue'

const count = ref(0)
const increment = () => count.value++
</script>
```

**Don't**:
```vue
<script lang="ts">
export default {
  setup() {
    const count = ref(0)
    return { count }
  }
}
</script>
```

### 2. Reactive References

**Do**: Use `ref()` for primitives, `reactive()` for objects
```typescript
const count = ref(0)
const user = reactive({ name: 'John', age: 30 })
```

**Don't**: Destructure reactive objects
```typescript
// WRONG - loses reactivity
const { name, age } = reactive({ name: 'John', age: 30 })

// CORRECT - use toRefs
const state = reactive({ name: 'John', age: 30 })
const { name, age } = toRefs(state)
```

### 3. Computed Properties

**Do**: Use for derived state
```typescript
const firstName = ref('John')
const lastName = ref('Doe')
const fullName = computed(() => `${firstName.value} ${lastName.value}`)
```

**Don't**: Use methods for derived state
```typescript
// Inefficient - recalculates on every render
const getFullName = () => `${firstName.value} ${lastName.value}`
```

### 4. Component Naming

**Do**: Use PascalCase for components
```typescript
import DocumentList from '@/components/DocumentList.vue'
```

**Do**: Use kebab-case in templates
```vue
<document-list />
```

### 5. Props Definition

**Do**: Define props with types
```typescript
<script setup lang="ts">
interface Props {
  title: string
  count?: number
  items: string[]
}

const props = withDefaults(defineProps<Props>(), {
  count: 0
})
</script>
```

### 6. Emit Events with Types

```typescript
<script setup lang="ts">
interface Emits {
  (e: 'update', value: string): void
  (e: 'delete', id: number): void
}

const emit = defineEmits<Emits>()

function handleUpdate(value: string) {
  emit('update', value)
}
</script>
```

---

## Common Patterns for Document Manager

### 1. Document List Component

```vue
<script setup lang="ts">
import { computed } from 'vue'
import type { Document } from '@/types/document'

interface Props {
  documents: Document[]
  loading?: boolean
}

interface Emits {
  (e: 'select', doc: Document): void
  (e: 'delete', id: string): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<Emits>()

const isEmpty = computed(() => props.documents.length === 0)
</script>

<template>
  <div class="document-list">
    <div v-if="loading" class="loading">
      Loading documents...
    </div>

    <div v-else-if="isEmpty" class="empty">
      No documents found
    </div>

    <div v-else class="list">
      <div
        v-for="doc in documents"
        :key="doc.id"
        class="document-item"
        @click="emit('select', doc)"
      >
        <h3>{{ doc.name }}</h3>
        <p>{{ doc.size }} bytes</p>
        <button @click.stop="emit('delete', doc.id)">
          Delete
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.document-item {
  padding: 1rem;
  border: 1px solid #ccc;
  margin-bottom: 0.5rem;
  cursor: pointer;
}

.document-item:hover {
  background-color: #f5f5f5;
}
</style>
```

### 2. File Upload Component

```vue
<script setup lang="ts">
import { ref } from 'vue'

interface Emits {
  (e: 'upload', file: File): void
}

const emit = defineEmits<Emits>()

const dragOver = ref(false)
const fileInput = ref<HTMLInputElement>()

function handleDrop(event: DragEvent) {
  dragOver.value = false
  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    emit('upload', files[0])
  }
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement
  const files = target.files
  if (files && files.length > 0) {
    emit('upload', files[0])
  }
}

function openFileDialog() {
  fileInput.value?.click()
}
</script>

<template>
  <div
    class="upload-area"
    :class="{ 'drag-over': dragOver }"
    @dragover.prevent="dragOver = true"
    @dragleave="dragOver = false"
    @drop.prevent="handleDrop"
    @click="openFileDialog"
  >
    <input
      ref="fileInput"
      type="file"
      style="display: none"
      @change="handleFileSelect"
    />
    <p>Drag and drop file here or click to browse</p>
  </div>
</template>

<style scoped>
.upload-area {
  border: 2px dashed #ccc;
  padding: 2rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.upload-area:hover,
.upload-area.drag-over {
  border-color: #42b983;
  background-color: #f0f9ff;
}
</style>
```

### 3. Folder Tree Component

```vue
<script setup lang="ts">
import { ref } from 'vue'
import type { Folder } from '@/types/folder'

interface Props {
  folder: Folder
  level?: number
}

interface Emits {
  (e: 'select', folder: Folder): void
}

const props = withDefaults(defineProps<Props>(), {
  level: 0
})

const emit = defineEmits<Emits>()

const isExpanded = ref(false)

function toggleExpand() {
  isExpanded.value = !isExpanded.value
}
</script>

<template>
  <div class="folder-node">
    <div
      class="folder-header"
      :style="{ paddingLeft: `${level * 20}px` }"
      @click="emit('select', folder)"
    >
      <span
        v-if="folder.children && folder.children.length > 0"
        class="expand-icon"
        @click.stop="toggleExpand"
      >
        {{ isExpanded ? '▼' : '▶' }}
      </span>
      <span class="folder-icon">📁</span>
      <span class="folder-name">{{ folder.name }}</span>
      <span class="folder-count">({{ folder.documentCount }})</span>
    </div>

    <div v-if="isExpanded && folder.children" class="folder-children">
      <folder-tree
        v-for="child in folder.children"
        :key="child.id"
        :folder="child"
        :level="level + 1"
        @select="emit('select', $event)"
      />
    </div>
  </div>
</template>

<style scoped>
.folder-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  cursor: pointer;
}

.folder-header:hover {
  background-color: #f5f5f5;
}

.expand-icon {
  width: 20px;
  cursor: pointer;
}
</style>
```

---

## Lifecycle Hooks

```typescript
<script setup lang="ts">
import { onMounted, onUpdated, onUnmounted, ref } from 'vue'

// Called after component is mounted
onMounted(() => {
  console.log('Component mounted')
  // Fetch data, setup event listeners, etc.
})

// Called after component updates
onUpdated(() => {
  console.log('Component updated')
})

// Called before component is unmounted
onUnmounted(() => {
  console.log('Component unmounted')
  // Cleanup: remove event listeners, cancel requests, etc.
})

// Watch for changes
import { watch } from 'vue'

const count = ref(0)

watch(count, (newValue, oldValue) => {
  console.log(`Count changed from ${oldValue} to ${newValue}`)
})

// Watch multiple sources
watch([count, otherRef], ([newCount, newOther], [oldCount, oldOther]) => {
  console.log('Multiple values changed')
})

// Watch with immediate execution
watch(count, (value) => {
  console.log('Count:', value)
}, { immediate: true })
</script>
```

---

## Performance Optimization

### 1. Use `v-show` vs `v-if`

```vue
<!-- Use v-if for conditional rendering (removes from DOM) -->
<div v-if="showDetails">Details</div>

<!-- Use v-show for toggling visibility (stays in DOM) -->
<div v-show="isVisible">Toggle me frequently</div>
```

### 2. Use `v-memo` for Expensive Lists

```vue
<template>
  <div
    v-for="item in list"
    :key="item.id"
    v-memo="[item.id, item.selected]"
  >
    <!-- Only re-renders if id or selected changes -->
    {{ item.name }}
  </div>
</template>
```

### 3. Lazy Load Components

```typescript
import { defineAsyncComponent } from 'vue'

const DocumentViewer = defineAsyncComponent(() =>
  import('@/components/DocumentViewer.vue')
)
```

### 4. Use `shallowRef` and `shallowReactive`

```typescript
import { shallowRef } from 'vue'

// Only top-level properties are reactive
const state = shallowRef({ nested: { value: 1 } })
```

---

## Testing

### Unit Test Example (Vitest)

```typescript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import DocumentList from '@/components/DocumentList.vue'

describe('DocumentList', () => {
  it('renders documents', () => {
    const documents = [
      { id: '1', name: 'Doc 1', size: 1024 },
      { id: '2', name: 'Doc 2', size: 2048 }
    ]

    const wrapper = mount(DocumentList, {
      props: { documents }
    })

    expect(wrapper.findAll('.document-item')).toHaveLength(2)
    expect(wrapper.text()).toContain('Doc 1')
  })

  it('emits select event', async () => {
    const documents = [{ id: '1', name: 'Doc 1', size: 1024 }]

    const wrapper = mount(DocumentList, {
      props: { documents }
    })

    await wrapper.find('.document-item').trigger('click')

    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')?.[0]).toEqual([documents[0]])
  })
})
```

---

## Common Pitfalls

### 1. Mutating Props

**Don't**:
```typescript
const props = defineProps<{ count: number }>()
props.count++ // ERROR: Props are readonly
```

**Do**:
```typescript
const props = defineProps<{ count: number }>()
const localCount = ref(props.count)
localCount.value++
```

### 2. Accessing `.value` in Template

**Don't**:
```vue
<template>
  <div>{{ count.value }}</div> <!-- WRONG -->
</template>
```

**Do**:
```vue
<template>
  <div>{{ count }}</div> <!-- Automatically unwrapped -->
</template>
```

### 3. Forgetting `await nextTick`

```typescript
import { nextTick } from 'vue'

const message = ref('Hello')

function updateMessage() {
  message.value = 'Updated'

  // DOM not updated yet
  console.log(document.getElementById('msg')?.textContent) // "Hello"

  nextTick(() => {
    // DOM updated
    console.log(document.getElementById('msg')?.textContent) // "Updated"
  })
}
```

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://vuejs.org
- **API Reference**: https://vuejs.org/api/
- **Style Guide**: https://vuejs.org/style-guide/
- **Examples**: https://vuejs.org/examples/

### Ecosystem
- **Vue Router**: https://router.vuejs.org
- **Pinia**: https://pinia.vuejs.org
- **Vite**: https://vitejs.dev
- **Vitest**: https://vitest.dev

### Learning Resources
- **Vue Mastery**: https://www.vuemastery.com
- **Vue School**: https://vueschool.io
- **Official Tutorial**: https://vuejs.org/tutorial/

### Community
- **Discord**: https://chat.vuejs.org
- **Forum**: https://forum.vuejs.org
- **GitHub**: https://github.com/vuejs/core

---

## Quick Reference

### Creating a Component

```vue
<script setup lang="ts">
// Imports
import { ref, computed } from 'vue'

// Props
interface Props {
  title: string
}
const props = defineProps<Props>()

// Emits
interface Emits {
  (e: 'save', value: string): void
}
const emit = defineEmits<Emits>()

// State
const message = ref('')

// Computed
const uppercase = computed(() => message.value.toUpperCase())

// Methods
function save() {
  emit('save', message.value)
}
</script>

<template>
  <div>
    <h1>{{ props.title }}</h1>
    <input v-model="message" />
    <p>{{ uppercase }}</p>
    <button @click="save">Save</button>
  </div>
</template>

<style scoped>
/* Scoped styles */
</style>
```

### Common Directives

| Directive | Purpose | Example |
|-----------|---------|---------|
| `v-if` | Conditional rendering | `<div v-if="show">` |
| `v-show` | Toggle visibility | `<div v-show="visible">` |
| `v-for` | List rendering | `<div v-for="item in items" :key="item.id">` |
| `v-model` | Two-way binding | `<input v-model="text">` |
| `v-bind` / `:` | Bind attribute | `:href="url"` |
| `v-on` / `@` | Event listener | `@click="handler"` |
| `v-slot` / `#` | Named slots | `#header` |

---

**For this project**: Use Vue 3 with Composition API and `<script setup>` for all components. Leverage TypeScript for type safety and create composables for shared logic.
