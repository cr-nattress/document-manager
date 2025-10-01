# Architecture & Project Structure Guidelines

**Area**: Project Organization, File Structure, Code Organization
**Related**: [MASTER](./MASTER.md), [Components](./03-COMPONENTS.md), [State](./04-STATE.md)
**Last Updated**: 2025-09-30

---

## File Size Limits

These limits ensure maintainability and code review efficiency:

| File Type | Maximum Lines | Refactor Threshold |
|-----------|--------------|-------------------|
| Vue Components | 200 lines | 180 lines |
| Composables | 100 lines | 90 lines |
| Service Files | 150 lines | 135 lines |
| Store Modules | 150 lines | 135 lines |
| Utility Functions | 50 lines per function | 45 lines |
| Security Validators | 100 lines | 90 lines |
| Type Definition Files | No strict limit | Group by domain |

**Enforcement**: If a file exceeds its limit, **refactor immediately before adding new features**.

### Refactoring Strategies

**Large Component** (> 200 lines):
- Extract child components
- Move logic to composables
- Create feature-specific utilities

**Large Composable** (> 100 lines):
- Split by concern (data, UI, validation)
- Extract helper functions to utilities
- Create specialized composables

**Large Service** (> 150 lines):
- Split by resource type (users, documents, etc.)
- Extract common logic to base service
- Create utility functions

---

## Project Structure

```
src/
├── components/
│   ├── common/              # Reusable UI components (<200 lines each)
│   │   ├── EmptyState.vue
│   │   ├── LoadingSpinner.vue
│   │   └── ErrorMessage.vue
│   ├── features/            # Feature-specific components
│   │   ├── documents/
│   │   │   ├── DocumentList.vue
│   │   │   ├── DocumentCard.vue
│   │   │   └── UploadDialog.vue
│   │   └── folders/
│   │       ├── FolderTree.vue
│   │       └── FolderNode.vue
│   └── layouts/             # Layout components
│       ├── AppLayout.vue
│       ├── AppBar.vue
│       └── NavigationDrawer.vue
│
├── composables/             # Composition functions (<100 lines each)
│   ├── useSecureFileUpload.ts
│   ├── useRateLimiter.ts
│   ├── useSecurityMonitoring.ts
│   └── useInactivityTimer.ts
│
├── services/                # External service integrations (<150 lines each)
│   ├── api/
│   │   ├── baseApiClient.ts
│   │   ├── documentApi.ts
│   │   ├── folderApi.ts
│   │   └── authApi.ts
│   └── security/
│       ├── authService.ts
│       ├── encryptionService.ts
│       └── errorHandler.ts
│
├── stores/                  # Pinia state stores (<150 lines each)
│   ├── authStore.ts
│   ├── documentStore.ts
│   ├── folderStore.ts
│   ├── searchStore.ts
│   └── uiStore.ts
│
├── guards/                  # Route guards & permissions
│   ├── authGuard.ts
│   ├── roleGuard.ts
│   └── securityGuard.ts
│
├── utils/                   # Pure utility functions (<50 lines per fn)
│   ├── validators/
│   │   ├── sanitizer.ts
│   │   ├── schemas.ts
│   │   └── fileValidator.ts
│   ├── formatters/
│   │   ├── dateFormatter.ts
│   │   ├── byteFormatter.ts
│   │   └── numberFormatter.ts
│   └── security/
│       ├── urlSecurity.ts
│       ├── cspHelper.ts
│       └── tokenManager.ts
│
├── types/                   # TypeScript type definitions
│   ├── models/              # Domain models
│   │   ├── document.ts
│   │   ├── folder.ts
│   │   └── user.ts
│   ├── api/                 # API types
│   │   ├── requests.ts
│   │   └── responses.ts
│   └── security/            # Security-related types
│       ├── auth.ts
│       └── validation.ts
│
├── constants/               # Application constants
│   ├── app.ts               # App-wide constants
│   ├── routes.ts            # Route names/paths
│   └── security/
│       ├── csp.ts           # CSP directives
│       └── validation.ts    # Validation rules
│
├── assets/                  # Static assets
│   ├── styles/
│   │   ├── main.css
│   │   └── variables.css
│   └── images/
│
├── router/                  # Vue Router configuration
│   ├── index.ts
│   └── routes.ts
│
├── views/                   # Page-level components
│   ├── DashboardView.vue
│   ├── BrowseView.vue
│   └── SearchView.vue
│
├── App.vue                  # Root component
└── main.ts                  # Application entry point
```

---

## Module Organization Principles

### 1. Single Responsibility Principle
Each file should have **one clear purpose**:

**Good**:
```typescript
// services/api/documentApi.ts - Only document API calls
export class DocumentApi {
  async getDocuments() { }
  async getDocument(id: string) { }
  async createDocument(data: CreateDocumentRequest) { }
}

// services/api/folderApi.ts - Only folder API calls
export class FolderApi {
  async getFolders() { }
  async getFolder(id: string) { }
}
```

**Bad**:
```typescript
// services/api/allApis.ts - Too many responsibilities
export class AllApis {
  async getDocuments() { }
  async getFolders() { }
  async getUsers() { }
  async uploadFile() { }
  async sendEmail() { }
  // ... 500 more lines
}
```

### 2. Feature-Based Organization

Group related files by feature, not by type:

**Good**:
```
features/
├── documents/
│   ├── DocumentList.vue
│   ├── DocumentCard.vue
│   ├── UploadDialog.vue
│   ├── useDocuments.ts
│   └── documentTypes.ts
└── folders/
    ├── FolderTree.vue
    ├── FolderNode.vue
    ├── useFolders.ts
    └── folderTypes.ts
```

**Acceptable for small shared components**:
```
common/
├── EmptyState.vue
├── LoadingSpinner.vue
└── ErrorMessage.vue
```

### 3. Dependency Direction

Dependencies should flow in one direction:

```
Views (pages)
  ↓ uses
Components
  ↓ uses
Composables
  ↓ uses
Services / Stores
  ↓ uses
Utils / Types
```

**Never**:
- Utils should not import from services
- Services should not import from components
- Composables should not import from views

---

## Naming Conventions

### Files
- **Components**: PascalCase (e.g., `DocumentList.vue`)
- **Composables**: camelCase with `use` prefix (e.g., `useDocuments.ts`)
- **Services**: camelCase with descriptive suffix (e.g., `documentApi.ts`)
- **Stores**: camelCase with `Store` suffix (e.g., `documentStore.ts`)
- **Types**: camelCase (e.g., `document.ts`)
- **Utils**: camelCase (e.g., `sanitizer.ts`)

### Exports
- **Components**: Named export matching filename
- **Composables**: Named export with `use` prefix
- **Services**: Class or object export
- **Stores**: Named export with `use` prefix
- **Types**: Named exports (interfaces, types)

```typescript
// Good examples
export function useDocuments() { }          // composables/useDocuments.ts
export class DocumentApi { }                 // services/api/documentApi.ts
export const useDocumentStore = defineStore() // stores/documentStore.ts
export interface Document { }                // types/models/document.ts
```

---

## Component Size Management

### When Component Exceeds 200 Lines

**Strategy 1: Extract Child Components**
```vue
<!-- Before: DocumentForm.vue (250 lines) -->
<template>
  <form>
    <!-- 100 lines of metadata fields -->
    <!-- 80 lines of tag input -->
    <!-- 70 lines of file upload -->
  </form>
</template>

<!-- After: DocumentForm.vue (80 lines) -->
<template>
  <form>
    <DocumentMetadataFields />
    <DocumentTagInput />
    <DocumentFileUpload />
  </form>
</template>

<!-- + MetadataFields.vue (100 lines) -->
<!-- + TagInput.vue (80 lines) -->
<!-- + FileUpload.vue (70 lines) -->
```

**Strategy 2: Extract Logic to Composables**
```vue
<!-- Before: DocumentList.vue (220 lines) -->
<script setup lang="ts">
// 50 lines of data fetching logic
// 40 lines of filtering logic
// 30 lines of sorting logic
// 40 lines of pagination logic
// 60 lines of template
</script>

<!-- After: DocumentList.vue (90 lines) -->
<script setup lang="ts">
import { useDocumentData } from '@/composables/useDocumentData'
import { useDocumentFilters } from '@/composables/useDocumentFilters'
import { usePagination } from '@/composables/usePagination'

const { documents, loading } = useDocumentData()
const { filteredDocuments, applyFilter } = useDocumentFilters(documents)
const { paginatedItems, page, pageSize } = usePagination(filteredDocuments)
</script>
```

---

## Composable Size Management

### When Composable Exceeds 100 Lines

**Strategy 1: Split by Concern**
```typescript
// Before: useDocuments.ts (150 lines)
export function useDocuments() {
  // 40 lines data fetching
  // 30 lines filtering
  // 30 lines sorting
  // 20 lines pagination
  // 30 lines UI state
}

// After: Split into focused composables
// useDocumentData.ts (40 lines) - data fetching only
// useDocumentFilters.ts (30 lines) - filtering only
// useDocumentSort.ts (30 lines) - sorting only
// usePagination.ts (20 lines) - pagination only
// useDocumentUI.ts (30 lines) - UI state only
```

**Strategy 2: Extract Utilities**
```typescript
// Before: useFileUpload.ts (120 lines)
export function useFileUpload() {
  // 60 lines of validation logic
  // 40 lines of upload logic
  // 20 lines of progress tracking
}

// After:
// useFileUpload.ts (50 lines) - upload and progress only
// utils/validators/fileValidator.ts (60 lines) - validation logic
```

---

## Service Size Management

### When Service Exceeds 150 Lines

**Strategy: Split by Resource**
```typescript
// Before: apiService.ts (300 lines)
export class ApiService {
  // 100 lines document methods
  // 80 lines folder methods
  // 70 lines user methods
  // 50 lines auth methods
}

// After: Separate services
// services/api/documentApi.ts (100 lines)
// services/api/folderApi.ts (80 lines)
// services/api/userApi.ts (70 lines)
// services/api/authApi.ts (50 lines)
```

---

## Import Organization

Group and order imports consistently:

```typescript
// 1. Vue core
import { ref, computed, watch } from 'vue'

// 2. Third-party libraries
import { z } from 'zod'
import DOMPurify from 'dompurify'

// 3. Internal stores
import { useDocumentStore } from '@/stores/documentStore'
import { useAuthStore } from '@/stores/authStore'

// 4. Internal composables
import { useSecureFileUpload } from '@/composables/useSecureFileUpload'

// 5. Internal services
import { documentApi } from '@/services/api/documentApi'

// 6. Internal utilities
import { InputSanitizer } from '@/utils/validators/sanitizer'

// 7. Types
import type { Document } from '@/types/models/document'
import type { UploadOptions } from '@/types/api/requests'

// 8. Constants
import { MAX_FILE_SIZE } from '@/constants/app'
```

---

## Code Organization Within Files

### Component Structure (Vue SFC)
```vue
<script setup lang="ts">
// 1. Imports (organized as above)
import { ref, computed } from 'vue'

// 2. Props & Emits
interface Props {
  items: Item[]
}
interface Emits {
  (e: 'select', item: Item): void
}
const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 3. Composables & Stores
const store = useDocumentStore()
const { validate } = useValidation()

// 4. Reactive State
const selected = ref<Item | null>(null)
const loading = ref(false)

// 5. Computed Properties
const sortedItems = computed(() => [...props.items].sort())

// 6. Methods/Functions
function handleSelect(item: Item) {
  selected.value = item
  emit('select', item)
}

// 7. Lifecycle Hooks
onMounted(() => {
  // initialization
})

// 8. Watchers
watch(() => props.items, () => {
  // react to changes
})
</script>

<template>
  <!-- Template here -->
</template>

<style scoped>
/* Scoped styles here */
</style>
```

### TypeScript File Structure
```typescript
// 1. Imports
import { ref, computed } from 'vue'
import type { Document } from '@/types/models/document'

// 2. Type Definitions (if any)
interface ComposableOptions {
  autoFetch?: boolean
}

// 3. Constants (private to file)
const DEFAULT_PAGE_SIZE = 20

// 4. Main Export
export function useDocuments(options: ComposableOptions = {}) {
  // Implementation
}

// 5. Helper Functions (private)
function helperFunction() {
  // Helper logic
}

// 6. Additional Exports (if needed)
export type { ComposableOptions }
```

---

## Circular Dependency Prevention

### Common Causes

**Avoid**:
```typescript
// composables/useA.ts
import { useB } from './useB'

// composables/useB.ts
import { useA } from './useA' // CIRCULAR!
```

**Solution**: Extract shared logic
```typescript
// composables/useShared.ts
export function sharedLogic() { }

// composables/useA.ts
import { sharedLogic } from './useShared'

// composables/useB.ts
import { sharedLogic } from './useShared'
```

---

## Checklist for New Files

Before creating a new file:

- [ ] Does it have a single, clear responsibility?
- [ ] Is the name descriptive and following conventions?
- [ ] Will it stay under the size limit?
- [ ] Is it in the correct directory for its type?
- [ ] Does it avoid circular dependencies?
- [ ] Are imports organized correctly?
- [ ] Is the internal structure consistent?

---

## Related Guidelines

- **For component patterns**: See [Components](./03-COMPONENTS.md)
- **For state organization**: See [State](./04-STATE.md)
- **For type organization**: See [TypeScript](./07-TYPESCRIPT.md)
- **For security structure**: See [Security](./02-SECURITY.md)

---

**Remember**: Good architecture prevents bugs and security issues before they happen. Maintain these standards rigorously.
