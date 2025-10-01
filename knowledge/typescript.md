# TypeScript - Comprehensive Guide

**Technology**: TypeScript
**Category**: Programming Language
**Official Docs**: https://www.typescriptlang.org

---

## Overview

TypeScript is a typed superset of JavaScript that compiles to plain JavaScript. It adds optional static typing, classes, and interfaces to JavaScript, enabling better tooling and catching errors at compile-time.

### Key Features
- **Static Typing** - Type checking at compile time
- **Type Inference** - Automatic type detection
- **Interfaces & Types** - Define contracts
- **Generics** - Reusable type-safe code
- **Enums** - Named constants
- **Decorators** - Meta-programming support

---

## Design Patterns

### 1. Type-Safe API Client Pattern

```typescript
// types/api.ts
export interface ApiResponse<T> {
  data: T
  status: number
  message?: string
}

export interface Document {
  id: string
  name: string
  size: number
  uploadedAt: Date
  metadata: Record<string, unknown>
  tags: string[]
}

// services/apiClient.ts
import axios, { AxiosResponse } from 'axios'

class ApiClient {
  private baseURL: string

  constructor(baseURL: string) {
    this.baseURL = baseURL
  }

  async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    const response: AxiosResponse<T> = await axios.get(
      `${this.baseURL}${endpoint}`
    )

    return {
      data: response.data,
      status: response.status
    }
  }

  async post<T, D>(endpoint: string, data: D): Promise<ApiResponse<T>> {
    const response: AxiosResponse<T> = await axios.post(
      `${this.baseURL}${endpoint}`,
      data
    )

    return {
      data: response.data,
      status: response.status
    }
  }
}

// Usage
const client = new ApiClient('/api')
const response = await client.get<Document[]>('/documents')
// response.data is typed as Document[]
```

### 2. Repository Pattern with Generics

```typescript
// repositories/baseRepository.ts
export interface Repository<T> {
  getAll(): Promise<T[]>
  getById(id: string): Promise<T | null>
  create(item: Omit<T, 'id'>): Promise<T>
  update(id: string, item: Partial<T>): Promise<T>
  delete(id: string): Promise<void>
}

export class BaseRepository<T extends { id: string }> implements Repository<T> {
  constructor(private endpoint: string) {}

  async getAll(): Promise<T[]> {
    const response = await fetch(this.endpoint)
    return response.json()
  }

  async getById(id: string): Promise<T | null> {
    const response = await fetch(`${this.endpoint}/${id}`)
    if (!response.ok) return null
    return response.json()
  }

  async create(item: Omit<T, 'id'>): Promise<T> {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    })
    return response.json()
  }

  async update(id: string, item: Partial<T>): Promise<T> {
    const response = await fetch(`${this.endpoint}/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    })
    return response.json()
  }

  async delete(id: string): Promise<void> {
    await fetch(`${this.endpoint}/${id}`, { method: 'DELETE' })
  }
}

// Usage
interface Document {
  id: string
  name: string
  size: number
}

const documentRepo = new BaseRepository<Document>('/api/documents')
const docs = await documentRepo.getAll() // Typed as Document[]
```

### 3. Builder Pattern with Types

```typescript
// models/documentBuilder.ts
export interface DocumentMetadata {
  author?: string
  department?: string
  year?: number
  [key: string]: unknown
}

export interface Document {
  id: string
  name: string
  fileName: string
  folderId: string
  size: number
  contentType: string
  uploadedAt: Date
  metadata: DocumentMetadata
  tags: string[]
}

export class DocumentBuilder {
  private document: Partial<Document> = {}

  setId(id: string): this {
    this.document.id = id
    return this
  }

  setName(name: string): this {
    this.document.name = name
    return this
  }

  setFileName(fileName: string): this {
    this.document.fileName = fileName
    return this
  }

  setFolderId(folderId: string): this {
    this.document.folderId = folderId
    return this
  }

  setSize(size: number): this {
    this.document.size = size
    return this
  }

  setContentType(contentType: string): this {
    this.document.contentType = contentType
    return this
  }

  setMetadata(metadata: DocumentMetadata): this {
    this.document.metadata = metadata
    return this
  }

  addTag(tag: string): this {
    if (!this.document.tags) {
      this.document.tags = []
    }
    this.document.tags.push(tag)
    return this
  }

  build(): Document {
    // Validate all required fields are present
    if (!this.document.id || !this.document.name || !this.document.fileName) {
      throw new Error('Missing required fields')
    }

    return {
      id: this.document.id,
      name: this.document.name,
      fileName: this.document.fileName,
      folderId: this.document.folderId || 'root',
      size: this.document.size || 0,
      contentType: this.document.contentType || 'application/octet-stream',
      uploadedAt: new Date(),
      metadata: this.document.metadata || {},
      tags: this.document.tags || []
    }
  }
}

// Usage
const doc = new DocumentBuilder()
  .setId('doc-123')
  .setName('My Document')
  .setFileName('document.pdf')
  .setSize(1024)
  .addTag('important')
  .addTag('report')
  .build()
```

---

## Best Practices

### 1. Use Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true
  }
}
```

### 2. Prefer Interfaces over Type Aliases for Objects

**Do**:
```typescript
interface Document {
  id: string
  name: string
}
```

**Also OK** (for unions, intersections):
```typescript
type DocumentOrFolder = Document | Folder
type DocumentWithTimestamp = Document & { timestamp: Date }
```

### 3. Use Utility Types

```typescript
// Pick - Select specific properties
type DocumentPreview = Pick<Document, 'id' | 'name' | 'size'>

// Omit - Exclude specific properties
type CreateDocument = Omit<Document, 'id' | 'uploadedAt'>

// Partial - Make all properties optional
type UpdateDocument = Partial<Document>

// Required - Make all properties required
type CompleteDocument = Required<Document>

// Readonly - Make all properties readonly
type ImmutableDocument = Readonly<Document>

// Record - Create object type with key-value pairs
type DocumentMap = Record<string, Document>
```

### 4. Use Type Guards

```typescript
interface Document {
  type: 'document'
  id: string
  name: string
}

interface Folder {
  type: 'folder'
  id: string
  name: string
  children: (Document | Folder)[]
}

// Type guard function
function isDocument(item: Document | Folder): item is Document {
  return item.type === 'document'
}

function isFolder(item: Document | Folder): item is Folder {
  return item.type === 'folder'
}

// Usage
function process(item: Document | Folder) {
  if (isDocument(item)) {
    console.log('Processing document:', item.name)
    // TypeScript knows item is Document here
  } else {
    console.log('Processing folder:', item.name)
    console.log('Children count:', item.children.length)
    // TypeScript knows item is Folder here
  }
}
```

### 5. Use Discriminated Unions

```typescript
interface SuccessResponse {
  status: 'success'
  data: Document[]
}

interface ErrorResponse {
  status: 'error'
  error: string
  code: number
}

type ApiResponse = SuccessResponse | ErrorResponse

function handleResponse(response: ApiResponse) {
  // TypeScript can narrow the type based on status
  if (response.status === 'success') {
    console.log(response.data) // OK - data exists
  } else {
    console.log(response.error) // OK - error exists
    console.log(response.code) // OK - code exists
  }
}
```

### 6. Use `unknown` Instead of `any`

**Don't**:
```typescript
function processData(data: any) {
  return data.value // No type checking
}
```

**Do**:
```typescript
function processData(data: unknown) {
  // Must check type before use
  if (typeof data === 'object' && data !== null && 'value' in data) {
    return (data as { value: string }).value
  }
  throw new Error('Invalid data')
}
```

---

## Common Patterns for Document Manager

### 1. API Response Types

```typescript
// types/api.ts
export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  hasNext: boolean
}

export interface ErrorResponse {
  error: string
  message: string
  details?: Record<string, string[]>
}

// Usage
const response: PaginatedResponse<Document> = await api.get('/documents')
```

### 2. Form Validation Types

```typescript
// types/validation.ts
export type ValidationRule<T> = (value: T) => string | null

export interface ValidationRules<T> {
  [K in keyof T]?: ValidationRule<T[K]>[]
}

export interface ValidationErrors<T> {
  [K in keyof T]?: string
}

// Validator class
export class Validator<T> {
  constructor(private rules: ValidationRules<T>) {}

  validate(data: T): ValidationErrors<T> {
    const errors: ValidationErrors<T> = {}

    for (const field in this.rules) {
      const fieldRules = this.rules[field]
      if (!fieldRules) continue

      for (const rule of fieldRules) {
        const error = rule(data[field])
        if (error) {
          errors[field] = error
          break // Stop at first error for this field
        }
      }
    }

    return errors
  }

  isValid(data: T): boolean {
    return Object.keys(this.validate(data)).length === 0
  }
}

// Usage
interface DocumentForm {
  name: string
  folderId: string
  tags: string[]
}

const required = <T>(message: string): ValidationRule<T> =>
  (value: T) => (value ? null : message)

const minLength = (min: number): ValidationRule<string> =>
  (value: string) => (value.length >= min ? null : `Minimum length is ${min}`)

const validator = new Validator<DocumentForm>({
  name: [
    required('Name is required'),
    minLength(3)
  ],
  folderId: [
    required('Folder is required')
  ]
})

const form: DocumentForm = {
  name: 'My Document',
  folderId: 'folder-123',
  tags: []
}

const errors = validator.validate(form)
if (Object.keys(errors).length === 0) {
  // Form is valid
}
```

### 3. Store Types (for Pinia/Vuex)

```typescript
// stores/documentStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Document } from '@/types/document'

export const useDocumentStore = defineStore('document', () => {
  // State
  const documents = ref<Document[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const selectedId = ref<string | null>(null)

  // Getters
  const selectedDocument = computed(() =>
    documents.value.find(d => d.id === selectedId.value)
  )

  const documentCount = computed(() => documents.value.length)

  const documentsInFolder = computed(() => (folderId: string) =>
    documents.value.filter(d => d.folderId === folderId)
  )

  // Actions
  async function fetchDocuments(): Promise<void> {
    loading.value = true
    error.value = null

    try {
      const response = await fetch('/api/documents')
      documents.value = await response.json()
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  function selectDocument(id: string): void {
    selectedId.value = id
  }

  function addDocument(doc: Document): void {
    documents.value.push(doc)
  }

  return {
    // State
    documents,
    loading,
    error,
    selectedId,

    // Getters
    selectedDocument,
    documentCount,
    documentsInFolder,

    // Actions
    fetchDocuments,
    selectDocument,
    addDocument
  }
})

// Typed usage
const store = useDocumentStore()
const docs: Document[] = store.documents // Fully typed
```

---

## Advanced TypeScript Features

### 1. Conditional Types

```typescript
type NonNullableFields<T> = {
  [K in keyof T]: NonNullable<T[K]>
}

// Usage
interface Document {
  id: string
  name: string
  description?: string
}

type RequiredDocument = NonNullableFields<Document>
// { id: string; name: string; description: string }
```

### 2. Mapped Types

```typescript
type Readonly<T> = {
  readonly [K in keyof T]: T[K]
}

type Optional<T> = {
  [K in keyof T]?: T[K]
}

// Usage
type ReadonlyDocument = Readonly<Document>
type OptionalDocument = Optional<Document>
```

### 3. Template Literal Types

```typescript
type EventName = 'click' | 'focus' | 'blur'
type EventHandler = `on${Capitalize<EventName>}`
// Result: 'onClick' | 'onFocus' | 'onBlur'

// API endpoint types
type HttpMethod = 'get' | 'post' | 'put' | 'delete'
type Endpoint = `/api/${string}`
type ApiCall = `${HttpMethod} ${Endpoint}`
// Example: 'get /api/documents'
```

---

## Error Handling Patterns

### 1. Result Type Pattern

```typescript
type Success<T> = {
  success: true
  data: T
}

type Failure = {
  success: false
  error: string
}

type Result<T> = Success<T> | Failure

async function fetchDocument(id: string): Promise<Result<Document>> {
  try {
    const response = await fetch(`/api/documents/${id}`)
    if (!response.ok) {
      return {
        success: false,
        error: `HTTP ${response.status}: ${response.statusText}`
      }
    }
    const data = await response.json()
    return {
      success: true,
      data
    }
  } catch (error) {
    return {
      success: false,
      error: (error as Error).message
    }
  }
}

// Usage
const result = await fetchDocument('doc-123')
if (result.success) {
  console.log(result.data) // Document
} else {
  console.error(result.error) // string
}
```

### 2. Custom Error Classes

```typescript
class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public details?: unknown
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

class ValidationError extends Error {
  constructor(
    message: string,
    public field: string
  ) {
    super(message)
    this.name = 'ValidationError'
  }
}

// Usage
try {
  throw new ApiError('Document not found', 404)
} catch (error) {
  if (error instanceof ApiError) {
    console.log(`API Error ${error.statusCode}: ${error.message}`)
  } else if (error instanceof ValidationError) {
    console.log(`Validation Error on ${error.field}: ${error.message}`)
  }
}
```

---

## TypeScript Configuration for Vue Projects

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "useDefineForClassFields": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.vue"],
  "exclude": ["node_modules", "dist"]
}
```

---

## Documentation & Resources

### Official Documentation
- **TypeScript Docs**: https://www.typescriptlang.org/docs/
- **Handbook**: https://www.typescriptlang.org/docs/handbook/intro.html
- **Playground**: https://www.typescriptlang.org/play

### Type Definitions
- **DefinitelyTyped**: https://github.com/DefinitelyTyped/DefinitelyTyped
- **Search Types**: https://www.typescriptlang.org/dt/search

### Learning Resources
- **TypeScript Deep Dive**: https://basarat.gitbook.io/typescript/
- **Effective TypeScript**: Book by Dan Vanderkam
- **Type Challenges**: https://github.com/type-challenges/type-challenges

### Tools
- **ts-node**: Execute TypeScript directly
- **tsc**: TypeScript compiler
- **@typescript-eslint**: ESLint for TypeScript

---

## Quick Reference

### Common Types

```typescript
// Primitives
let str: string = 'hello'
let num: number = 42
let bool: boolean = true
let nul: null = null
let undef: undefined = undefined

// Arrays
let arr: string[] = ['a', 'b']
let arr2: Array<string> = ['a', 'b']

// Tuples
let tuple: [string, number] = ['hello', 42]

// Objects
let obj: { name: string; age: number } = { name: 'John', age: 30 }

// Functions
let fn: (x: number) => number = (x) => x * 2

// Union
let union: string | number = 'hello'

// Intersection
type A = { a: string }
type B = { b: number }
let inter: A & B = { a: 'hello', b: 42 }

// Literal types
let literal: 'success' | 'error' = 'success'
```

---

**For this project**: Use TypeScript in strict mode with all Vue components and composables. Define interfaces for all API responses and data models.
