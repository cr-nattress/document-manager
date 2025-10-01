# TypeScript Patterns

**Area**: Type Safety, Type Definitions, Interfaces, Utility Types
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [Architecture](./01-ARCHITECTURE.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers TypeScript patterns with a focus on security-focused types, type safety, and maintainability.

---

## TypeScript Configuration

### Strict Mode Required

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "moduleResolution": "bundler",

    // Strict Type Checking
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,

    // Additional Checks
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,

    // Module Resolution
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "isolatedModules": true,

    // Other
    "skipLibCheck": true,
    "allowJs": false
  }
}
```

---

## Security-Focused Types

### Branded Types for Sensitive Data

```typescript
// types/security/auth.ts

// Branded type to prevent mixing regular strings with tokens
type Brand<K, T> = K & { __brand: T }

export type SensitiveToken = Brand<string, 'SensitiveToken'>
export type UserId = Brand<string, 'UserId'>
export type Email = Brand<string, 'Email'>
export type HashedPassword = Brand<string, 'HashedPassword'>

// Type guards to create branded types
export function createSensitiveToken(value: string): SensitiveToken {
  if (!value || value.length < 32) {
    throw new Error('Invalid token')
  }
  return value as SensitiveToken
}

export function createUserId(value: string): UserId {
  if (!/^[a-f0-9-]{36}$/.test(value)) {
    throw new Error('Invalid user ID format')
  }
  return value as UserId
}

export function createEmail(value: string): Email {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
    throw new Error('Invalid email format')
  }
  return value.toLowerCase() as Email
}

// Usage
const token = createSensitiveToken('abc123...') // SensitiveToken
const userId = createUserId('550e8400-e29b-41d4-a716-446655440000') // UserId

// ❌ This won't compile - prevents mixing types
function authenticate(token: SensitiveToken) { }
const regularString = 'not-a-token'
authenticate(regularString) // TypeScript error
```

### Readonly Types for Immutable Data

```typescript
// types/models/document.ts

export interface Document {
  readonly id: string
  readonly uploadedAt: string
  readonly uploadedBy: string
  name: string
  folderId: string
  size: number
  contentType: string
  tags: string[]
  metadata: Record<string, string>
}

// Deep readonly
export type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? DeepReadonly<T[P]>
    : T[P]
}

export type ImmutableDocument = DeepReadonly<Document>

// Usage
const doc: ImmutableDocument = {
  id: '123',
  uploadedAt: '2025-09-30T12:00:00Z',
  uploadedBy: 'user-1',
  name: 'Report.pdf',
  folderId: 'folder-1',
  size: 1024,
  contentType: 'application/pdf',
  tags: ['report', 'finance'],
  metadata: { year: '2025' }
}

// ❌ All of these will cause TypeScript errors
doc.id = '456'
doc.name = 'New Name'
doc.tags.push('new-tag')
doc.metadata.year = '2026'
```

---

## Domain Model Types

### Document Types

```typescript
// types/models/document.ts

export interface Document {
  id: string
  name: string
  folderId: string
  size: number
  contentType: string
  uploadedAt: string
  uploadedBy: string
  modifiedAt?: string
  modifiedBy?: string
  tags: string[]
  metadata: Record<string, string>
  version: number
}

export interface CreateDocumentRequest {
  name: string
  folderId: string
  file: File
  tags?: string[]
  metadata?: Record<string, string>
}

export interface UpdateDocumentRequest {
  name?: string
  folderId?: string
  tags?: string[]
  metadata?: Record<string, string>
}

export interface DocumentFilter {
  folderId?: string
  tags?: string[]
  contentType?: string
  uploadedAfter?: string
  uploadedBefore?: string
  searchQuery?: string
}

export interface DocumentSort {
  field: 'name' | 'uploadedAt' | 'size'
  order: 'asc' | 'desc'
}
```

### Folder Types

```typescript
// types/models/folder.ts

export interface Folder {
  id: string
  name: string
  path: string
  parentId: string | null
  createdAt: string
  createdBy: string
  children?: Folder[]
  documentCount?: number
}

export interface CreateFolderRequest {
  name: string
  parentId: string | null
}

export interface UpdateFolderRequest {
  name?: string
  parentId?: string | null
}

export interface FolderTree extends Folder {
  children: FolderTree[]
  level: number
  expanded: boolean
}
```

### User Types

```typescript
// types/models/user.ts

export type UserRole = 'admin' | 'editor' | 'viewer'

export interface User {
  id: string
  username: string
  email: string
  role: UserRole
  createdAt: string
  lastLogin?: string
}

// Public user info (safe to expose in UI)
export interface PublicUserInfo {
  id: string
  username: string
  role: UserRole
}

// Private user info (never expose in UI)
interface PrivateUserInfo {
  email: string
  passwordHash: string
  resetToken?: string
  mfaSecret?: string
}

// Helper type to ensure no private info leaks
export type SafeUser = Omit<User, keyof PrivateUserInfo>
```

---

## API Types

### Request/Response Types

```typescript
// types/api/requests.ts

export interface ApiRequest<T = unknown> {
  data: T
  headers?: Record<string, string>
  params?: Record<string, string | number>
}

export interface PaginatedRequest {
  page: number
  pageSize: number
  sort?: string
  order?: 'asc' | 'desc'
}

export interface SearchRequest extends PaginatedRequest {
  query: string
  filters?: Record<string, unknown>
}
```

```typescript
// types/api/responses.ts

export interface ApiResponse<T = unknown> {
  success: boolean
  data: T
  message?: string
  timestamp: string
}

export interface PaginatedResponse<T> {
  items: T[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
}

export interface ApiError {
  success: false
  error: {
    code: string
    message: string
    details?: Record<string, unknown>
  }
  timestamp: string
}
```

---

## Utility Types

### Common Utility Types

```typescript
// types/utils.ts

// Make specific properties required
export type RequireFields<T, K extends keyof T> = T & Required<Pick<T, K>>

// Make specific properties optional
export type OptionalFields<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>

// Extract properties by type
export type PropertiesOfType<T, U> = {
  [K in keyof T as T[K] extends U ? K : never]: T[K]
}

// Non-nullable version of type
export type NonNullableFields<T> = {
  [P in keyof T]: NonNullable<T[P]>
}

// Recursive Partial
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P]
}

// Usage examples
interface User {
  id: string
  name: string
  email?: string
  age?: number
}

type UserWithEmail = RequireFields<User, 'email'>
// { id: string; name: string; email: string; age?: number }

type UserUpdate = OptionalFields<User, 'id'>
// { id?: string; name?: string; email?: string; age?: number }

type UserStrings = PropertiesOfType<User, string>
// { id: string; name: string; email?: string }
```

---

## Type Guards

### Runtime Type Checking

```typescript
// utils/typeGuards.ts

export function isString(value: unknown): value is string {
  return typeof value === 'string'
}

export function isNumber(value: unknown): value is number {
  return typeof value === 'number' && !isNaN(value)
}

export function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

export function isArray<T>(value: unknown, itemGuard: (item: unknown) => item is T): value is T[] {
  return Array.isArray(value) && value.every(itemGuard)
}

export function isDefined<T>(value: T | undefined | null): value is T {
  return value !== undefined && value !== null
}

// Domain-specific type guards
export function isDocument(value: unknown): value is Document {
  if (!isObject(value)) return false

  return (
    isString(value.id) &&
    isString(value.name) &&
    isString(value.folderId) &&
    isNumber(value.size) &&
    isString(value.contentType) &&
    isString(value.uploadedAt) &&
    isString(value.uploadedBy) &&
    isArray(value.tags, isString)
  )
}

export function isFolder(value: unknown): value is Folder {
  if (!isObject(value)) return false

  return (
    isString(value.id) &&
    isString(value.name) &&
    isString(value.path) &&
    (value.parentId === null || isString(value.parentId)) &&
    isString(value.createdAt) &&
    isString(value.createdBy)
  )
}
```

### Usage in Components

```typescript
// composables/useDocuments.ts
import { ref } from 'vue'
import { isDocument } from '@/utils/typeGuards'
import type { Document } from '@/types/models/document'

export function useDocuments() {
  const documents = ref<Document[]>([])

  async function fetchDocuments() {
    const response = await fetch('/api/documents')
    const data = await response.json()

    // Validate response data
    if (!Array.isArray(data)) {
      throw new Error('Invalid response format')
    }

    // Filter out invalid documents
    documents.value = data.filter(isDocument)
  }

  return {
    documents,
    fetchDocuments
  }
}
```

---

## Generic Types

### Generic API Client

```typescript
// services/api/genericApiClient.ts

export class ApiClient<T> {
  constructor(private baseUrl: string) {}

  async get(id: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}/${id}`)
    return response.json()
  }

  async list(): Promise<T[]> {
    const response = await fetch(this.baseUrl)
    return response.json()
  }

  async create(data: Omit<T, 'id'>): Promise<T> {
    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
    return response.json()
  }

  async update(id: string, data: Partial<T>): Promise<T> {
    const response = await fetch(`${this.baseUrl}/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
    return response.json()
  }

  async delete(id: string): Promise<void> {
    await fetch(`${this.baseUrl}/${id}`, {
      method: 'DELETE'
    })
  }
}

// Usage
const documentClient = new ApiClient<Document>('/api/documents')
const folderClient = new ApiClient<Folder>('/api/folders')

const doc = await documentClient.get('123')
const folders = await folderClient.list()
```

### Generic Store Pattern

```typescript
// stores/createResourceStore.ts
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export function createResourceStore<T extends { id: string }>(
  name: string,
  apiClient: ApiClient<T>
) {
  return defineStore(name, () => {
    const items = ref<T[]>([])
    const selectedItem = ref<T | null>(null)
    const loading = ref(false)
    const error = ref<string | null>(null)

    const itemsById = computed(() => {
      return new Map(items.value.map(item => [item.id, item]))
    })

    async function fetchItems() {
      loading.value = true
      error.value = null

      try {
        items.value = await apiClient.list()
      } catch (err) {
        error.value = 'Failed to fetch items'
        console.error(err)
      } finally {
        loading.value = false
      }
    }

    async function createItem(data: Omit<T, 'id'>) {
      loading.value = true
      error.value = null

      try {
        const newItem = await apiClient.create(data)
        items.value.push(newItem)
        return newItem
      } catch (err) {
        error.value = 'Failed to create item'
        console.error(err)
        throw err
      } finally {
        loading.value = false
      }
    }

    return {
      items,
      selectedItem,
      loading,
      error,
      itemsById,
      fetchItems,
      createItem
    }
  })
}

// Usage
const useDocumentStore = createResourceStore('document', documentClient)
const useFolderStore = createResourceStore('folder', folderClient)
```

---

## Discriminated Unions

### Type-Safe State Machine

```typescript
// types/state.ts

export type AsyncState<T, E = Error> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: E }

// Usage with type narrowing
function handleState<T>(state: AsyncState<T>) {
  switch (state.status) {
    case 'idle':
      console.log('Not started')
      break

    case 'loading':
      console.log('Loading...')
      break

    case 'success':
      // TypeScript knows state.data exists here
      console.log('Data:', state.data)
      break

    case 'error':
      // TypeScript knows state.error exists here
      console.error('Error:', state.error)
      break
  }
}
```

### API Response Union Types

```typescript
// types/api/responses.ts

export type ApiResult<T> =
  | { success: true; data: T }
  | { success: false; error: ApiError }

// Usage
async function fetchDocument(id: string): Promise<ApiResult<Document>> {
  try {
    const response = await fetch(`/api/documents/${id}`)
    const data = await response.json()
    return { success: true, data }
  } catch (error) {
    return {
      success: false,
      error: {
        code: 'FETCH_ERROR',
        message: 'Failed to fetch document',
        details: { error }
      }
    }
  }
}

// Type-safe handling
const result = await fetchDocument('123')

if (result.success) {
  // TypeScript knows result.data exists
  console.log(result.data.name)
} else {
  // TypeScript knows result.error exists
  console.error(result.error.message)
}
```

---

## Type Inference

### Infer Types from Zod Schemas

```typescript
// utils/validators/schemas.ts
import { z } from 'zod'

export const documentSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(255),
  folderId: z.string().uuid(),
  size: z.number().positive(),
  contentType: z.string(),
  uploadedAt: z.string().datetime(),
  uploadedBy: z.string().uuid(),
  tags: z.array(z.string()).max(10),
  metadata: z.record(z.string(), z.string())
})

// Automatically infer TypeScript type from Zod schema
export type Document = z.infer<typeof documentSchema>

// No need to manually define the interface - it's inferred from the schema!
```

---

## Const Assertions

### Type-Safe Constants

```typescript
// constants/fileTypes.ts

export const FILE_TYPES = {
  PDF: 'application/pdf',
  WORD: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  EXCEL: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  TEXT: 'text/plain'
} as const

// Type is: {
//   readonly PDF: "application/pdf";
//   readonly WORD: "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
//   readonly EXCEL: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
//   readonly TEXT: "text/plain";
// }

export type FileType = typeof FILE_TYPES[keyof typeof FILE_TYPES]
// Type is: "application/pdf" | "application/vnd.openxmlformats-officedocument.wordprocessingml.document" | ...

// Usage
function isValidFileType(type: string): type is FileType {
  return Object.values(FILE_TYPES).includes(type as FileType)
}
```

---

## Type Organization

### Organizing Type Files

```
types/
├── models/              # Domain models
│   ├── document.ts
│   ├── folder.ts
│   └── user.ts
├── api/                 # API types
│   ├── requests.ts
│   └── responses.ts
├── security/            # Security types
│   ├── auth.ts
│   └── validation.ts
├── state.ts             # State types
├── utils.ts             # Utility types
└── index.ts             # Re-export all types
```

```typescript
// types/index.ts - Central export
export * from './models/document'
export * from './models/folder'
export * from './models/user'
export * from './api/requests'
export * from './api/responses'
export * from './security/auth'
export * from './state'
export * from './utils'
```

---

## TypeScript Best Practices Checklist

- [ ] Strict mode enabled in tsconfig.json
- [ ] No `any` types (use `unknown` if needed)
- [ ] Branded types for sensitive data
- [ ] Readonly for immutable data
- [ ] Type guards for runtime validation
- [ ] Discriminated unions for state machines
- [ ] Generic types for reusable code
- [ ] Infer types from Zod schemas
- [ ] Const assertions for constants
- [ ] Types organized by domain

---

## Related Guidelines

- **For security types**: See [Security](./02-SECURITY.md)
- **For validation schemas**: See [Validation](./06-VALIDATION.md)
- **For state types**: See [State](./04-STATE.md)
- **For API types**: See [API](./05-API.md)

---

**Remember**: TypeScript is your safety net. Use strict typing to catch errors at compile time, not runtime.
