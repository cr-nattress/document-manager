# Build & Deployment

**Area**: Build Configuration, Environment Variables, Security Headers, CI/CD
**Related**: [MASTER](./MASTER.md), [Security](./02-SECURITY.md), [Testing](./08-TESTING.md)
**Last Updated**: 2025-09-30

---

## Overview

This guide covers secure build configuration, environment setup, deployment strategies, and production hardening for the Document Management System.

---

## Environment Variables

### Never Commit Secrets

```bash
# .env.example (commit this)
VITE_API_BASE_URL=https://api.example.com
VITE_APP_NAME=Document Manager
VITE_MAX_FILE_SIZE=104857600
VITE_ALLOWED_FILE_TYPES=.pdf,.doc,.docx,.xls,.xlsx

# .env (DO NOT commit this)
VITE_API_BASE_URL=https://api.production.com
VITE_ENCRYPTION_KEY=your-secret-key-here
VITE_SENTRY_DSN=your-sentry-dsn
```

### Environment Variable Validation

```typescript
// config/env.ts
import { z } from 'zod'

const envSchema = z.object({
  VITE_API_BASE_URL: z.string().url(),
  VITE_APP_NAME: z.string().min(1),
  VITE_MAX_FILE_SIZE: z.string().transform(Number).pipe(z.number().positive()),
  VITE_ALLOWED_FILE_TYPES: z.string(),
  VITE_ENCRYPTION_KEY: z.string().min(32).optional(),
  VITE_SENTRY_DSN: z.string().url().optional()
})

export type Env = z.infer<typeof envSchema>

function validateEnv(): Env {
  try {
    return envSchema.parse(import.meta.env)
  } catch (error) {
    console.error('Invalid environment variables:', error)
    throw new Error('Environment validation failed')
  }
}

export const env = validateEnv()
```

### Using Environment Variables

```typescript
// main.ts
import { env } from '@/config/env'

// ✅ Good - Use validated env
const apiUrl = env.VITE_API_BASE_URL

// ❌ Bad - Direct access without validation
const apiUrl = import.meta.env.VITE_API_BASE_URL
```

---

## Build Configuration

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import vuetify from 'vite-plugin-vuetify'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      vue(),
      vuetify({ autoImport: true })
    ],

    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },

    // Security headers via meta tags
    server: {
      port: 3000,
      strictPort: true,
      headers: {
        // Development security headers
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block'
      }
    },

    build: {
      // Production optimizations
      target: 'es2020',
      minify: 'terser',
      terserOptions: {
        compress: {
          drop_console: true, // Remove console.log in production
          drop_debugger: true
        }
      },
      rollupOptions: {
        output: {
          // Code splitting
          manualChunks: {
            'vue-vendor': ['vue', 'vue-router', 'pinia'],
            'vuetify': ['vuetify'],
            'utils': ['zod', 'dompurify']
          }
        }
      },
      // Source maps for error tracking (not exposed to public)
      sourcemap: mode === 'production' ? 'hidden' : true,

      // Security: Don't inline small assets (prevent data URIs)
      assetsInlineLimit: 0
    },

    // Define environment variables
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString())
    }
  }
})
```

---

## Content Security Policy (CSP)

### CSP Configuration

```typescript
// constants/security/csp.ts

export const CSP_DIRECTIVES = {
  'default-src': ["'self'"],
  'script-src': [
    "'self'",
    "'strict-dynamic'",
    // Nonce will be added at runtime
  ],
  'style-src': [
    "'self'",
    "'unsafe-inline'", // Required for Vuetify
    'https://fonts.googleapis.com'
  ],
  'img-src': [
    "'self'",
    'data:', // For inline images
    'https:' // For external images
  ],
  'font-src': [
    "'self'",
    'https://fonts.gstatic.com'
  ],
  'connect-src': [
    "'self'",
    process.env.VITE_API_BASE_URL || ''
  ],
  'frame-ancestors': ["'none'"],
  'base-uri': ["'self'"],
  'form-action': ["'self'"],
  'upgrade-insecure-requests': []
}

export function generateCSP(): string {
  return Object.entries(CSP_DIRECTIVES)
    .map(([directive, values]) => {
      if (values.length === 0) return directive
      return `${directive} ${values.join(' ')}`
    })
    .join('; ')
}
```

### Inject CSP into HTML

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- Security Headers -->
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'strict-dynamic'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://api.example.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests">
  <meta http-equiv="X-Content-Type-Options" content="nosniff">
  <meta http-equiv="X-Frame-Options" content="DENY">
  <meta http-equiv="X-XSS-Protection" content="1; mode=block">
  <meta name="referrer" content="strict-origin-when-cross-origin">

  <title>Document Manager</title>
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

---

## Production Security Headers

### Server-Side Headers (Backend)

These headers should be configured on your backend/reverse proxy:

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name app.example.com;

    # SSL Configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # CSP Header
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'strict-dynamic'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://api.example.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests" always;

    location / {
        root /var/www/app/dist;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass https://api.example.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run security audit
        run: npm audit --audit-level=moderate

      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  test:
    runs-on: ubuntu-latest
    needs: security-scan
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run type check
        run: npm run type-check

      - name: Run unit tests
        run: npm run test:unit

      - name: Run security tests
        run: npm run test:security

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build production
        env:
          VITE_API_BASE_URL: ${{ secrets.VITE_API_BASE_URL }}
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
          retention-days: 7

  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: dist
          path: dist/

      - name: Deploy to production
        # Add your deployment steps here
        run: echo "Deploy to Azure Static Web Apps"
```

---

## Environment-Specific Builds

### Multiple Environment Configuration

```typescript
// config/environments.ts

interface EnvironmentConfig {
  apiBaseUrl: string
  enableDebug: boolean
  enableAnalytics: boolean
  logLevel: 'debug' | 'info' | 'warn' | 'error'
}

const environments: Record<string, EnvironmentConfig> = {
  development: {
    apiBaseUrl: 'http://localhost:7071/api',
    enableDebug: true,
    enableAnalytics: false,
    logLevel: 'debug'
  },

  staging: {
    apiBaseUrl: 'https://api-staging.example.com',
    enableDebug: true,
    enableAnalytics: false,
    logLevel: 'info'
  },

  production: {
    apiBaseUrl: 'https://api.example.com',
    enableDebug: false,
    enableAnalytics: true,
    logLevel: 'error'
  }
}

export function getConfig(): EnvironmentConfig {
  const mode = import.meta.env.MODE || 'development'
  return environments[mode] || environments.development
}
```

---

## Build Scripts

### Package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "npm run type-check && vite build",
    "build:staging": "vite build --mode staging",
    "build:production": "vite build --mode production",
    "preview": "vite preview",
    "type-check": "vue-tsc --noEmit",
    "lint": "eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix",
    "test:unit": "vitest run",
    "test:e2e": "playwright test",
    "test:security": "npm audit && npm run test:xss && npm run test:auth",
    "test:xss": "vitest run --grep 'XSS|sanitize'",
    "test:auth": "vitest run --grep 'auth|csrf|token'",
    "analyze": "vite build --mode analyze",
    "clean": "rm -rf dist node_modules",
    "prebuild": "npm run clean && npm ci"
  }
}
```

---

## Docker Deployment

### Production Dockerfile

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Build
RUN npm run build

# Production image
FROM nginx:alpine

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Security: Run as non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

---

## Performance Optimization

### Code Splitting

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: () => import('@/views/HomeView.vue')
    },
    {
      path: '/documents',
      name: 'Documents',
      component: () => import('@/views/DocumentsView.vue')
    },
    {
      path: '/admin',
      name: 'Admin',
      component: () => import('@/views/AdminView.vue'),
      meta: { requiresAuth: true, role: 'admin' }
    }
  ]
})
```

### Asset Optimization

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router', 'pinia'],
          'vuetify': ['vuetify'],
          'utils': ['zod', 'dompurify'],
          'icons': ['@mdi/font']
        }
      }
    }
  }
})
```

---

## Monitoring & Error Tracking

### Sentry Integration

```typescript
// main.ts
import * as Sentry from '@sentry/vue'
import { createApp } from 'vue'
import App from './App.vue'

const app = createApp(App)

// Only enable Sentry in production
if (import.meta.env.PROD) {
  Sentry.init({
    app,
    dsn: import.meta.env.VITE_SENTRY_DSN,
    environment: import.meta.env.MODE,
    integrations: [
      new Sentry.BrowserTracing({
        routingInstrumentation: Sentry.vueRouterInstrumentation(router)
      }),
      new Sentry.Replay()
    ],
    tracesSampleRate: 0.1,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
    beforeSend(event) {
      // Don't send events with sensitive data
      if (event.request) {
        delete event.request.cookies
        delete event.request.headers
      }
      return event
    }
  })
}

app.mount('#app')
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing
- [ ] Security audit clean (`npm audit`)
- [ ] No vulnerable dependencies
- [ ] Environment variables validated
- [ ] CSP headers configured
- [ ] HTTPS enforced
- [ ] Rate limiting active
- [ ] Error tracking enabled
- [ ] Build size optimized
- [ ] Source maps hidden/separate

### Post-Deployment

- [ ] Health check passing
- [ ] Security headers verified
- [ ] HTTPS working correctly
- [ ] CSP not blocking resources
- [ ] Error tracking receiving events
- [ ] Performance metrics acceptable
- [ ] No console errors
- [ ] Authentication working
- [ ] CSRF protection active

---

## Related Guidelines

- **For security configuration**: See [Security](./02-SECURITY.md)
- **For testing before deployment**: See [Testing](./08-TESTING.md)
- **For environment types**: See [TypeScript](./07-TYPESCRIPT.md)
- **For API configuration**: See [API](./05-API.md)

---

**Remember**: Production security is non-negotiable. Verify all security measures before every deployment.
