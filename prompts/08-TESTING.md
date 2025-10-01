# Testing & Security Validation

**Area**: Unit Testing, Integration Testing, Security Testing, E2E Testing
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [Components](./03-COMPONENTS.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers testing patterns with a focus on security validation, vulnerability prevention, and comprehensive test coverage.

---

## Testing Stack

### Recommended Testing Tools

- **Unit/Integration**: Vitest
- **Component Testing**: Vue Test Utils + Vitest
- **E2E Testing**: Playwright
- **Security Scanning**: npm audit, Snyk
- **Code Coverage**: Vitest coverage (c8)

---

## Security Testing Checklist

### Pre-Deployment Security Validation

**Must verify before each deployment:**

- [ ] **XSS Prevention**
  - No `v-html` with unsanitized user content
  - All user input sanitized with DOMPurify
  - Dynamic URLs validated (HTTPS only)
  - No `eval()` or `Function()` with user input

- [ ] **Input Validation**
  - All forms have Zod schema validation
  - File uploads validate type, size, content
  - API requests validate with Zod schemas
  - No SQL-like queries with unsanitized input

- [ ] **Authentication & Authorization**
  - Tokens stored in httpOnly cookies
  - CSRF tokens on all mutations
  - Auto-logout on inactivity working
  - Protected routes check authentication

- [ ] **Data Protection**
  - No sensitive data in localStorage
  - No secrets in client code
  - API responses don't leak internal data
  - Error messages are generic

- [ ] **Network Security**
  - HTTPS only (no HTTP)
  - CORS configured correctly
  - CSP headers implemented
  - Rate limiting active

- [ ] **Dependencies**
  - No vulnerable dependencies (`npm audit`)
  - Third-party libraries vetted
  - Latest security patches applied

---

## Unit Testing Patterns

### Testing Utilities and Functions

```typescript
// utils/__tests__/sanitizer.spec.ts
import { describe, it, expect } from 'vitest'
import { InputSanitizer } from '../validators/sanitizer'

describe('InputSanitizer', () => {
  describe('sanitizeText', () => {
    it('removes HTML tags', () => {
      const input = '<script>alert("XSS")</script>Hello'
      const result = InputSanitizer.sanitizeText(input)
      expect(result).toBe('Hello')
    })

    it('removes javascript: protocol', () => {
      const input = 'javascript:alert("XSS")'
      const result = InputSanitizer.sanitizeText(input)
      expect(result).toBe('alert("XSS")')
    })

    it('removes event handlers', () => {
      const input = '<div onclick="alert()">Click</div>'
      const result = InputSanitizer.sanitizeText(input)
      expect(result).toBe('Click')
    })

    it('trims whitespace', () => {
      const input = '  Hello World  '
      const result = InputSanitizer.sanitizeText(input)
      expect(result).toBe('Hello World')
    })
  })

  describe('sanitizeHTML', () => {
    it('allows safe HTML tags', () => {
      const input = '<p><strong>Bold</strong> and <em>italic</em></p>'
      const result = InputSanitizer.sanitizeHTML(input)
      expect(result).toContain('<strong>')
      expect(result).toContain('<em>')
    })

    it('removes dangerous tags', () => {
      const input = '<script>alert("XSS")</script><p>Safe</p>'
      const result = InputSanitizer.sanitizeHTML(input)
      expect(result).not.toContain('<script>')
      expect(result).toContain('Safe')
    })

    it('removes dangerous attributes', () => {
      const input = '<p onclick="alert()">Text</p>'
      const result = InputSanitizer.sanitizeHTML(input)
      expect(result).not.toContain('onclick')
    })
  })

  describe('sanitizeFilename', () => {
    it('replaces special characters with underscore', () => {
      const input = 'file<name>.pdf'
      const result = InputSanitizer.sanitizeFilename(input)
      expect(result).toBe('file_name_.pdf')
    })

    it('prevents path traversal', () => {
      const input = '../../../etc/passwd'
      const result = InputSanitizer.sanitizeFilename(input)
      expect(result).not.toContain('..')
    })

    it('limits length to 255 characters', () => {
      const input = 'a'.repeat(300)
      const result = InputSanitizer.sanitizeFilename(input)
      expect(result.length).toBeLessThanOrEqual(255)
    })
  })
})
```

### Testing Validation Schemas

```typescript
// utils/__tests__/schemas.spec.ts
import { describe, it, expect } from 'vitest'
import { userRegistrationSchema } from '../validators/schemas'

describe('userRegistrationSchema', () => {
  it('validates correct user data', () => {
    const validData = {
      username: 'john_doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'SecurePass123!'
    }

    const result = userRegistrationSchema.safeParse(validData)
    expect(result.success).toBe(true)
  })

  it('rejects username with special characters', () => {
    const invalidData = {
      username: 'john<script>',
      email: 'john@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'SecurePass123!'
    }

    const result = userRegistrationSchema.safeParse(invalidData)
    expect(result.success).toBe(false)
  })

  it('rejects short passwords', () => {
    const invalidData = {
      username: 'john_doe',
      email: 'john@example.com',
      password: 'Short1!',
      confirmPassword: 'Short1!'
    }

    const result = userRegistrationSchema.safeParse(invalidData)
    expect(result.success).toBe(false)
  })

  it('rejects passwords without special characters', () => {
    const invalidData = {
      username: 'john_doe',
      email: 'john@example.com',
      password: 'SecurePass123',
      confirmPassword: 'SecurePass123'
    }

    const result = userRegistrationSchema.safeParse(invalidData)
    expect(result.success).toBe(false)
  })

  it('rejects mismatched passwords', () => {
    const invalidData = {
      username: 'john_doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'DifferentPass123!'
    }

    const result = userRegistrationSchema.safeParse(invalidData)
    expect(result.success).toBe(false)
  })
})
```

---

## Component Testing

### Testing Vue Components

```typescript
// components/__tests__/DocumentCard.spec.ts
import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import DocumentCard from '../DocumentCard.vue'
import type { Document } from '@/types/models/document'

const vuetify = createVuetify()

describe('DocumentCard', () => {
  const mockDocument: Document = {
    id: '123',
    name: 'Test.pdf',
    folderId: 'folder-1',
    size: 1024,
    contentType: 'application/pdf',
    uploadedAt: '2025-09-30T12:00:00Z',
    uploadedBy: 'user-1',
    tags: ['test'],
    metadata: {},
    version: 1
  }

  it('renders document name', () => {
    const wrapper = mount(DocumentCard, {
      global: { plugins: [vuetify] },
      props: { document: mockDocument }
    })

    expect(wrapper.text()).toContain('Test.pdf')
  })

  it('emits select event on click', async () => {
    const wrapper = mount(DocumentCard, {
      global: { plugins: [vuetify] },
      props: { document: mockDocument }
    })

    await wrapper.find('[data-testid="document-card"]').trigger('click')

    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')?.[0]).toEqual([mockDocument])
  })

  it('sanitizes document name for display', () => {
    const maliciousDoc = {
      ...mockDocument,
      name: '<script>alert("XSS")</script>Test.pdf'
    }

    const wrapper = mount(DocumentCard, {
      global: { plugins: [vuetify] },
      props: { document: maliciousDoc }
    })

    // Should not contain script tag
    expect(wrapper.html()).not.toContain('<script>')
  })

  it('does not use v-html for user content', () => {
    const wrapper = mount(DocumentCard, {
      global: { plugins: [vuetify] },
      props: { document: mockDocument }
    })

    // Verify no v-html in component
    expect(wrapper.html()).not.toMatch(/v-html/)
  })
})
```

### Testing File Upload Component

```typescript
// components/__tests__/UploadDialog.spec.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import UploadDialog from '../UploadDialog.vue'

const vuetify = createVuetify()

describe('UploadDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('validates file type', async () => {
    const wrapper = mount(UploadDialog, {
      global: { plugins: [vuetify] }
    })

    const invalidFile = new File(['content'], 'test.exe', {
      type: 'application/x-msdownload'
    })

    await wrapper.vm.handleFileSelect([invalidFile])

    expect(wrapper.vm.fileError).toBeTruthy()
    expect(wrapper.vm.fileError).toContain('File type not allowed')
  })

  it('validates file size', async () => {
    const wrapper = mount(UploadDialog, {
      global: { plugins: [vuetify] }
    })

    // Create 101MB file (exceeds 100MB limit)
    const largeFile = new File(
      [new ArrayBuffer(101 * 1024 * 1024)],
      'large.pdf',
      { type: 'application/pdf' }
    )

    await wrapper.vm.handleFileSelect([largeFile])

    expect(wrapper.vm.fileError).toBeTruthy()
    expect(wrapper.vm.fileError).toContain('File size exceeds')
  })

  it('sanitizes filename before upload', async () => {
    const wrapper = mount(UploadDialog, {
      global: { plugins: [vuetify] }
    })

    const maliciousFile = new File(
      ['content'],
      '../../../etc/passwd',
      { type: 'application/pdf' }
    )

    await wrapper.vm.handleFileSelect([maliciousFile])

    // Filename should be sanitized
    expect(wrapper.vm.documentName).not.toContain('..')
  })
})
```

---

## Store Testing

### Testing Pinia Stores

```typescript
// stores/__tests__/documentStore.spec.ts
import { setActivePinia, createPinia } from 'pinia'
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useDocumentStore } from '../documentStore'

describe('documentStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('initializes with empty state', () => {
    const store = useDocumentStore()

    expect(store.documents).toEqual([])
    expect(store.selectedDocument).toBeNull()
    expect(store.loading).toBe(false)
  })

  it('adds document correctly', () => {
    const store = useDocumentStore()

    const doc = {
      id: '123',
      name: 'Test.pdf',
      folderId: 'root',
      size: 1024,
      contentType: 'application/pdf',
      uploadedAt: '2025-09-30T12:00:00Z',
      uploadedBy: 'user-1',
      tags: [],
      metadata: {},
      version: 1
    }

    store.addDocument(doc)

    expect(store.documents).toHaveLength(1)
    expect(store.documents[0]).toEqual(doc)
  })

  it('filters documents by folder', () => {
    const store = useDocumentStore()

    store.documents = [
      { id: '1', name: 'Doc1', folderId: 'folder1' },
      { id: '2', name: 'Doc2', folderId: 'folder2' },
      { id: '3', name: 'Doc3', folderId: 'folder1' }
    ] as any

    const filtered = store.documentsByFolder('folder1')

    expect(filtered).toHaveLength(2)
    expect(filtered.map(d => d.id)).toEqual(['1', '3'])
  })

  it('resets state on logout', () => {
    const store = useDocumentStore()

    store.documents = [{ id: '1', name: 'Doc1' }] as any
    store.selectedDocument = { id: '1', name: 'Doc1' } as any

    store.$reset()

    expect(store.documents).toEqual([])
    expect(store.selectedDocument).toBeNull()
  })
})
```

---

## API Testing

### Testing API Clients

```typescript
// services/__tests__/documentApi.spec.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { DocumentApi } from '../api/documentApi'
import type { Document } from '@/types/models/document'

// Mock axios
vi.mock('axios')

describe('DocumentApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('fetches documents with authentication', async () => {
    const mockDocuments: Document[] = [
      {
        id: '123',
        name: 'Test.pdf',
        folderId: 'root',
        size: 1024,
        contentType: 'application/pdf',
        uploadedAt: '2025-09-30T12:00:00Z',
        uploadedBy: 'user-1',
        tags: [],
        metadata: {},
        version: 1
      }
    ]

    const mockGet = vi.fn().mockResolvedValue({ data: mockDocuments })
    vi.mocked(axios.get).mockImplementation(mockGet)

    const result = await DocumentApi.getDocuments()

    expect(result).toEqual(mockDocuments)
    expect(mockGet).toHaveBeenCalledWith('/api/documents')
  })

  it('includes CSRF token on mutations', async () => {
    const mockPost = vi.fn().mockResolvedValue({ data: {} })
    vi.mocked(axios.post).mockImplementation(mockPost)

    await DocumentApi.createDocument({
      name: 'New.pdf',
      folderId: 'root'
    })

    // Verify CSRF token was included
    expect(mockPost).toHaveBeenCalled()
    const callConfig = mockPost.mock.calls[0][2]
    expect(callConfig?.headers).toHaveProperty('X-CSRF-Token')
  })

  it('validates request data with Zod', async () => {
    const invalidData = {
      name: '', // Empty name - invalid
      folderId: 'not-a-uuid' // Invalid UUID
    }

    await expect(
      DocumentApi.createDocument(invalidData as any)
    ).rejects.toThrow()
  })

  it('handles network errors gracefully', async () => {
    const mockGet = vi.fn().mockRejectedValue(new Error('Network error'))
    vi.mocked(axios.get).mockImplementation(mockGet)

    await expect(DocumentApi.getDocuments()).rejects.toThrow('Network error')
  })
})
```

---

## E2E Testing

### End-to-End Security Tests

```typescript
// e2e/security.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Security', () => {
  test('prevents XSS in document names', async ({ page }) => {
    await page.goto('/documents')

    // Try to create document with XSS payload
    await page.click('[data-testid="upload-button"]')
    await page.fill('[data-testid="document-name"]', '<script>alert("XSS")</script>')
    await page.click('[data-testid="submit"]')

    // Verify script tag is not in DOM
    const html = await page.content()
    expect(html).not.toContain('<script>alert("XSS")</script>')
  })

  test('enforces authentication on protected routes', async ({ page }) => {
    // Try to access protected route without login
    await page.goto('/documents')

    // Should redirect to login
    await expect(page).toHaveURL(/\/login/)
  })

  test('auto-logout after inactivity', async ({ page }) => {
    // Login
    await page.goto('/login')
    await page.fill('[data-testid="email"]', 'user@example.com')
    await page.fill('[data-testid="password"]', 'password123')
    await page.click('[data-testid="login-button"]')

    // Wait for inactivity timeout (15 minutes in production, shorter in test)
    await page.waitForTimeout(15 * 60 * 1000)

    // Should be logged out
    await expect(page).toHaveURL(/\/login/)
  })

  test('validates file uploads', async ({ page }) => {
    await page.goto('/documents')
    await page.click('[data-testid="upload-button"]')

    // Try to upload invalid file type
    const fileInput = await page.$('[data-testid="file-input"]')
    await fileInput?.setInputFiles({
      name: 'malicious.exe',
      mimeType: 'application/x-msdownload',
      buffer: Buffer.from('fake exe content')
    })

    // Should show error
    await expect(page.locator('[data-testid="file-error"]')).toContainText('File type not allowed')
  })

  test('includes CSRF token in mutations', async ({ page }) => {
    await page.goto('/documents')

    // Intercept network requests
    await page.route('/api/documents', (route) => {
      const headers = route.request().headers()
      expect(headers).toHaveProperty('x-csrf-token')
      route.continue()
    })

    await page.click('[data-testid="create-document"]')
  })
})
```

---

## Security Vulnerability Scanning

### Automated Dependency Scanning

```bash
# Run npm audit
npm audit

# Fix vulnerabilities automatically
npm audit fix

# Check for outdated packages
npm outdated

# Use Snyk for advanced scanning
npx snyk test

# Continuous monitoring
npx snyk monitor
```

### Pre-Commit Security Checks

```json
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:security": "npm audit && npm run test:xss && npm run test:auth",
    "test:xss": "vitest run --grep 'XSS|sanitize|v-html'",
    "test:auth": "vitest run --grep 'auth|csrf|token'",
    "precommit": "npm run test:security"
  }
}
```

---

## Coverage Requirements

### Minimum Coverage Thresholds

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'c8',
      reporter: ['text', 'html', 'lcov'],
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
      // Require 100% coverage for security-critical files
      perFile: true,
      thresholds: {
        'src/utils/validators/**': {
          lines: 100,
          functions: 100,
          branches: 100,
          statements: 100
        },
        'src/services/security/**': {
          lines: 100,
          functions: 100,
          branches: 100,
          statements: 100
        }
      }
    }
  }
})
```

---

## Test Organization

### Testing Structure

```
tests/
├── unit/
│   ├── utils/
│   │   ├── sanitizer.spec.ts
│   │   ├── schemas.spec.ts
│   │   └── fileValidator.spec.ts
│   ├── composables/
│   │   └── useFormValidation.spec.ts
│   └── services/
│       └── documentApi.spec.ts
├── component/
│   ├── DocumentCard.spec.ts
│   ├── UploadDialog.spec.ts
│   └── FolderTree.spec.ts
├── integration/
│   ├── stores/
│   │   └── documentStore.spec.ts
│   └── flows/
│       └── uploadFlow.spec.ts
└── e2e/
    ├── security.spec.ts
    ├── authentication.spec.ts
    └── fileUpload.spec.ts
```

---

## Testing Best Practices Checklist

- [ ] All security utils have 100% coverage
- [ ] XSS prevention tested
- [ ] Input sanitization tested
- [ ] File validation tested
- [ ] CSRF token handling tested
- [ ] Authentication flows tested
- [ ] Authorization checks tested
- [ ] Rate limiting tested
- [ ] Error handling tested
- [ ] No secrets in test files
- [ ] Mock external dependencies
- [ ] Clean up after tests

---

## Vuetify-Specific Testing

### Test Setup for Vuetify Components

```typescript
// tests/setup.ts
import { config } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { vi } from 'vitest'
import ResizeObserver from 'resize-observer-polyfill'

// Setup Vuetify
const vuetify = createVuetify({
  components,
  directives
})

config.global.plugins = [vuetify]

// Mock ResizeObserver
global.ResizeObserver = ResizeObserver

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
  takeRecords: vi.fn(),
  root: null,
  rootMargin: '',
  thresholds: []
}))

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
})
```

### Vuetify Test Helpers

```typescript
// tests/utils/vuetify-test-helper.ts
import { VueWrapper } from '@vue/test-utils'

export class VuetifyTestHelper {
  static async openDialog(wrapper: VueWrapper) {
    const activator = wrapper.find('[data-testid="dialog-activator"]')
    await activator.trigger('click')
    await wrapper.vm.$nextTick()

    // Wait for animation
    await new Promise(resolve => setTimeout(resolve, 300))
  }

  static async selectOption(wrapper: VueWrapper, label: string, option: string) {
    const select = wrapper.find(`.v-select:has(label:contains("${label}"))`)
    await select.trigger('click')

    const item = wrapper.find(`.v-list-item:contains("${option}")`)
    await item.trigger('click')
  }

  static findSnackbar(wrapper: VueWrapper, text?: string) {
    if (text) {
      return wrapper.find(`.v-snackbar:contains("${text}")`)
    }
    return wrapper.find('.v-snackbar')
  }

  static async waitForAsyncValidation(wrapper: VueWrapper, timeout = 1000) {
    await new Promise(resolve => setTimeout(resolve, timeout))
    await wrapper.vm.$nextTick()
  }
}
```

---

## Test Data Factories

### Creating Realistic Test Data

```typescript
// tests/utils/test-factory.ts
import { faker } from '@faker-js/faker'

export class TestDataFactory {
  static createUser(overrides?: Partial<User>): User {
    return {
      id: faker.string.uuid(),
      email: faker.internet.email(),
      name: faker.person.fullName(),
      role: faker.helpers.arrayElement(['admin', 'user', 'guest']),
      status: faker.helpers.arrayElement(['active', 'inactive']),
      createdAt: faker.date.past().toISOString(),
      ...overrides
    }
  }

  static createUsers(count: number): User[] {
    return Array.from({ length: count }, () => this.createUser())
  }

  static createDocument(overrides?: Partial<Document>): Document {
    return {
      id: faker.string.uuid(),
      name: faker.system.fileName(),
      folderId: faker.string.uuid(),
      size: faker.number.int({ min: 1000, max: 10000000 }),
      contentType: faker.helpers.arrayElement([
        'application/pdf',
        'application/msword',
        'application/vnd.ms-excel'
      ]),
      uploadedAt: faker.date.past().toISOString(),
      uploadedBy: faker.string.uuid(),
      tags: faker.helpers.arrayElements(['work', 'personal', 'important'], 2),
      metadata: {},
      version: 1,
      ...overrides
    }
  }

  static createLoginCredentials(): { email: string; password: string } {
    return {
      email: faker.internet.email(),
      password: 'ValidPass123!'
    }
  }
}
```

---

## Testing Best Practices Summary

### Unit Testing
- [ ] Test files co-located with source files or in `__tests__`
- [ ] Mock external dependencies (API calls, stores)
- [ ] Test component props, events, and slots
- [ ] Test computed properties and watchers
- [ ] Test error states and edge cases
- [ ] Test accessibility attributes
- [ ] Maintain > 80% code coverage
- [ ] Use test factories for consistent data
- [ ] Test Vuetify component integrations

### Integration Testing
- [ ] Test store actions and mutations
- [ ] Test composables with different inputs
- [ ] Test service layer with mocked APIs
- [ ] Test router guards and navigation
- [ ] Test form validation flows
- [ ] Test real component interactions
- [ ] Test error recovery mechanisms

### E2E Testing
- [ ] Use Page Object Model pattern
- [ ] Test critical user journeys
- [ ] Test across different browsers
- [ ] Test responsive layouts
- [ ] Test accessibility standards
- [ ] Test performance budgets
- [ ] Test security features (XSS, CSRF)
- [ ] Test offline/error scenarios
- [ ] Use realistic test data

### Performance Testing
- [ ] Measure First Contentful Paint
- [ ] Measure Time to Interactive
- [ ] Test with network throttling
- [ ] Test with large datasets
- [ ] Monitor bundle sizes
- [ ] Test memory leaks
- [ ] Profile component rendering

---

## Related Guidelines

- **For security patterns**: See [Security](./02-SECURITY.md)
- **For component patterns**: See [Components](./03-COMPONENTS.md)
- **For validation**: See [Validation](./06-VALIDATION.md)
- **For API testing**: See [API](./05-API.md)
- **For UI/UX testing**: See [UI/UX](./10-UI-UX.md)

---

**Remember**: Tests are your safety net. Security-critical code must have 100% test coverage.
