# Security Best Practices

**Area**: Application Security, Input Validation, Authentication, Authorization
**Related**: [MASTER](./MASTER.md), [Validation](./06-VALIDATION.md), [API](./05-API.md)
**Priority**: CRITICAL - Always reference this prompt
**Last Updated**: 2025-09-30

---

## Security-First Mindset

**Every line of code is a potential security vulnerability.**

Before writing any code, ask:
1. What user input is involved?
2. What sensitive data is handled?
3. What could an attacker do with this?
4. What protections are needed?

---

## Core Security Principles

### 1. Defense in Depth
Implement multiple layers of security:
- **Client-side validation** (UX)
- **Server-side validation** (actual security)
- **Database constraints** (last line of defense)
- **Network security** (firewalls, HTTPS)

### 2. Never Trust User Input
**All** user input is malicious until proven otherwise:
- Form inputs
- URL parameters
- File uploads
- Cookies
- Headers
- WebSocket messages

### 3. Principle of Least Privilege
Grant minimum necessary permissions:
- Users see only their data
- APIs expose minimum information
- Code has minimum permissions

### 4. Fail Securely
When errors occur:
- Don't expose internal details
- Log security events
- Fail to safe state
- Show generic error messages

---

## XSS (Cross-Site Scripting) Prevention

### Rule 1: Never Use `v-html` with User Content

**BAD** - Direct XSS vulnerability:
```vue
<template>
  <!-- NEVER DO THIS -->
  <div v-html="userComment"></div>
  <div v-html="blogPost.content"></div>
</template>
```

**GOOD** - Safe text rendering:
```vue
<template>
  <!-- Vue automatically escapes -->
  <div>{{ userComment }}</div>
  <p>{{ blogPost.content }}</p>
</template>
```

### Rule 2: Sanitize When HTML is Required

```typescript
// utils/validators/sanitizer.ts
import DOMPurify from 'dompurify'

export class InputSanitizer {
  /**
   * Sanitize HTML - only use when HTML is absolutely necessary
   * Default: strips all HTML
   */
  static sanitizeHTML(input: string): string {
    return DOMPurify.sanitize(input, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
      ALLOWED_ATTR: ['href'],
      ALLOW_DATA_ATTR: false
    })
  }

  /**
   * Remove all HTML - use this for most user input
   */
  static sanitizeText(input: string): string {
    return input
      .replace(/<[^>]*>/g, '') // Remove HTML tags
      .replace(/javascript:/gi, '') // Remove javascript: URLs
      .trim()
  }

  /**
   * Sanitize for use in attributes
   */
  static sanitizeAttribute(input: string): string {
    return input
      .replace(/["'<>`]/g, '') // Remove dangerous characters
      .trim()
  }
}
```

**Usage in Component**:
```vue
<script setup lang="ts">
import { computed } from 'vue'
import { InputSanitizer } from '@/utils/validators/sanitizer'

const props = defineProps<{
  userContent: string
}>()

// Always sanitize before displaying
const safeContent = computed(() =>
  InputSanitizer.sanitizeText(props.userContent)
)

// If HTML is absolutely required (rare case)
const safeHTML = computed(() =>
  InputSanitizer.sanitizeHTML(props.userContent)
)
</script>

<template>
  <!-- Safe: automatically escaped -->
  <div>{{ safeContent }}</div>

  <!-- Only if HTML is required and sanitized -->
  <div v-html="safeHTML"></div>
</template>
```

---

## Input Validation & Sanitization

### Schema-Based Validation with Zod

```typescript
// utils/validators/schemas.ts
import { z } from 'zod'

/**
 * User registration schema with security constraints
 */
export const userRegistrationSchema = z.object({
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(30, 'Username must be at most 30 characters')
    .regex(
      /^[a-zA-Z0-9_-]+$/,
      'Only alphanumeric characters, underscore, and hyphen allowed'
    ),

  email: z.string()
    .email('Invalid email address')
    .max(255, 'Email too long')
    .transform(val => val.toLowerCase().trim()),

  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/,
      'Password must contain uppercase, lowercase, number, and special character'
    )
})

/**
 * Document creation schema
 */
export const documentSchema = z.object({
  name: z.string()
    .min(1, 'Name is required')
    .max(255, 'Name too long')
    .transform(val => InputSanitizer.sanitizeText(val)),

  folderId: z.string()
    .uuid('Invalid folder ID'),

  tags: z.array(z.string().max(50))
    .max(20, 'Maximum 20 tags allowed')
    .optional(),

  metadata: z.record(z.string(), z.string())
    .refine(
      val => Object.keys(val).length <= 50,
      'Maximum 50 metadata fields'
    )
    .optional()
})

/**
 * URL validation - only allow HTTPS
 */
export const urlSchema = z.string()
  .url('Invalid URL')
  .startsWith('https://', 'Only HTTPS URLs allowed')
  .max(2000, 'URL too long')
```

### Email Validation

```typescript
export class InputSanitizer {
  /**
   * Validate email with additional security checks
   */
  static validateEmail(email: string): { valid: boolean; error?: string } {
    // Schema validation
    const result = z.string().email().max(255).safeParse(email)
    if (!result.success) {
      return { valid: false, error: result.error.errors[0].message }
    }

    // Additional checks
    const lowerEmail = email.toLowerCase()

    // Block obviously fake emails
    const suspiciousPatterns = [
      /@test\./,
      /@example\./,
      /@localhost/,
      /\+.*@/ // Block plus addressing for certain cases
    ]

    if (suspiciousPatterns.some(pattern => pattern.test(lowerEmail))) {
      return { valid: false, error: 'Invalid email domain' }
    }

    return { valid: true }
  }
}
```

---

## Authentication & Authorization

### Secure Token Storage

```typescript
// services/security/authService.ts
import CryptoJS from 'crypto-js'

export class AuthService {
  private readonly TOKEN_KEY = 'auth_token'
  private readonly REFRESH_TOKEN_KEY = 'refresh_token'

  /**
   * PRODUCTION: Use httpOnly cookies set by backend
   * DEVELOPMENT: Use sessionStorage (cleared on tab close)
   */
  setTokens(accessToken: string, refreshToken: string): void {
    if (import.meta.env.PROD) {
      // In production, tokens should be in httpOnly cookies
      // This is just a warning - backend must set cookies
      console.warn('⚠️ Tokens should be stored in httpOnly cookies by backend')
      return
    }

    // Development only - encrypt before storing
    const encryptedAccess = this.encrypt(accessToken)
    const encryptedRefresh = this.encrypt(refreshToken)

    sessionStorage.setItem(this.TOKEN_KEY, encryptedAccess)
    sessionStorage.setItem(this.REFRESH_TOKEN_KEY, encryptedRefresh)
  }

  getAccessToken(): string | null {
    if (import.meta.env.PROD) {
      // In production, token is in httpOnly cookie
      // Backend will automatically include it
      return null
    }

    const encrypted = sessionStorage.getItem(this.TOKEN_KEY)
    return encrypted ? this.decrypt(encrypted) : null
  }

  /**
   * Clear all authentication data
   */
  clearAuth(): void {
    // Clear storage
    sessionStorage.clear()
    localStorage.clear()

    // Clear all cookies (if any)
    document.cookie.split(';').forEach(cookie => {
      document.cookie = cookie
        .replace(/^ +/, '')
        .replace(/=.*/, '=;expires=' + new Date().toUTCString() + ';path=/')
    })
  }

  private encrypt(data: string): string {
    const key = import.meta.env.VITE_ENCRYPTION_KEY || 'dev-key-change-in-prod'
    return CryptoJS.AES.encrypt(data, key).toString()
  }

  private decrypt(encryptedData: string): string {
    const key = import.meta.env.VITE_ENCRYPTION_KEY || 'dev-key-change-in-prod'
    const bytes = CryptoJS.AES.decrypt(encryptedData, key)
    return bytes.toString(CryptoJS.enc.Utf8)
  }
}
```

### Route Guards

```typescript
// guards/authGuard.ts
import type { RouteLocationNormalized } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'

export function authGuard(to: RouteLocationNormalized): boolean | string {
  const authStore = useAuthStore()

  // Check authentication
  if (!authStore.isAuthenticated) {
    // Save intended destination
    return {
      path: '/login',
      query: { redirect: to.fullPath }
    }
  }

  // Check role-based permissions
  if (to.meta.requiredRole) {
    if (!authStore.hasRole(to.meta.requiredRole as string)) {
      console.error('🔒 Unauthorized access attempt:', to.path)
      return '/unauthorized'
    }
  }

  // Check resource-level permissions
  if (to.meta.requiredPermission) {
    if (!authStore.hasPermission(to.meta.requiredPermission as string)) {
      console.error('🔒 Insufficient permissions:', to.path)
      return '/forbidden'
    }
  }

  return true
}

// In router configuration
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth) {
    const result = authGuard(to)
    if (result === true) {
      next()
    } else {
      next(result)
    }
  } else {
    next()
  }
})
```

---

## CSRF (Cross-Site Request Forgery) Protection

### CSRF Token Handling

```typescript
// services/api/secureApiClient.ts
import axios, { type AxiosInstance } from 'axios'

export class SecureApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_URL,
      timeout: 10000,
      withCredentials: true, // Include cookies
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })

    this.setupInterceptors()
  }

  private setupInterceptors(): void {
    // Add CSRF token to all requests
    this.client.interceptors.request.use(
      config => {
        // Get CSRF token from meta tag or cookie
        const csrfToken = this.getCSRFToken()

        if (csrfToken) {
          config.headers['X-CSRF-Token'] = csrfToken
        }

        // Add auth token if using header-based auth
        const authToken = sessionStorage.getItem('auth_token')
        if (authToken) {
          config.headers.Authorization = `Bearer ${authToken}`
        }

        return config
      },
      error => Promise.reject(error)
    )
  }

  /**
   * Get CSRF token from DOM or cookie
   */
  private getCSRFToken(): string | null {
    // Try meta tag first
    const metaToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content')

    if (metaToken) return metaToken

    // Try cookie
    const cookieToken = document.cookie
      .split('; ')
      .find(row => row.startsWith('XSRF-TOKEN='))
      ?.split('=')[1]

    return cookieToken || null
  }
}
```

---

## Content Security Policy (CSP)

```typescript
// constants/security/csp.ts
export const CSP_DIRECTIVES = {
  // Only load resources from same origin
  'default-src': ["'self'"],

  // Scripts: self only (no inline scripts in production)
  'script-src': [
    "'self'",
    import.meta.env.DEV ? "'unsafe-inline'" : "", // Dev only
    import.meta.env.DEV ? "'unsafe-eval'" : ""    // Dev only
  ].filter(Boolean),

  // Styles: self + inline styles for Vue
  'style-src': ["'self'", "'unsafe-inline'"],

  // Images: self + data URIs + HTTPS
  'img-src': ["'self'", "data:", "https:"],

  // Fonts: self only
  'font-src': ["'self'"],

  // API connections
  'connect-src': ["'self'", import.meta.env.VITE_API_URL],

  // Prevent framing (clickjacking protection)
  'frame-ancestors': ["'none'"],

  // Base URI restrictions
  'base-uri': ["'self'"],

  // Form submissions
  'form-action': ["'self'"],

  // Upgrade insecure requests
  'upgrade-insecure-requests': []
}

/**
 * Generate CSP header string
 */
export function generateCSPHeader(): string {
  return Object.entries(CSP_DIRECTIVES)
    .map(([directive, values]) =>
      values.length > 0
        ? `${directive} ${values.join(' ')}`
        : directive
    )
    .join('; ')
}
```

**Set in HTML**:
```html
<!-- index.html -->
<meta http-equiv="Content-Security-Policy" content="[CSP_STRING_HERE]">
```

---

## File Upload Security

See [Validation Guidelines](./06-VALIDATION.md) for complete file upload security patterns.

**Critical Checks**:
1. File size limits
2. MIME type validation
3. File extension validation
4. Content scanning
5. Filename sanitization

---

## URL & Navigation Security

```typescript
// utils/security/urlSecurity.ts
export class URLSecurity {
  /**
   * Prevent open redirect attacks
   */
  static isSafeRedirect(url: string): boolean {
    try {
      const parsed = new URL(url, window.location.origin)
      // Only allow same-origin redirects
      return parsed.origin === window.location.origin
    } catch {
      return false
    }
  }

  /**
   * Sanitize URL parameters
   */
  static sanitizeParams(params: Record<string, any>): Record<string, string> {
    const sanitized: Record<string, string> = {}

    for (const [key, value] of Object.entries(params)) {
      // Remove HTML/scripts from parameters
      const clean = String(value)
        .replace(/<[^>]*>/g, '')
        .replace(/javascript:/gi, '')
        .trim()

      sanitized[key] = clean
    }

    return sanitized
  }

  /**
   * Validate external URLs
   */
  static isValidExternalURL(url: string): boolean {
    // Whitelist of allowed domains
    const allowedDomains = [
      'github.com',
      'docs.vuejs.org',
      'vuetifyjs.com',
      'microsoft.com'
    ]

    try {
      const parsed = new URL(url)

      // Must be HTTPS
      if (parsed.protocol !== 'https:') {
        return false
      }

      // Must be in allowed domains
      return allowedDomains.some(domain =>
        parsed.hostname === domain || parsed.hostname.endsWith(`.${domain}`)
      )
    } catch {
      return false
    }
  }
}

// Usage in router
router.beforeEach((to, from, next) => {
  // Validate redirect parameter
  if (to.query.redirect && typeof to.query.redirect === 'string') {
    if (!URLSecurity.isSafeRedirect(to.query.redirect)) {
      console.error('🚨 Unsafe redirect blocked:', to.query.redirect)
      return next('/')
    }
  }

  // Sanitize all query parameters
  if (Object.keys(to.query).length > 0) {
    to.query = URLSecurity.sanitizeParams(to.query)
  }

  next()
})
```

---

## Rate Limiting (Client-Side)

```typescript
// composables/useRateLimiter.ts
export function useRateLimiter(
  key: string,
  maxRequests: number,
  windowMs: number
) {
  const requests = ref<Map<string, number[]>>(new Map())

  function checkLimit(): boolean {
    const now = Date.now()
    const userRequests = requests.value.get(key) || []

    // Filter requests within time window
    const recentRequests = userRequests.filter(time => now - time < windowMs)

    // Check if limit exceeded
    if (recentRequests.length >= maxRequests) {
      console.warn(`⚠️ Rate limit exceeded for: ${key}`)
      return false
    }

    // Add current request
    recentRequests.push(now)
    requests.value.set(key, recentRequests)

    return true
  }

  function reset(): void {
    requests.value.delete(key)
  }

  return {
    checkLimit,
    reset
  }
}

// Usage in component
const { checkLimit } = useRateLimiter('login', 5, 60000) // 5 attempts per minute

async function handleLogin() {
  if (!checkLimit()) {
    showError('Too many login attempts. Please wait.')
    return
  }

  // Proceed with login
}
```

---

## Secure State Management

See [State Management Guidelines](./04-STATE.md) for complete patterns.

**Key Principles**:
1. Never store sensitive data in plain text
2. Encrypt PII before storing
3. Clear sensitive data on logout
4. Implement auto-logout on inactivity
5. Use readonly for sensitive state

---

## Error Handling

```typescript
// services/security/errorHandler.ts
export class SecurityErrorHandler {
  /**
   * Handle errors without exposing sensitive information
   */
  static handleError(error: any): void {
    const sanitized = this.sanitizeError(error)

    // Log to monitoring (server-side)
    this.logToMonitoring(sanitized)

    // Show user-friendly message
    this.showUserMessage(this.getUserMessage(error))
  }

  /**
   * Remove sensitive data from errors
   */
  private static sanitizeError(error: any): any {
    const sanitized = { ...error }

    // Remove sensitive headers
    delete sanitized.config?.headers?.Authorization
    delete sanitized.config?.headers?.['X-CSRF-Token']
    delete sanitized.request?.headers
    delete sanitized.response?.config

    return {
      message: error.message,
      code: error.code,
      status: error.response?.status,
      timestamp: new Date().toISOString(),
      // Only include stack in development
      stack: import.meta.env.DEV ? error.stack : undefined
    }
  }

  /**
   * Get user-friendly error message
   */
  private static getUserMessage(error: any): string {
    // Production: generic messages only
    if (import.meta.env.PROD) {
      const statusMessages: Record<number, string> = {
        400: 'Invalid request. Please check your input.',
        401: 'Please log in to continue.',
        403: 'You don't have permission to do that.',
        404: 'The requested resource was not found.',
        429: 'Too many requests. Please slow down.',
        500: 'Something went wrong. Please try again later.'
      }

      return statusMessages[error.response?.status] ||
             'An error occurred. Please try again.'
    }

    // Development: show actual error
    return error.message
  }
}
```

---

## Security Monitoring

```typescript
// composables/useSecurityMonitoring.ts
interface SecurityEvent {
  type: 'SUSPICIOUS_INPUT' | 'RATE_LIMIT' | 'AUTH_FAILURE' | 'XSS_ATTEMPT'
  timestamp: number
  details: string
  severity: 'low' | 'medium' | 'high' | 'critical'
}

export function useSecurityMonitoring() {
  const events = ref<SecurityEvent[]>([])

  /**
   * Track security event
   */
  function trackEvent(event: Omit<SecurityEvent, 'timestamp'>): void {
    const fullEvent: SecurityEvent = {
      ...event,
      timestamp: Date.now()
    }

    events.value.push(fullEvent)

    // Log to console in development
    if (import.meta.env.DEV) {
      console.warn('🔒 Security Event:', fullEvent)
    }

    // Send to monitoring service
    sendToMonitoring(fullEvent)

    // Alert on critical events
    if (event.severity === 'critical') {
      alertSecurityTeam(fullEvent)
    }
  }

  /**
   * Detect suspicious patterns in user input
   */
  function detectSuspiciousInput(input: string): boolean {
    const patterns = {
      sql: /(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|--|;)/i,
      xss: /<script|javascript:|onerror=|onload=/i,
      path: /\.\.|\/\//,
      command: /&&|\||;|`|\$\(/
    }

    for (const [type, pattern] of Object.entries(patterns)) {
      if (pattern.test(input)) {
        trackEvent({
          type: 'SUSPICIOUS_INPUT',
          severity: 'high',
          details: `${type} injection attempt detected`
        })
        return true
      }
    }

    return false
  }

  return {
    trackEvent,
    detectSuspiciousInput,
    events: readonly(events)
  }
}
```

---

## Security Testing Checklist

Before marking any feature as complete:

### Authentication & Authorization
- [ ] Tokens stored securely (httpOnly cookies or encrypted sessionStorage)
- [ ] Session timeout implemented (15 minutes default)
- [ ] Password requirements enforced (min 8 chars, uppercase, lowercase, number, special)
- [ ] Account lockout after failed attempts
- [ ] Logout clears all sensitive data
- [ ] Route guards check authentication and authorization

### Input Validation
- [ ] All user inputs validated with Zod schemas
- [ ] All text inputs sanitized before display
- [ ] No `v-html` with user content (or sanitized with DOMPurify)
- [ ] File uploads validated (size, type, content)
- [ ] URL parameters sanitized
- [ ] SQL injection prevention (parameterized queries on backend)

### XSS Prevention
- [ ] No inline scripts in production
- [ ] CSP headers configured
- [ ] External URLs validated before use
- [ ] User content escaped automatically by Vue

### CSRF Protection
- [ ] CSRF tokens on all state-changing requests
- [ ] SameSite cookie attribute set
- [ ] Referer header validation on backend

### Data Protection
- [ ] Sensitive data encrypted in storage
- [ ] HTTPS enforced
- [ ] No secrets in client code
- [ ] PII minimized and protected
- [ ] Audit logs for sensitive operations

### Error Handling
- [ ] Generic error messages in production
- [ ] No sensitive data in error responses
- [ ] Security events logged
- [ ] Rate limiting on sensitive endpoints

---

## Quick Security Reference

| Threat | Protection | Implementation |
|--------|-----------|----------------|
| XSS | Sanitization | DOMPurify, no `v-html` |
| CSRF | Tokens | X-CSRF-Token header |
| SQL Injection | Validation | Zod schemas, parameterized queries |
| Open Redirect | URL validation | Same-origin check |
| Clickjacking | CSP | frame-ancestors: none |
| Session Hijacking | Secure cookies | httpOnly, Secure, SameSite |
| Brute Force | Rate limiting | Client & server limits |
| Data Exposure | Encryption | CryptoJS, HTTPS |

---

**Remember**: Security is not a feature, it's a requirement. Every feature must pass security review.
