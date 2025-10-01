# Vue 3 Component Patterns

**Area**: Component Development, Composition API, Template Security
**Related**: [MASTER](./MASTER.md), [Architecture](./01-ARCHITECTURE.md), [Security](./02-SECURITY.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers Vue 3 component patterns using Composition API with `<script setup>`, focusing on security, type safety, and maintainability.

---

## Composition API with `<script setup>`

### Basic Component Structure

```vue
<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import type { PropType } from 'vue'

// 1. Imports
// 2. Props & Emits
// 3. Composables & Stores
// 4. Reactive State
// 5. Computed Properties
// 6. Methods/Functions
// 7. Lifecycle Hooks
// 8. Watchers
</script>

<template>
  <!-- Template here -->
</template>

<style scoped>
/* Scoped styles here */
</style>
```

---

## Props and Emits with TypeScript

### Props Definition

**Good - Using TypeScript Interface**:
```vue
<script setup lang="ts">
interface Props {
  userId: string
  items: Document[]
  maxItems?: number
  showActions?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  maxItems: 10,
  showActions: true
})
</script>
```

**Bad - No Types**:
```vue
<script setup>
// ❌ No type safety
const props = defineProps({
  userId: String,
  items: Array
})
</script>
```

### Emits Definition

**Good - Typed Events**:
```vue
<script setup lang="ts">
import type { Document } from '@/types/models/document'

interface Emits {
  (e: 'select', document: Document): void
  (e: 'delete', documentId: string): void
  (e: 'update', documentId: string, data: Partial<Document>): void
}

const emit = defineEmits<Emits>()

function handleSelect(doc: Document) {
  emit('select', doc)
}
</script>
```

### Props Validation

Always validate props, especially user-provided data:

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { z } from 'zod'

interface Props {
  email: string
  age: number
  url?: string
}

const props = defineProps<Props>()

// Validate props on mount
const emailSchema = z.string().email()
const ageSchema = z.number().min(0).max(150)
const urlSchema = z.string().url()

const validatedEmail = computed(() => {
  const result = emailSchema.safeParse(props.email)
  return result.success ? result.data : null
})
</script>
```

---

## Component Size Management

### Keep Components Under 200 Lines

**Strategy 1: Extract Child Components**

```vue
<!-- Before: UserProfile.vue (250 lines) -->
<template>
  <div>
    <!-- 80 lines of header -->
    <!-- 90 lines of details -->
    <!-- 80 lines of activity feed -->
  </div>
</template>

<!-- After: UserProfile.vue (60 lines) -->
<template>
  <div>
    <UserProfileHeader :user="user" />
    <UserProfileDetails :user="user" />
    <UserActivityFeed :userId="user.id" />
  </div>
</template>
```

**Strategy 2: Extract Logic to Composables**

```vue
<!-- Before: DocumentList.vue (220 lines) -->
<script setup lang="ts">
// 50 lines of data fetching
// 40 lines of filtering
// 30 lines of sorting
// 40 lines of pagination
// 60 lines of template
</script>

<!-- After: DocumentList.vue (80 lines) -->
<script setup lang="ts">
import { useDocumentData } from '@/composables/useDocumentData'
import { useDocumentFilters } from '@/composables/useDocumentFilters'
import { usePagination } from '@/composables/usePagination'

const { documents, loading, error } = useDocumentData()
const { filteredDocuments, applyFilter } = useDocumentFilters(documents)
const { paginatedItems, page, pageSize } = usePagination(filteredDocuments)
</script>
```

---

## Reactive State

### State Declaration

```vue
<script setup lang="ts">
import { ref, reactive, readonly } from 'vue'

// Primitive values - use ref
const count = ref(0)
const name = ref('')
const isActive = ref(false)

// Objects - use reactive
const user = reactive({
  id: '',
  name: '',
  email: ''
})

// Expose readonly state to prevent external mutations
const state = reactive({ count: 0 })
const readonlyState = readonly(state)

defineExpose({ readonlyState })
</script>
```

### Secure State Management

**Never expose sensitive data directly**:

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { SensitiveToken } from '@/types/security/auth'

// ❌ Bad - Token exposed
const authToken = ref<string>('')

// ✅ Good - Token hidden, only expose validation
const authToken = ref<SensitiveToken | null>(null)
const isAuthenticated = computed(() => authToken.value !== null)

// Only expose what's needed
defineExpose({ isAuthenticated })
</script>
```

---

## Computed Properties

### Basic Computed

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Document } from '@/types/models/document'

const documents = ref<Document[]>([])
const searchQuery = ref('')

// Computed property with type inference
const filteredDocuments = computed(() => {
  const query = searchQuery.value.toLowerCase()
  return documents.value.filter(doc =>
    doc.name.toLowerCase().includes(query)
  )
})

// Computed with explicit type
const documentCount = computed<number>(() => documents.value.length)
</script>
```

### Computed with Getters and Setters

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

const firstName = ref('John')
const lastName = ref('Doe')

const fullName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (value: string) => {
    const [first, last] = value.split(' ')
    firstName.value = first
    lastName.value = last
  }
})
</script>

<template>
  <v-text-field v-model="fullName" />
</template>
```

---

## Lifecycle Hooks

### Common Lifecycle Patterns

```vue
<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, onErrorCaptured } from 'vue'

const data = ref<any[]>([])

// On component mount
onMounted(async () => {
  try {
    data.value = await fetchData()
  } catch (error) {
    console.error('Failed to load data:', error)
  }
})

// Cleanup on unmount
let intervalId: number | null = null

onMounted(() => {
  intervalId = setInterval(() => {
    // Periodic task
  }, 5000)
})

onBeforeUnmount(() => {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = null
  }
})

// Error handling
onErrorCaptured((err, instance, info) => {
  console.error('Component error:', err, info)
  // Return false to prevent error propagation
  return false
})
</script>
```

---

## Watchers

### Basic Watch

```vue
<script setup lang="ts">
import { ref, watch } from 'vue'

const searchQuery = ref('')
const results = ref<any[]>([])

// Watch a single ref
watch(searchQuery, async (newQuery, oldQuery) => {
  if (newQuery !== oldQuery) {
    results.value = await search(newQuery)
  }
})
</script>
```

### Watch Multiple Sources

```vue
<script setup lang="ts">
import { ref, watch } from 'vue'

const firstName = ref('')
const lastName = ref('')

// Watch multiple sources
watch([firstName, lastName], ([newFirst, newLast]) => {
  console.log(`Name changed to: ${newFirst} ${newLast}`)
})
</script>
```

### WatchEffect for Automatic Tracking

```vue
<script setup lang="ts">
import { ref, watchEffect } from 'vue'

const url = ref('https://api.example.com/data')
const data = ref(null)

// Automatically tracks all reactive dependencies
watchEffect(async () => {
  const response = await fetch(url.value)
  data.value = await response.json()
})
</script>
```

### Watch with Options

```vue
<script setup lang="ts">
import { ref, watch } from 'vue'

const user = ref({ name: '', email: '' })

// Deep watch for objects
watch(
  user,
  (newUser) => {
    console.log('User updated:', newUser)
  },
  { deep: true, immediate: true }
)
</script>
```

---

## Template Security Patterns

### CRITICAL: XSS Prevention

**Never use v-html with user content**:

```vue
<template>
  <!-- ❌ DANGEROUS - XSS vulnerability -->
  <div v-html="userComment"></div>

  <!-- ✅ SAFE - Text rendering -->
  <div>{{ userComment }}</div>

  <!-- ✅ SAFE - Sanitized HTML if absolutely necessary -->
  <div v-html="sanitizedHTML"></div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import DOMPurify from 'dompurify'

interface Props {
  userComment: string
}

const props = defineProps<Props>()

const sanitizedHTML = computed(() =>
  DOMPurify.sanitize(props.userComment, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong'],
    ALLOWED_ATTR: []
  })
)
</script>
```

### Secure Dynamic Binding

```vue
<template>
  <!-- ❌ DANGEROUS - User-controlled URLs -->
  <a :href="userUrl">Click here</a>

  <!-- ✅ SAFE - Validated URL -->
  <a :href="safeUrl">Click here</a>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { z } from 'zod'

interface Props {
  userUrl: string
}

const props = defineProps<Props>()

const urlSchema = z.string().url().refine(
  (url) => url.startsWith('https://'),
  { message: 'Only HTTPS URLs allowed' }
)

const safeUrl = computed(() => {
  const result = urlSchema.safeParse(props.userUrl)
  return result.success ? result.data : '#'
})
</script>
```

### Conditional Rendering

```vue
<template>
  <!-- Use v-if for conditional rendering -->
  <div v-if="isAuthenticated">
    <SecretData />
  </div>

  <!-- Use v-show for toggling visibility (element stays in DOM) -->
  <div v-show="isVisible">
    <PublicData />
  </div>

  <!-- Never rely on v-show for security -->
  <!-- ❌ Bad - Data still in DOM -->
  <div v-show="isAdmin">
    <AdminPanel />
  </div>

  <!-- ✅ Good - Component not rendered -->
  <div v-if="isAdmin">
    <AdminPanel />
  </div>
</template>
```

---

## List Rendering

### Using v-for Securely

```vue
<template>
  <!-- Always use :key with unique, stable identifiers -->
  <div v-for="doc in documents" :key="doc.id">
    {{ doc.name }}
  </div>

  <!-- ❌ Bad - Index as key (unstable) -->
  <div v-for="(doc, index) in documents" :key="index">
    {{ doc.name }}
  </div>

  <!-- Filter sensitive data before rendering -->
  <div v-for="user in publicUsers" :key="user.id">
    {{ user.name }}
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { User } from '@/types/models/user'

interface Props {
  users: User[]
}

const props = defineProps<Props>()

// Remove sensitive fields
const publicUsers = computed(() =>
  props.users.map(user => ({
    id: user.id,
    name: user.name,
    // Don't expose: email, phone, ssn, etc.
  }))
)
</script>
```

---

## Form Input Handling

### Secure v-model Usage

```vue
<template>
  <v-form ref="form" v-model="valid">
    <!-- Text input with validation -->
    <v-text-field
      v-model="username"
      label="Username"
      :rules="usernameRules"
      counter="30"
      maxlength="30"
    />

    <!-- Email with validation -->
    <v-text-field
      v-model="email"
      label="Email"
      type="email"
      :rules="emailRules"
    />

    <!-- Password with secure input -->
    <v-text-field
      v-model="password"
      label="Password"
      type="password"
      :rules="passwordRules"
      autocomplete="new-password"
    />
  </v-form>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { z } from 'zod'

const form = ref()
const valid = ref(false)

const username = ref('')
const email = ref('')
const password = ref('')

// Client-side validation rules
const usernameRules = [
  (v: string) => !!v || 'Username is required',
  (v: string) => (v && v.length >= 3) || 'Min 3 characters',
  (v: string) => (v && v.length <= 30) || 'Max 30 characters',
  (v: string) => /^[a-zA-Z0-9_-]+$/.test(v) || 'Alphanumeric only'
]

const emailRules = [
  (v: string) => !!v || 'Email is required',
  (v: string) => z.string().email().safeParse(v).success || 'Invalid email'
]

const passwordRules = [
  (v: string) => !!v || 'Password is required',
  (v: string) => (v && v.length >= 8) || 'Min 8 characters',
  (v: string) => /(?=.*[a-z])/.test(v) || 'Must contain lowercase',
  (v: string) => /(?=.*[A-Z])/.test(v) || 'Must contain uppercase',
  (v: string) => /(?=.*\d)/.test(v) || 'Must contain number',
  (v: string) => /(?=.*[@$!%*?&])/.test(v) || 'Must contain special char'
]
</script>
```

---

## Component Communication

### Parent-Child via Props/Emits

```vue
<!-- Parent.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import ChildComponent from './ChildComponent.vue'
import type { Document } from '@/types/models/document'

const documents = ref<Document[]>([])

function handleDocumentSelect(doc: Document) {
  console.log('Selected:', doc)
}
</script>

<template>
  <ChildComponent
    :documents="documents"
    @select="handleDocumentSelect"
  />
</template>
```

```vue
<!-- ChildComponent.vue -->
<script setup lang="ts">
import type { Document } from '@/types/models/document'

interface Props {
  documents: Document[]
}

interface Emits {
  (e: 'select', document: Document): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

function selectDocument(doc: Document) {
  emit('select', doc)
}
</script>

<template>
  <div v-for="doc in documents" :key="doc.id">
    <button @click="selectDocument(doc)">
      {{ doc.name }}
    </button>
  </div>
</template>
```

### Provide/Inject for Deep Hierarchies

```vue
<!-- Provider (Parent/Ancestor) -->
<script setup lang="ts">
import { provide, readonly, reactive } from 'vue'

const theme = reactive({
  primary: '#1976D2',
  secondary: '#424242'
})

// Provide readonly to prevent child mutations
provide('theme', readonly(theme))
</script>
```

```vue
<!-- Consumer (Child/Descendant) -->
<script setup lang="ts">
import { inject } from 'vue'
import type { Theme } from '@/types/theme'

const theme = inject<Theme>('theme')
</script>

<template>
  <div :style="{ color: theme?.primary }">
    Themed content
  </div>
</template>
```

---

## Component Composition

### Using Composables

```vue
<script setup lang="ts">
import { useDocumentStore } from '@/stores/documentStore'
import { useSecureFileUpload } from '@/composables/useSecureFileUpload'
import { useRateLimiter } from '@/composables/useRateLimiter'

const documentStore = useDocumentStore()
const { upload, progress, error } = useSecureFileUpload()
const { checkLimit, remaining } = useRateLimiter('upload', 10, 60000)

async function handleUpload(file: File) {
  if (!checkLimit()) {
    alert(`Rate limit exceeded. Try again in ${remaining}ms`)
    return
  }

  await upload(file)
}
</script>
```

---

## Error Boundaries

### Component Error Handling

```vue
<script setup lang="ts">
import { ref, onErrorCaptured } from 'vue'

const error = ref<Error | null>(null)
const errorInfo = ref<string>('')

onErrorCaptured((err, instance, info) => {
  error.value = err
  errorInfo.value = info

  // Log to monitoring service
  console.error('Component error:', err, info)

  // Prevent error propagation
  return false
})
</script>

<template>
  <div v-if="error" class="error-boundary">
    <h3>Something went wrong</h3>
    <p>{{ error.message }}</p>
  </div>
  <div v-else>
    <slot />
  </div>
</template>
```

---

## Component Testing Checklist

- [ ] Props are properly typed
- [ ] Emits are properly typed
- [ ] No `v-html` with user content
- [ ] All URLs are validated
- [ ] Form inputs have validation
- [ ] Component stays under 200 lines
- [ ] No sensitive data exposed
- [ ] Lifecycle cleanup implemented
- [ ] Error boundaries in place
- [ ] Accessible (ARIA labels, keyboard nav)

---

## Related Guidelines

- **For component size limits**: See [Architecture](./01-ARCHITECTURE.md)
- **For security patterns**: See [Security](./02-SECURITY.md)
- **For state management**: See [State](./04-STATE.md)
- **For form validation**: See [Validation](./06-VALIDATION.md)

---

**Remember**: Components are the building blocks of your application. Keep them small, secure, and focused on a single responsibility.
