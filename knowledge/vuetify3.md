# Vuetify 3 - Comprehensive Guide

**Technology**: Vuetify 3
**Category**: UI Component Framework
**Official Docs**: https://vuetifyjs.com

---

## Overview

Vuetify 3 is a complete Material Design component framework for Vue 3. It provides a comprehensive collection of pre-built, customizable UI components following Google's Material Design specifications.

### Key Features
- **Material Design 3** - Latest Material Design guidelines
- **80+ Components** - Comprehensive component library
- **Responsive Grid System** - 12-column flexbox grid
- **Theme Customization** - Deep theming support with CSS variables
- **Accessibility** - WCAG 2.0 compliant components
- **TypeScript Support** - Full TypeScript definitions
- **Tree Shaking** - Automatic component optimization
- **SSR Ready** - Server-side rendering support

---

## Design Patterns

### 1. Layout Pattern with Navigation

**Purpose**: Create consistent application layout with navigation drawer and app bar

```vue
<script setup lang="ts">
import { ref } from 'vue'

const drawer = ref(true)
const rail = ref(false)

interface MenuItem {
  title: string
  icon: string
  to: string
}

const menuItems: MenuItem[] = [
  { title: 'Documents', icon: 'mdi-file-document', to: '/documents' },
  { title: 'Folders', icon: 'mdi-folder', to: '/folders' },
  { title: 'Search', icon: 'mdi-magnify', to: '/search' },
  { title: 'Upload', icon: 'mdi-upload', to: '/upload' }
]
</script>

<template>
  <v-app>
    <!-- App Bar -->
    <v-app-bar color="primary" prominent>
      <v-app-bar-nav-icon @click="drawer = !drawer" />
      <v-toolbar-title>Document Manager</v-toolbar-title>
      <v-spacer />
      <v-btn icon="mdi-account-circle" />
    </v-app-bar>

    <!-- Navigation Drawer -->
    <v-navigation-drawer
      v-model="drawer"
      :rail="rail"
      permanent
      @click="rail = false"
    >
      <v-list-item
        prepend-icon="mdi-folder-multiple"
        title="Document Manager"
        nav
      >
        <template #append>
          <v-btn
            icon="mdi-chevron-left"
            variant="text"
            @click.stop="rail = !rail"
          />
        </template>
      </v-list-item>

      <v-divider />

      <v-list density="compact" nav>
        <v-list-item
          v-for="item in menuItems"
          :key="item.to"
          :prepend-icon="item.icon"
          :title="item.title"
          :to="item.to"
          :value="item.to"
        />
      </v-list>
    </v-navigation-drawer>

    <!-- Main Content -->
    <v-main>
      <v-container fluid>
        <router-view />
      </v-container>
    </v-main>
  </v-app>
</template>
```

### 2. Data Table Pattern

**Purpose**: Display and manage lists of data with sorting, pagination, and actions

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Document } from '@/types/document'

interface Props {
  documents: Document[]
  loading?: boolean
}

interface Emits {
  (e: 'view', doc: Document): void
  (e: 'download', doc: Document): void
  (e: 'delete', doc: Document): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<Emits>()

const search = ref('')
const page = ref(1)
const itemsPerPage = ref(10)

const headers = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Size', key: 'size', sortable: true },
  { title: 'Type', key: 'contentType', sortable: true },
  { title: 'Modified', key: 'modifiedAt', sortable: true },
  { title: 'Actions', key: 'actions', sortable: false }
]

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

function formatDate(date: string): string {
  return new Date(date).toLocaleDateString()
}
</script>

<template>
  <v-card>
    <v-card-title>
      <v-row>
        <v-col cols="12" md="6">
          <h2>Documents</h2>
        </v-col>
        <v-col cols="12" md="6">
          <v-text-field
            v-model="search"
            prepend-inner-icon="mdi-magnify"
            label="Search documents"
            single-line
            hide-details
            clearable
          />
        </v-col>
      </v-row>
    </v-card-title>

    <v-data-table
      :headers="headers"
      :items="documents"
      :search="search"
      :loading="loading"
      :items-per-page="itemsPerPage"
      :page="page"
      @update:page="page = $event"
      @update:items-per-page="itemsPerPage = $event"
    >
      <!-- Size column formatting -->
      <template #item.size="{ item }">
        {{ formatBytes(item.size) }}
      </template>

      <!-- Date column formatting -->
      <template #item.modifiedAt="{ item }">
        {{ formatDate(item.modifiedAt) }}
      </template>

      <!-- Actions column -->
      <template #item.actions="{ item }">
        <v-btn
          icon="mdi-eye"
          size="small"
          variant="text"
          @click="emit('view', item)"
        />
        <v-btn
          icon="mdi-download"
          size="small"
          variant="text"
          @click="emit('download', item)"
        />
        <v-btn
          icon="mdi-delete"
          size="small"
          variant="text"
          color="error"
          @click="emit('delete', item)"
        />
      </template>

      <!-- Loading state -->
      <template #loading>
        <v-skeleton-loader type="table-row@5" />
      </template>

      <!-- No data state -->
      <template #no-data>
        <v-empty-state
          icon="mdi-file-document-outline"
          title="No documents found"
          text="Upload your first document to get started"
        />
      </template>
    </v-data-table>
  </v-card>
</template>
```

### 3. Form Validation Pattern

**Purpose**: Create forms with validation using Vuetify's built-in validation

```vue
<script setup lang="ts">
import { ref } from 'vue'

interface DocumentMetadata {
  title: string
  description: string
  category: string
  tags: string[]
}

interface Emits {
  (e: 'save', metadata: DocumentMetadata): void
  (e: 'cancel'): void
}

const emit = defineEmits<Emits>()

const form = ref()
const valid = ref(false)

const metadata = ref<DocumentMetadata>({
  title: '',
  description: '',
  category: '',
  tags: []
})

const categories = ['Financial', 'Legal', 'HR', 'Marketing', 'Technical']

const rules = {
  required: (v: string) => !!v || 'Field is required',
  minLength: (min: number) => (v: string) =>
    (v && v.length >= min) || `Minimum ${min} characters required`,
  maxLength: (max: number) => (v: string) =>
    (v && v.length <= max) || `Maximum ${max} characters allowed`
}

async function handleSubmit() {
  const { valid: isValid } = await form.value.validate()

  if (isValid) {
    emit('save', metadata.value)
  }
}

function handleReset() {
  form.value.reset()
}

function handleCancel() {
  emit('cancel')
}
</script>

<template>
  <v-form ref="form" v-model="valid" @submit.prevent="handleSubmit">
    <v-card>
      <v-card-title>Document Metadata</v-card-title>

      <v-card-text>
        <v-text-field
          v-model="metadata.title"
          label="Title"
          :rules="[rules.required, rules.maxLength(100)]"
          counter="100"
          required
        />

        <v-textarea
          v-model="metadata.description"
          label="Description"
          :rules="[rules.maxLength(500)]"
          counter="500"
          rows="3"
        />

        <v-select
          v-model="metadata.category"
          :items="categories"
          label="Category"
          :rules="[rules.required]"
          required
        />

        <v-combobox
          v-model="metadata.tags"
          label="Tags"
          multiple
          chips
          closable-chips
          hint="Press enter to add a tag"
          persistent-hint
        />
      </v-card-text>

      <v-card-actions>
        <v-spacer />
        <v-btn variant="text" @click="handleCancel">
          Cancel
        </v-btn>
        <v-btn variant="text" @click="handleReset">
          Reset
        </v-btn>
        <v-btn
          type="submit"
          color="primary"
          :disabled="!valid"
        >
          Save
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-form>
</template>
```

---

## Best Practices

### 1. Use Density Props for Compact UIs

**Do**:
```vue
<v-list density="compact">
  <v-list-item>Item 1</v-list-item>
  <v-list-item>Item 2</v-list-item>
</v-list>

<v-btn size="small">Small Button</v-btn>
<v-text-field density="compact" />
```

**Why**: Provides better space utilization and allows more content on screen

### 2. Use Variant Props for Visual Hierarchy

```vue
<!-- Primary actions -->
<v-btn color="primary" variant="elevated">Save</v-btn>

<!-- Secondary actions -->
<v-btn variant="outlined">Cancel</v-btn>

<!-- Tertiary actions -->
<v-btn variant="text">More Info</v-btn>
```

### 3. Leverage Vuetify's Grid System

**Do**:
```vue
<v-container>
  <v-row>
    <v-col cols="12" md="6" lg="4">
      <!-- Responsive: full width mobile, half on tablet, third on desktop -->
    </v-col>
  </v-row>
</v-container>
```

**Don't**:
```vue
<!-- Avoid custom CSS for layout when grid system can handle it -->
<div style="width: 33.33%; float: left;">
  Content
</div>
```

### 4. Use Composition for Reusable Logic

```typescript
// composables/useVuetifyTheme.ts
import { useTheme } from 'vuetify'
import { computed } from 'vue'

export function useVuetifyTheme() {
  const theme = useTheme()

  const isDark = computed(() => theme.global.current.value.dark)

  function toggleTheme() {
    theme.global.name.value = isDark.value ? 'light' : 'dark'
  }

  return {
    isDark,
    toggleTheme,
    theme
  }
}
```

### 5. Proper Icon Usage

**Do**: Use MDI icons with proper naming
```vue
<v-icon icon="mdi-account" />
<v-btn icon="mdi-delete" />
<v-list-item prepend-icon="mdi-folder" />
```

**Don't**: Mix icon libraries or use incorrect syntax
```vue
<!-- WRONG -->
<v-icon>account</v-icon>
<v-icon>fa-user</v-icon>
```

---

## Common Patterns for Document Manager

### 1. Folder Tree View Component

```vue
<script setup lang="ts">
import { ref } from 'vue'
import type { Folder } from '@/types/folder'

interface Props {
  folders: Folder[]
  loading?: boolean
}

interface Emits {
  (e: 'select', folder: Folder): void
  (e: 'create', parentId: string): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<Emits>()

const selected = ref<string[]>([])
const opened = ref<string[]>([])

function transformToTreeItems(folders: Folder[]) {
  return folders.map(folder => ({
    id: folder.id,
    title: folder.name,
    value: folder.id,
    children: folder.children ? transformToTreeItems(folder.children) : []
  }))
}

const items = computed(() => transformToTreeItems(props.folders))
</script>

<template>
  <v-card>
    <v-card-title>
      <v-row align="center">
        <v-col>Folders</v-col>
        <v-col cols="auto">
          <v-btn
            icon="mdi-folder-plus"
            size="small"
            variant="text"
            @click="emit('create', '')"
          />
        </v-col>
      </v-row>
    </v-card-title>

    <v-card-text>
      <v-treeview
        v-model:selected="selected"
        v-model:opened="opened"
        :items="items"
        :loading="loading"
        item-value="id"
        activatable
        open-on-click
        @update:selected="emit('select', $event[0])"
      >
        <template #prepend="{ item }">
          <v-icon
            :icon="opened.includes(item.id) ? 'mdi-folder-open' : 'mdi-folder'"
          />
        </template>

        <template #append="{ item }">
          <v-btn
            icon="mdi-folder-plus"
            size="x-small"
            variant="text"
            @click.stop="emit('create', item.id)"
          />
        </template>
      </v-treeview>
    </v-card-text>
  </v-card>
</template>
```

### 2. File Upload Dialog

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

interface Emits {
  (e: 'upload', file: File): void
  (e: 'close'): void
}

const emit = defineEmits<Emits>()

const dialog = ref(false)
const file = ref<File | null>(null)
const dragOver = ref(false)

const fileSize = computed(() => {
  if (!file.value) return ''
  const bytes = file.value.size
  const mb = (bytes / (1024 * 1024)).toFixed(2)
  return `${mb} MB`
})

function handleFileSelect(files: File[]) {
  if (files.length > 0) {
    file.value = files[0]
  }
}

function handleDrop(event: DragEvent) {
  dragOver.value = false
  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    file.value = files[0]
  }
}

function handleUpload() {
  if (file.value) {
    emit('upload', file.value)
    dialog.value = false
    file.value = null
  }
}

function handleCancel() {
  file.value = null
  dialog.value = false
  emit('close')
}

defineExpose({ open: () => { dialog.value = true } })
</script>

<template>
  <v-dialog v-model="dialog" max-width="600">
    <template #activator="{ props }">
      <v-btn color="primary" v-bind="props">
        <v-icon start icon="mdi-upload" />
        Upload Document
      </v-btn>
    </template>

    <v-card>
      <v-card-title>Upload Document</v-card-title>

      <v-card-text>
        <v-file-input
          v-model="file"
          label="Select file"
          prepend-icon="mdi-paperclip"
          show-size
          @update:model-value="handleFileSelect"
        />

        <v-divider class="my-4" />

        <div
          class="drop-zone"
          :class="{ 'drag-over': dragOver }"
          @dragover.prevent="dragOver = true"
          @dragleave="dragOver = false"
          @drop.prevent="handleDrop"
        >
          <v-icon
            size="64"
            :icon="file ? 'mdi-file-check' : 'mdi-cloud-upload'"
            :color="file ? 'success' : 'grey'"
          />
          <p v-if="!file" class="text-center mt-4">
            Drag and drop file here
          </p>
          <div v-else class="text-center mt-4">
            <p class="font-weight-bold">{{ file.name }}</p>
            <p class="text-caption">{{ fileSize }}</p>
          </div>
        </div>
      </v-card-text>

      <v-card-actions>
        <v-spacer />
        <v-btn variant="text" @click="handleCancel">
          Cancel
        </v-btn>
        <v-btn
          color="primary"
          :disabled="!file"
          @click="handleUpload"
        >
          Upload
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.drop-zone {
  border: 2px dashed #ccc;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s;
}

.drop-zone.drag-over {
  border-color: rgb(var(--v-theme-primary));
  background-color: rgba(var(--v-theme-primary), 0.1);
}
</style>
```

### 3. Document Preview Dialog

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Document } from '@/types/document'

interface Props {
  document: Document | null
}

const props = defineProps<Props>()

const dialog = ref(false)

const isPdf = computed(() =>
  props.document?.contentType === 'application/pdf'
)

const isImage = computed(() =>
  props.document?.contentType?.startsWith('image/')
)

const isText = computed(() =>
  props.document?.contentType?.startsWith('text/')
)

function close() {
  dialog.value = false
}

defineExpose({
  open: () => { dialog.value = true },
  close
})
</script>

<template>
  <v-dialog v-model="dialog" max-width="900" scrollable>
    <v-card v-if="document">
      <v-card-title>
        <v-row align="center">
          <v-col>{{ document.name }}</v-col>
          <v-col cols="auto">
            <v-btn
              icon="mdi-download"
              variant="text"
              :href="document.blobUrl"
              download
            />
            <v-btn
              icon="mdi-close"
              variant="text"
              @click="close"
            />
          </v-col>
        </v-row>
      </v-card-title>

      <v-divider />

      <v-card-text style="height: 600px;">
        <!-- PDF Preview -->
        <iframe
          v-if="isPdf"
          :src="document.blobUrl"
          style="width: 100%; height: 100%; border: none;"
        />

        <!-- Image Preview -->
        <v-img
          v-else-if="isImage"
          :src="document.blobUrl"
          :alt="document.name"
          contain
        />

        <!-- Text Preview -->
        <pre v-else-if="isText" class="text-pre-wrap">
          <!-- Load text content here -->
        </pre>

        <!-- Unsupported -->
        <v-empty-state
          v-else
          icon="mdi-file-question"
          title="Preview not available"
          :text="`Preview is not available for ${document.contentType} files`"
        >
          <template #actions>
            <v-btn
              color="primary"
              :href="document.blobUrl"
              download
            >
              Download File
            </v-btn>
          </template>
        </v-empty-state>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>
```

---

## Theme Customization

### 1. Creating Custom Theme

```typescript
// plugins/vuetify.ts
import { createVuetify } from 'vuetify'
import { aliases, mdi } from 'vuetify/iconsets/mdi'
import 'vuetify/styles'

export default createVuetify({
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
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
        colors: {
          primary: '#2196F3',
          secondary: '#424242',
          accent: '#FF4081',
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
          background: '#121212',
          surface: '#212121'
        }
      }
    }
  },
  icons: {
    defaultSet: 'mdi',
    aliases,
    sets: {
      mdi
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
    }
  }
})
```

### 2. Using Theme in Components

```vue
<script setup lang="ts">
import { useTheme } from 'vuetify'
import { computed } from 'vue'

const theme = useTheme()

const primaryColor = computed(() => theme.current.value.colors.primary)
const isDark = computed(() => theme.global.current.value.dark)

function toggleTheme() {
  theme.global.name.value = isDark.value ? 'light' : 'dark'
}
</script>

<template>
  <v-app>
    <v-app-bar :color="primaryColor">
      <v-toolbar-title>Document Manager</v-toolbar-title>
      <v-spacer />
      <v-btn
        :icon="isDark ? 'mdi-weather-sunny' : 'mdi-weather-night'"
        @click="toggleTheme"
      />
    </v-app-bar>
  </v-app>
</template>
```

---

## Responsive Design

### 1. Responsive Grid

```vue
<template>
  <v-container>
    <v-row>
      <!-- Full width on mobile, half on tablet, third on desktop -->
      <v-col
        v-for="doc in documents"
        :key="doc.id"
        cols="12"
        sm="6"
        md="4"
        lg="3"
      >
        <v-card>
          <v-card-title>{{ doc.name }}</v-card-title>
          <v-card-text>{{ doc.description }}</v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>
```

### 2. Display Utilities

```vue
<template>
  <!-- Hide on mobile, show on desktop -->
  <v-btn class="d-none d-md-flex">Desktop Only</v-btn>

  <!-- Show on mobile, hide on desktop -->
  <v-btn class="d-md-none">Mobile Only</v-btn>

  <!-- Responsive navigation -->
  <v-app-bar>
    <!-- Hamburger menu on mobile -->
    <v-app-bar-nav-icon class="d-md-none" />

    <!-- Full menu on desktop -->
    <div class="d-none d-md-flex">
      <v-btn>Documents</v-btn>
      <v-btn>Folders</v-btn>
      <v-btn>Search</v-btn>
    </div>
  </v-app-bar>
</template>
```

---

## Performance Optimization

### 1. Virtual Scrolling for Large Lists

```vue
<script setup lang="ts">
import { ref } from 'vue'

const items = ref(Array.from({ length: 10000 }, (_, i) => ({
  id: i,
  title: `Item ${i}`,
  subtitle: `Description for item ${i}`
})))
</script>

<template>
  <v-virtual-scroll
    :items="items"
    height="400"
    item-height="64"
  >
    <template #default="{ item }">
      <v-list-item
        :key="item.id"
        :title="item.title"
        :subtitle="item.subtitle"
      />
    </template>
  </v-virtual-scroll>
</template>
```

### 2. Lazy Loading Images

```vue
<template>
  <v-img
    :src="document.thumbnailUrl"
    :lazy-src="placeholderUrl"
    aspect-ratio="1"
    cover
  >
    <template #placeholder>
      <v-row class="fill-height ma-0" align="center" justify="center">
        <v-progress-circular indeterminate color="grey-lighten-5" />
      </v-row>
    </template>
  </v-img>
</template>
```

---

## Accessibility

### 1. Proper ARIA Labels

```vue
<template>
  <v-btn
    icon="mdi-delete"
    aria-label="Delete document"
    @click="deleteDocument"
  />

  <v-text-field
    label="Search"
    aria-label="Search documents"
    aria-describedby="search-hint"
  />
  <span id="search-hint" class="text-caption">
    Enter keywords to search documents
  </span>
</template>
```

### 2. Keyboard Navigation

```vue
<template>
  <v-list>
    <v-list-item
      v-for="item in items"
      :key="item.id"
      tabindex="0"
      @click="selectItem(item)"
      @keydown.enter="selectItem(item)"
      @keydown.space.prevent="selectItem(item)"
    >
      {{ item.name }}
    </v-list-item>
  </v-list>
</template>
```

---

## Testing

### Unit Test Example (Vitest)

```typescript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import DocumentList from '@/components/DocumentList.vue'

describe('DocumentList', () => {
  const vuetify = createVuetify({
    components,
    directives
  })

  it('renders v-data-table with documents', () => {
    const documents = [
      { id: '1', name: 'Doc 1', size: 1024, modifiedAt: '2025-01-01' },
      { id: '2', name: 'Doc 2', size: 2048, modifiedAt: '2025-01-02' }
    ]

    const wrapper = mount(DocumentList, {
      props: { documents },
      global: {
        plugins: [vuetify]
      }
    })

    expect(wrapper.findComponent({ name: 'VDataTable' }).exists()).toBe(true)
    expect(wrapper.text()).toContain('Doc 1')
    expect(wrapper.text()).toContain('Doc 2')
  })

  it('emits view event when view button clicked', async () => {
    const documents = [
      { id: '1', name: 'Doc 1', size: 1024, modifiedAt: '2025-01-01' }
    ]

    const wrapper = mount(DocumentList, {
      props: { documents },
      global: {
        plugins: [vuetify]
      }
    })

    await wrapper.find('[data-test="view-btn"]').trigger('click')

    expect(wrapper.emitted('view')).toBeTruthy()
    expect(wrapper.emitted('view')?.[0]).toEqual([documents[0]])
  })
})
```

---

## Common Pitfalls

### 1. Not Using v-model Correctly

**Don't**:
```vue
<v-text-field :value="text" @input="text = $event" />
```

**Do**:
```vue
<v-text-field v-model="text" />
```

### 2. Forgetting to Import Components

**Don't**:
```typescript
// Using components without proper setup
import { VBtn } from 'vuetify/components'
```

**Do**:
```typescript
// Vuetify 3 auto-imports components via plugin
// Just use them in template
```

### 3. Mixing v2 and v3 Syntax

**v2 (Don't use)**:
```vue
<v-btn @click="handler">Click</v-btn>
<v-icon>mdi-home</v-icon>
```

**v3 (Correct)**:
```vue
<v-btn @click="handler">Click</v-btn>
<v-icon icon="mdi-home" />
```

### 4. Not Using Proper Spacing

**Don't**:
```vue
<div style="margin: 16px;">Content</div>
```

**Do**:
```vue
<div class="ma-4">Content</div>
<!-- or -->
<v-container>
  <v-row>
    <v-col>Content</v-col>
  </v-row>
</v-container>
```

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://vuetifyjs.com
- **API Reference**: https://vuetifyjs.com/en/api/
- **Component Library**: https://vuetifyjs.com/en/components/all/
- **Material Design**: https://m3.material.io

### Learning Resources
- **Vuetify University**: https://vuetify.dev/en/getting-started/
- **YouTube Channel**: https://www.youtube.com/vuetify
- **Examples**: https://github.com/vuetifyjs/vuetify/tree/master/packages/docs/src/examples

### Community
- **Discord**: https://community.vuetifyjs.com
- **GitHub**: https://github.com/vuetifyjs/vuetify
- **Stack Overflow**: Tag `vuetify.js`

---

## Quick Reference

### Common Components

```vue
<!-- Buttons -->
<v-btn color="primary">Button</v-btn>
<v-btn icon="mdi-heart" />
<v-btn variant="outlined">Outlined</v-btn>
<v-btn variant="text">Text</v-btn>

<!-- Cards -->
<v-card>
  <v-card-title>Title</v-card-title>
  <v-card-text>Content</v-card-text>
  <v-card-actions>
    <v-btn>Action</v-btn>
  </v-card-actions>
</v-card>

<!-- Forms -->
<v-text-field label="Name" />
<v-textarea label="Description" />
<v-select :items="items" label="Category" />
<v-checkbox label="Agree" />
<v-switch label="Enable" />

<!-- Lists -->
<v-list>
  <v-list-item title="Item 1" />
  <v-list-item title="Item 2" />
</v-list>

<!-- Dialogs -->
<v-dialog v-model="dialog">
  <v-card>
    <v-card-title>Dialog</v-card-title>
  </v-card>
</v-dialog>

<!-- Data Tables -->
<v-data-table
  :headers="headers"
  :items="items"
  :search="search"
/>
```

### Spacing Utilities

| Class | Margin/Padding |
|-------|----------------|
| `ma-0` to `ma-16` | All sides margin |
| `pa-0` to `pa-16` | All sides padding |
| `mt-4`, `mb-4` | Top, bottom |
| `ml-4`, `mr-4` | Left, right |
| `mx-4`, `my-4` | Horizontal, vertical |

### Display Utilities

| Class | Description |
|-------|-------------|
| `d-none` | Hide element |
| `d-flex` | Flex display |
| `d-block` | Block display |
| `d-sm-flex` | Flex on small+ |
| `d-md-none` | Hide on medium+ |

---

**For this project**: Use Vuetify 3 for all UI components. Follow Material Design 3 guidelines. Create consistent, accessible, and responsive interfaces using Vuetify's component library and grid system.

**Last Updated**: 2025-09-30
