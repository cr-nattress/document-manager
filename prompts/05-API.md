# API & Network Security

**Area**: HTTP Requests, API Integration, Network Security
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [State](./04-STATE.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers secure API integration patterns, including request/response handling, authentication, CSRF protection, and rate limiting.

---

## Secure API Client Setup

### Base API Client with Interceptors

```typescript
// services/api/baseApiClient.ts
import axios, { type AxiosInstance, type AxiosError } from 'axios'
import { useAuthStore } from '@/stores/authStore'
import { useUIStore } from '@/stores/uiStore'

export class BaseApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      },
      withCredentials: true // Send cookies (for httpOnly tokens)
    })

    this.setupInterceptors()
  }

  private setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        // Add CSRF token to headers
        const csrfToken = this.getCsrfToken()
        if (csrfToken) {
          config.headers['X-CSRF-Token'] = csrfToken
        }

        // Add correlation ID for request tracking
        config.headers['X-Correlation-ID'] = this.generateCorrelationId()

        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => {
        // Update CSRF token if provided
        const newCsrfToken = response.headers['x-csrf-token']
        if (newCsrfToken) {
          this.storeCsrfToken(newCsrfToken)
        }

        return response
      },
      (error: AxiosError) => {
        return this.handleError(error)
      }
    )
  }

  private handleError(error: AxiosError) {
    const authStore = useAuthStore()
    const uiStore = useUIStore()

    if (error.response) {
      switch (error.response.status) {
        case 401:
          // Unauthorized - logout user
          authStore.logout()
          uiStore.showNotification('error', 'Session expired. Please login again.')
          break

        case 403:
          // Forbidden - insufficient permissions
          uiStore.showNotification('error', 'Access denied.')
          break

        case 429:
          // Rate limit exceeded
          uiStore.showNotification('error', 'Too many requests. Please try again later.')
          break

        case 500:
        case 502:
        case 503:
          // Server errors - generic message
          uiStore.showNotification('error', 'Server error. Please try again later.')
          break

        default:
          // Generic error
          uiStore.showNotification('error', 'An error occurred. Please try again.')
      }
    } else if (error.request) {
      // Network error
      uiStore.showNotification('error', 'Network error. Please check your connection.')
    }

    return Promise.reject(error)
  }

  private getCsrfToken(): string | null {
    return localStorage.getItem('csrf-token')
  }

  private storeCsrfToken(token: string): void {
    localStorage.setItem('csrf-token', token)
  }

  private generateCorrelationId(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 11)}`
  }

  public getClient(): AxiosInstance {
    return this.client
  }
}

export const apiClient = new BaseApiClient().getClient()
```

---

## CSRF Token Handling

### Fetch CSRF Token on App Init

```typescript
// services/security/csrfService.ts
import { apiClient } from '@/services/api/baseApiClient'

export class CsrfService {
  static async fetchToken(): Promise<string> {
    try {
      const response = await apiClient.get('/api/csrf-token')
      const token = response.data.token

      if (!token) {
        throw new Error('No CSRF token received')
      }

      // Store token in localStorage
      localStorage.setItem('csrf-token', token)
      return token
    } catch (error) {
      console.error('Failed to fetch CSRF token:', error)
      throw error
    }
  }

  static getToken(): string | null {
    return localStorage.getItem('csrf-token')
  }

  static clearToken(): void {
    localStorage.removeItem('csrf-token')
  }
}
```

```vue
<!-- App.vue -->
<script setup lang="ts">
import { onMounted } from 'vue'
import { CsrfService } from '@/services/security/csrfService'

onMounted(async () => {
  try {
    await CsrfService.fetchToken()
  } catch (error) {
    console.error('Failed to initialize CSRF protection:', error)
  }
})
</script>
```

### Include CSRF Token in Mutations

```typescript
// services/api/documentApi.ts
import { apiClient } from './baseApiClient'
import type { Document, CreateDocumentRequest } from '@/types/models/document'

export class DocumentApi {
  // GET requests (safe, no CSRF needed)
  static async getDocuments(): Promise<Document[]> {
    const response = await apiClient.get('/api/documents')
    return response.data
  }

  // POST requests (mutation, CSRF required)
  static async createDocument(data: CreateDocumentRequest): Promise<Document> {
    // CSRF token automatically added by interceptor
    const response = await apiClient.post('/api/documents', data)
    return response.data
  }

  // PUT requests (mutation, CSRF required)
  static async updateDocument(id: string, data: Partial<Document>): Promise<Document> {
    const response = await apiClient.put(`/api/documents/${id}`, data)
    return response.data
  }

  // DELETE requests (mutation, CSRF required)
  static async deleteDocument(id: string): Promise<void> {
    await apiClient.delete(`/api/documents/${id}`)
  }
}
```

---

## Rate Limiting

### Client-Side Rate Limiter

```typescript
// composables/useRateLimiter.ts
import { ref, computed } from 'vue'

interface RateLimitConfig {
  maxRequests: number
  windowMs: number
}

const rateLimits = new Map<string, number[]>()

export function useRateLimiter(key: string, maxRequests: number, windowMs: number) {
  const timestamps = ref<number[]>(rateLimits.get(key) || [])

  const remaining = computed(() => {
    const now = Date.now()
    const validTimestamps = timestamps.value.filter(t => now - t < windowMs)
    return Math.max(0, maxRequests - validTimestamps.length)
  })

  const nextResetTime = computed(() => {
    if (timestamps.value.length === 0) return 0
    const oldestTimestamp = timestamps.value[0]
    return oldestTimestamp + windowMs
  })

  function checkLimit(): boolean {
    const now = Date.now()

    // Remove expired timestamps
    timestamps.value = timestamps.value.filter(t => now - t < windowMs)

    // Check if limit exceeded
    if (timestamps.value.length >= maxRequests) {
      return false
    }

    // Add current timestamp
    timestamps.value.push(now)

    // Update map
    rateLimits.set(key, timestamps.value)

    return true
  }

  function reset() {
    timestamps.value = []
    rateLimits.delete(key)
  }

  return {
    remaining,
    nextResetTime,
    checkLimit,
    reset
  }
}
```

### Usage in Components

```vue
<script setup lang="ts">
import { useRateLimiter } from '@/composables/useRateLimiter'
import { DocumentApi } from '@/services/api/documentApi'

// Allow 10 uploads per minute
const { checkLimit, remaining } = useRateLimiter('upload', 10, 60000)

async function handleUpload(file: File) {
  if (!checkLimit()) {
    alert(`Rate limit exceeded. You have ${remaining.value} uploads remaining.`)
    return
  }

  try {
    await DocumentApi.uploadDocument(file)
  } catch (error) {
    console.error('Upload failed:', error)
  }
}
</script>
```

---

## Request Validation

### Validate Request Data with Zod

```typescript
// services/api/documentApi.ts
import { z } from 'zod'
import { apiClient } from './baseApiClient'

// Request schema
const createDocumentSchema = z.object({
  name: z.string().min(1).max(255),
  folderId: z.string().uuid(),
  tags: z.array(z.string()).max(10),
  metadata: z.record(z.string(), z.string()).optional()
})

export class DocumentApi {
  static async createDocument(data: unknown): Promise<Document> {
    // Validate request data before sending
    const validated = createDocumentSchema.parse(data)

    const response = await apiClient.post('/api/documents', validated)
    return response.data
  }
}
```

---

## Response Validation

### Validate Response Data

```typescript
// services/api/documentApi.ts
import { z } from 'zod'
import { apiClient } from './baseApiClient'

// Response schema
const documentSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  folderId: z.string().uuid(),
  uploadedAt: z.string().datetime(),
  size: z.number(),
  contentType: z.string(),
  tags: z.array(z.string()),
  metadata: z.record(z.string(), z.string())
})

export class DocumentApi {
  static async getDocument(id: string): Promise<Document> {
    const response = await apiClient.get(`/api/documents/${id}`)

    // Validate response data
    const validated = documentSchema.parse(response.data)

    return validated
  }

  static async getDocuments(): Promise<Document[]> {
    const response = await apiClient.get('/api/documents')

    // Validate array of documents
    const validated = z.array(documentSchema).parse(response.data)

    return validated
  }
}
```

---

## File Upload Security

### Secure File Upload Implementation

```typescript
// services/api/uploadApi.ts
import { apiClient } from './baseApiClient'
import { z } from 'zod'

const ALLOWED_FILE_TYPES = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
]

const MAX_FILE_SIZE = 100 * 1024 * 1024 // 100MB

export class UploadApi {
  static async uploadFile(
    file: File,
    metadata: Record<string, string>
  ): Promise<{ documentId: string; url: string }> {
    // Validate file type
    if (!ALLOWED_FILE_TYPES.includes(file.type)) {
      throw new Error('Invalid file type')
    }

    // Validate file size
    if (file.size > MAX_FILE_SIZE) {
      throw new Error('File too large')
    }

    // Create FormData
    const formData = new FormData()
    formData.append('file', file)
    formData.append('metadata', JSON.stringify(metadata))

    // Upload with progress tracking
    const response = await apiClient.post('/api/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      onUploadProgress: (progressEvent) => {
        const percentCompleted = Math.round(
          (progressEvent.loaded * 100) / (progressEvent.total || 1)
        )
        console.log(`Upload progress: ${percentCompleted}%`)
      }
    })

    // Validate response
    const uploadResponseSchema = z.object({
      documentId: z.string().uuid(),
      url: z.string().url()
    })

    return uploadResponseSchema.parse(response.data)
  }
}
```

---

## Retry Logic

### Automatic Retry on Failure

```typescript
// utils/api/retryHelper.ts
export async function retryRequest<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000
): Promise<T> {
  let lastError: Error | null = null

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error as Error
      console.warn(`Request failed (attempt ${i + 1}/${maxRetries}):`, error)

      if (i < maxRetries - 1) {
        // Wait before retrying (exponential backoff)
        await new Promise(resolve =>
          setTimeout(resolve, delayMs * Math.pow(2, i))
        )
      }
    }
  }

  throw lastError
}
```

```typescript
// services/api/documentApi.ts
import { retryRequest } from '@/utils/api/retryHelper'
import { apiClient } from './baseApiClient'

export class DocumentApi {
  static async getDocuments(): Promise<Document[]> {
    return retryRequest(async () => {
      const response = await apiClient.get('/api/documents')
      return response.data
    }, 3, 1000)
  }
}
```

---

## Request Cancellation

### Cancel In-Flight Requests

```typescript
// composables/useApiRequest.ts
import { ref, onBeforeUnmount } from 'vue'
import axios, { type CancelTokenSource } from 'axios'

export function useApiRequest<T>() {
  const loading = ref(false)
  const error = ref<Error | null>(null)
  const data = ref<T | null>(null)

  let cancelTokenSource: CancelTokenSource | null = null

  async function execute(fn: (cancelToken: CancelTokenSource) => Promise<T>) {
    loading.value = true
    error.value = null

    // Cancel previous request if still pending
    if (cancelTokenSource) {
      cancelTokenSource.cancel('New request initiated')
    }

    cancelTokenSource = axios.CancelToken.source()

    try {
      data.value = await fn(cancelTokenSource)
    } catch (err) {
      if (!axios.isCancel(err)) {
        error.value = err as Error
      }
    } finally {
      loading.value = false
    }
  }

  // Cancel on component unmount
  onBeforeUnmount(() => {
    if (cancelTokenSource) {
      cancelTokenSource.cancel('Component unmounted')
    }
  })

  return {
    loading,
    error,
    data,
    execute
  }
}
```

```vue
<script setup lang="ts">
import { useApiRequest } from '@/composables/useApiRequest'
import { apiClient } from '@/services/api/baseApiClient'
import type { Document } from '@/types/models/document'

const { loading, error, data, execute } = useApiRequest<Document[]>()

async function searchDocuments(query: string) {
  await execute(async (cancelToken) => {
    const response = await apiClient.get('/api/documents/search', {
      params: { q: query },
      cancelToken: cancelToken.token
    })
    return response.data
  })
}
</script>
```

---

## Error Handling

### Consistent Error Handling Pattern

```typescript
// utils/api/errorHandler.ts
import type { AxiosError } from 'axios'

export interface ApiError {
  status: number
  message: string
  code?: string
}

export function handleApiError(error: unknown): ApiError {
  if (axios.isAxiosError(error)) {
    const axiosError = error as AxiosError

    if (axiosError.response) {
      // Server responded with error status
      return {
        status: axiosError.response.status,
        message: getErrorMessage(axiosError.response.status),
        code: (axiosError.response.data as any)?.code
      }
    } else if (axiosError.request) {
      // Request made but no response
      return {
        status: 0,
        message: 'Network error. Please check your connection.'
      }
    }
  }

  // Unknown error
  return {
    status: 500,
    message: 'An unexpected error occurred.'
  }
}

function getErrorMessage(status: number): string {
  switch (status) {
    case 400:
      return 'Invalid request. Please check your input.'
    case 401:
      return 'Authentication required. Please login.'
    case 403:
      return 'Access denied.'
    case 404:
      return 'Resource not found.'
    case 429:
      return 'Too many requests. Please try again later.'
    case 500:
    case 502:
    case 503:
      return 'Server error. Please try again later.'
    default:
      return 'An error occurred. Please try again.'
  }
}
```

---

## Request/Response Logging

### Development Logging

```typescript
// services/api/baseApiClient.ts
import axios from 'axios'

const isDevelopment = import.meta.env.MODE === 'development'

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL
})

if (isDevelopment) {
  // Log requests in development
  client.interceptors.request.use((config) => {
    console.log('→ Request:', {
      method: config.method?.toUpperCase(),
      url: config.url,
      data: config.data
    })
    return config
  })

  // Log responses in development
  client.interceptors.response.use(
    (response) => {
      console.log('← Response:', {
        status: response.status,
        url: response.config.url,
        data: response.data
      })
      return response
    },
    (error) => {
      console.error('← Error:', {
        status: error.response?.status,
        url: error.config?.url,
        data: error.response?.data
      })
      return Promise.reject(error)
    }
  )
}
```

---

## API Security Checklist

- [ ] HTTPS only (no HTTP)
- [ ] CSRF token on all mutations
- [ ] httpOnly cookies for tokens
- [ ] Rate limiting implemented
- [ ] Request validation with Zod
- [ ] Response validation with Zod
- [ ] File upload validation (type, size)
- [ ] Error messages don't expose internals
- [ ] Request cancellation on unmount
- [ ] Retry logic for transient failures
- [ ] Correlation IDs for request tracking

---

## Related Guidelines

- **For security patterns**: See [Security](./02-SECURITY.md)
- **For state management**: See [State](./04-STATE.md)
- **For validation patterns**: See [Validation](./06-VALIDATION.md)
- **For TypeScript types**: See [TypeScript](./07-TYPESCRIPT.md)

---

**Remember**: The API is the gateway to your data. Secure it thoroughly and validate everything.
