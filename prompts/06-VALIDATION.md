# Form Validation & Input Handling

**Area**: User Input, Form Validation, File Uploads, Sanitization
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [Components](./03-COMPONENTS.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers secure input validation, sanitization, and form handling patterns using Zod schemas and DOMPurify.

---

## Input Sanitization

### Never Trust User Input

**Always sanitize and validate all user input before use or storage.**

### Text Sanitization

```typescript
// utils/validators/sanitizer.ts
import DOMPurify from 'dompurify'

export class InputSanitizer {
  /**
   * Remove all HTML tags and dangerous characters
   */
  static sanitizeText(input: string): string {
    return input
      .replace(/<[^>]*>/g, '')           // Remove HTML tags
      .replace(/javascript:/gi, '')       // Remove javascript: protocol
      .replace(/on\w+=/gi, '')           // Remove event handlers
      .trim()
  }

  /**
   * Sanitize HTML with allowed tags only
   */
  static sanitizeHTML(input: string): string {
    return DOMPurify.sanitize(input, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
      ALLOWED_ATTR: ['href'],
      ALLOW_DATA_ATTR: false,
      ALLOWED_URI_REGEXP: /^https?:\/\//
    })
  }

  /**
   * Sanitize for SQL-like contexts (escape special chars)
   */
  static sanitizeForQuery(input: string): string {
    return input
      .replace(/['";]/g, '')
      .trim()
  }

  /**
   * Sanitize filename
   */
  static sanitizeFilename(input: string): string {
    return input
      .replace(/[^a-zA-Z0-9._-]/g, '_')
      .replace(/\.{2,}/g, '.')
      .substring(0, 255)
  }

  /**
   * Sanitize URL
   */
  static sanitizeURL(input: string): string | null {
    try {
      const url = new URL(input)

      // Only allow https protocol
      if (url.protocol !== 'https:') {
        return null
      }

      return url.toString()
    } catch {
      return null
    }
  }
}
```

---

## Zod Schema Validation

### User Registration Schema

```typescript
// utils/validators/schemas.ts
import { z } from 'zod'

export const userRegistrationSchema = z.object({
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(30, 'Username must be at most 30 characters')
    .regex(/^[a-zA-Z0-9_-]+$/, 'Username can only contain letters, numbers, underscores, and hyphens'),

  email: z.string()
    .email('Invalid email address')
    .max(255, 'Email is too long')
    .toLowerCase(),

  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password is too long')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/\d/, 'Password must contain at least one number')
    .regex(/[@$!%*?&#]/, 'Password must contain at least one special character'),

  confirmPassword: z.string()
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword']
})

export type UserRegistration = z.infer<typeof userRegistrationSchema>
```

### Document Upload Schema

```typescript
// utils/validators/schemas.ts
import { z } from 'zod'

export const documentUploadSchema = z.object({
  name: z.string()
    .min(1, 'Document name is required')
    .max(255, 'Document name is too long')
    .regex(/^[^<>:"/\\|?*]+$/, 'Document name contains invalid characters'),

  folderId: z.string()
    .uuid('Invalid folder ID'),

  tags: z.array(z.string())
    .max(10, 'Maximum 10 tags allowed')
    .optional()
    .default([]),

  metadata: z.record(
    z.string().max(50),
    z.string().max(500)
  )
    .optional()
    .default({}),

  description: z.string()
    .max(1000, 'Description is too long')
    .optional()
})

export type DocumentUpload = z.infer<typeof documentUploadSchema>
```

### Search Query Schema

```typescript
// utils/validators/schemas.ts
import { z } from 'zod'

export const searchQuerySchema = z.object({
  query: z.string()
    .min(1, 'Search query is required')
    .max(100, 'Search query is too long'),

  filters: z.object({
    folderId: z.string().uuid().optional(),
    tags: z.array(z.string()).max(5).optional(),
    dateFrom: z.string().datetime().optional(),
    dateTo: z.string().datetime().optional(),
    fileTypes: z.array(z.enum(['pdf', 'doc', 'docx', 'xls', 'xlsx'])).optional()
  }).optional(),

  sort: z.enum(['name', 'date', 'size']).optional().default('date'),
  order: z.enum(['asc', 'desc']).optional().default('desc'),
  page: z.number().min(1).optional().default(1),
  pageSize: z.number().min(10).max(100).optional().default(20)
})

export type SearchQuery = z.infer<typeof searchQuerySchema>
```

---

## File Upload Validation

### Client-Side File Validation

```typescript
// utils/validators/fileValidator.ts
import { z } from 'zod'

const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain'
]

const ALLOWED_EXTENSIONS = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt']

const MAX_FILE_SIZE = 100 * 1024 * 1024 // 100MB

export class FileValidator {
  static validateFile(file: File): { valid: boolean; error?: string } {
    // Check file exists
    if (!file) {
      return { valid: false, error: 'No file selected' }
    }

    // Check file size
    if (file.size === 0) {
      return { valid: false, error: 'File is empty' }
    }

    if (file.size > MAX_FILE_SIZE) {
      return {
        valid: false,
        error: `File size exceeds ${MAX_FILE_SIZE / 1024 / 1024}MB limit`
      }
    }

    // Check MIME type
    if (!ALLOWED_MIME_TYPES.includes(file.type)) {
      return {
        valid: false,
        error: 'File type not allowed'
      }
    }

    // Check extension
    const extension = this.getFileExtension(file.name)
    if (!ALLOWED_EXTENSIONS.includes(extension)) {
      return {
        valid: false,
        error: 'File extension not allowed'
      }
    }

    // Check filename
    const filenameResult = this.validateFilename(file.name)
    if (!filenameResult.valid) {
      return filenameResult
    }

    return { valid: true }
  }

  static validateFilename(filename: string): { valid: boolean; error?: string } {
    // Check length
    if (filename.length > 255) {
      return { valid: false, error: 'Filename is too long' }
    }

    // Check for dangerous characters
    const dangerousChars = /[<>:"/\\|?*\x00-\x1F]/
    if (dangerousChars.test(filename)) {
      return { valid: false, error: 'Filename contains invalid characters' }
    }

    // Check for path traversal attempts
    if (filename.includes('..') || filename.includes('./') || filename.includes('.\\')) {
      return { valid: false, error: 'Invalid filename' }
    }

    return { valid: true }
  }

  static getFileExtension(filename: string): string {
    const parts = filename.toLowerCase().split('.')
    return parts.length > 1 ? `.${parts.pop()}` : ''
  }

  static async validateFileContent(file: File): Promise<{ valid: boolean; error?: string }> {
    // Read file header to verify actual file type
    const header = await this.readFileHeader(file, 8)

    // PDF magic number: %PDF
    if (file.type === 'application/pdf') {
      const isPDF = header.startsWith('25504446') // %PDF in hex
      if (!isPDF) {
        return { valid: false, error: 'File content does not match PDF format' }
      }
    }

    // Add more magic number checks as needed...

    return { valid: true }
  }

  private static async readFileHeader(file: File, bytes: number): Promise<string> {
    const slice = file.slice(0, bytes)
    const buffer = await slice.arrayBuffer()
    const array = new Uint8Array(buffer)
    return Array.from(array).map(b => b.toString(16).padStart(2, '0')).join('')
  }
}
```

---

## Form Validation Composable

### Reusable Form Validation Hook

```typescript
// composables/useFormValidation.ts
import { ref, computed } from 'vue'
import { z, type ZodSchema } from 'zod'

export function useFormValidation<T extends ZodSchema>(schema: T) {
  const errors = ref<Record<string, string>>({})
  const isValid = computed(() => Object.keys(errors.value).length === 0)

  function validate(data: unknown): { success: boolean; data?: z.infer<T> } {
    try {
      const validated = schema.parse(data)
      errors.value = {}
      return { success: true, data: validated }
    } catch (error) {
      if (error instanceof z.ZodError) {
        errors.value = {}
        error.errors.forEach(err => {
          const path = err.path.join('.')
          errors.value[path] = err.message
        })
      }
      return { success: false }
    }
  }

  function validateField(field: string, value: unknown): boolean {
    try {
      // Extract field schema
      const fieldSchema = (schema as any).shape[field]
      if (fieldSchema) {
        fieldSchema.parse(value)
        delete errors.value[field]
        return true
      }
      return false
    } catch (error) {
      if (error instanceof z.ZodError) {
        errors.value[field] = error.errors[0].message
      }
      return false
    }
  }

  function clearErrors() {
    errors.value = {}
  }

  function clearFieldError(field: string) {
    delete errors.value[field]
  }

  return {
    errors,
    isValid,
    validate,
    validateField,
    clearErrors,
    clearFieldError
  }
}
```

### Usage in Component

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useFormValidation } from '@/composables/useFormValidation'
import { userRegistrationSchema } from '@/utils/validators/schemas'
import { InputSanitizer } from '@/utils/validators/sanitizer'

const formData = ref({
  username: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const { errors, isValid, validate, validateField } = useFormValidation(userRegistrationSchema)

function handleInput(field: string, value: string) {
  // Sanitize input
  const sanitized = InputSanitizer.sanitizeText(value)
  formData.value[field] = sanitized

  // Validate field
  validateField(field, sanitized)
}

async function handleSubmit() {
  const result = validate(formData.value)

  if (!result.success) {
    console.error('Validation failed:', errors.value)
    return
  }

  // Submit validated data
  try {
    await submitRegistration(result.data)
  } catch (error) {
    console.error('Registration failed:', error)
  }
}
</script>

<template>
  <v-form @submit.prevent="handleSubmit">
    <v-text-field
      :model-value="formData.username"
      label="Username"
      :error-messages="errors.username"
      @update:model-value="handleInput('username', $event)"
    />

    <v-text-field
      :model-value="formData.email"
      label="Email"
      type="email"
      :error-messages="errors.email"
      @update:model-value="handleInput('email', $event)"
    />

    <v-text-field
      :model-value="formData.password"
      label="Password"
      type="password"
      :error-messages="errors.password"
      @update:model-value="handleInput('password', $event)"
    />

    <v-text-field
      :model-value="formData.confirmPassword"
      label="Confirm Password"
      type="password"
      :error-messages="errors.confirmPassword"
      @update:model-value="handleInput('confirmPassword', $event)"
    />

    <v-btn
      type="submit"
      color="primary"
      :disabled="!isValid"
    >
      Register
    </v-btn>
  </v-form>
</template>
```

---

## Secure File Upload Component

### File Upload with Validation

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { FileValidator } from '@/utils/validators/fileValidator'
import { InputSanitizer } from '@/utils/validators/sanitizer'

const selectedFile = ref<File | null>(null)
const fileError = ref<string | null>(null)

async function handleFileSelect(files: File[]) {
  if (files.length === 0) return

  const file = files[0]

  // Validate file
  const basicValidation = FileValidator.validateFile(file)
  if (!basicValidation.valid) {
    fileError.value = basicValidation.error || 'Invalid file'
    selectedFile.value = null
    return
  }

  // Validate file content (async)
  const contentValidation = await FileValidator.validateFileContent(file)
  if (!contentValidation.valid) {
    fileError.value = contentValidation.error || 'Invalid file content'
    selectedFile.value = null
    return
  }

  // File is valid
  selectedFile.value = file
  fileError.value = null
}

async function handleUpload() {
  if (!selectedFile.value) return

  const formData = new FormData()
  formData.append('file', selectedFile.value)

  // Add sanitized metadata
  const metadata = {
    originalName: InputSanitizer.sanitizeFilename(selectedFile.value.name),
    uploadedAt: new Date().toISOString()
  }
  formData.append('metadata', JSON.stringify(metadata))

  try {
    await uploadFile(formData)
  } catch (error) {
    console.error('Upload failed:', error)
  }
}
</script>

<template>
  <div>
    <v-file-input
      :model-value="selectedFile ? [selectedFile] : []"
      label="Select file"
      :error-messages="fileError"
      accept=".pdf,.doc,.docx,.xls,.xlsx,.txt"
      show-size
      @update:model-value="handleFileSelect"
    />

    <v-btn
      :disabled="!selectedFile"
      color="primary"
      @click="handleUpload"
    >
      Upload
    </v-btn>
  </div>
</template>
```

---

## Real-Time Validation

### Debounced Validation

```typescript
// composables/useDebouncedValidation.ts
import { ref, watch } from 'vue'
import { z, type ZodSchema } from 'zod'

export function useDebouncedValidation<T extends ZodSchema>(
  schema: T,
  delayMs: number = 500
) {
  const value = ref<any>(null)
  const error = ref<string | null>(null)
  const validating = ref(false)

  let timeoutId: number | null = null

  watch(value, (newValue) => {
    if (timeoutId) {
      clearTimeout(timeoutId)
    }

    validating.value = true

    timeoutId = window.setTimeout(() => {
      try {
        schema.parse(newValue)
        error.value = null
      } catch (err) {
        if (err instanceof z.ZodError) {
          error.value = err.errors[0].message
        }
      } finally {
        validating.value = false
      }
    }, delayMs)
  })

  return {
    value,
    error,
    validating
  }
}
```

```vue
<script setup lang="ts">
import { useDebouncedValidation } from '@/composables/useDebouncedValidation'
import { z } from 'zod'

const emailSchema = z.string().email('Invalid email address')

const { value: email, error: emailError, validating } = useDebouncedValidation(emailSchema, 500)
</script>

<template>
  <v-text-field
    v-model="email"
    label="Email"
    :error-messages="emailError"
    :loading="validating"
  />
</template>
```

---

## Password Strength Indicator

### Password Strength Component

```vue
<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  password: string
}

const props = defineProps<Props>()

const strength = computed(() => {
  const password = props.password
  let score = 0

  if (password.length >= 8) score++
  if (password.length >= 12) score++
  if (/[a-z]/.test(password)) score++
  if (/[A-Z]/.test(password)) score++
  if (/\d/.test(password)) score++
  if (/[@$!%*?&#]/.test(password)) score++

  if (score <= 2) return { level: 'weak', color: 'error', text: 'Weak' }
  if (score <= 4) return { level: 'medium', color: 'warning', text: 'Medium' }
  return { level: 'strong', color: 'success', text: 'Strong' }
})

const progressValue = computed(() => {
  if (strength.value.level === 'weak') return 33
  if (strength.value.level === 'medium') return 66
  return 100
})
</script>

<template>
  <div class="password-strength">
    <v-progress-linear
      :model-value="progressValue"
      :color="strength.color"
      height="6"
      rounded
    />
    <div class="text-caption mt-1" :class="`text-${strength.color}`">
      Password strength: {{ strength.text }}
    </div>
  </div>
</template>
```

---

## Validation Checklist

- [ ] All user input sanitized before use
- [ ] Zod schemas for all forms
- [ ] File type validation (MIME + extension)
- [ ] File size validation
- [ ] File content validation (magic numbers)
- [ ] Filename sanitization
- [ ] URL validation (HTTPS only)
- [ ] Email validation
- [ ] Password strength requirements
- [ ] Real-time validation feedback
- [ ] Error messages user-friendly
- [ ] Never expose internal errors

---

## Related Guidelines

- **For security patterns**: See [Security](./02-SECURITY.md)
- **For component patterns**: See [Components](./03-COMPONENTS.md)
- **For API integration**: See [API](./05-API.md)
- **For TypeScript types**: See [TypeScript](./07-TYPESCRIPT.md)

---

**Remember**: Validation is your first line of defense. Never trust user input, always validate and sanitize.
