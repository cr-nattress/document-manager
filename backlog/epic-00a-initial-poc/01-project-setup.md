# Story 01: Project Setup and Configuration

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Foundation
**Priority**: Critical
**Estimate**: 4 hours

---

## User Story

As a **developer**, I want to **set up the initial Vue 3 project with all necessary dependencies and configuration**, so that **I have a working development environment to build the POC**.

---

## Acceptance Criteria

- [ ] Vite + Vue 3 + TypeScript project initialized
- [ ] Vuetify 3 installed and configured with Material Design theme
- [ ] Pinia installed and configured for state management
- [ ] Vue Router installed and configured (basic routes)
- [ ] TypeScript strict mode enabled in tsconfig.json
- [ ] ESLint and Prettier configured with Vue 3 rules
- [ ] Project folder structure created as per architecture
- [ ] Development server runs without errors
- [ ] Hot module reload (HMR) working
- [ ] Build command produces production bundle successfully

---

## Technical Details

### Dependencies to Install
```json
{
  "dependencies": {
    "vue": "^3.4.0",
    "vuetify": "^3.5.0",
    "pinia": "^2.1.7",
    "vue-router": "^4.2.5",
    "@mdi/font": "^7.4.47"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "typescript": "^5.3.3",
    "vite": "^5.0.0",
    "vue-tsc": "^1.8.27",
    "eslint": "^8.56.0",
    "eslint-plugin-vue": "^9.20.0",
    "@typescript-eslint/parser": "^6.19.0",
    "prettier": "^3.2.0"
  }
}
```

### Folder Structure to Create
```
frontend/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   ├── folders/
│   │   ├── documents/
│   │   ├── search/
│   │   └── common/
│   ├── stores/
│   ├── types/
│   ├── data/
│   ├── views/
│   ├── App.vue
│   └── main.ts
├── public/
├── index.html
├── vite.config.ts
├── tsconfig.json
├── .eslintrc.cjs
└── package.json
```

### Vuetify Configuration (main.ts)
```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles'
import App from './App.vue'

const vuetify = createVuetify({
  components,
  directives,
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
        }
      }
    }
  }
})

const pinia = createPinia()
const app = createApp(App)

app.use(pinia)
app.use(vuetify)
app.mount('#app')
```

### TypeScript Configuration (tsconfig.json)
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

---

## Tasks

1. **Initialize Project**
   - Run `npm create vite@latest frontend -- --template vue-ts`
   - Navigate to project directory
   - Install base dependencies

2. **Install UI Dependencies**
   - Install Vuetify 3 and MDI icons
   - Install Pinia for state management
   - Install Vue Router

3. **Configure Vuetify**
   - Create Vuetify plugin configuration
   - Set up Material Design theme
   - Import Vuetify styles and MDI fonts

4. **Configure TypeScript**
   - Enable strict mode
   - Configure path aliases (@/ for src/)
   - Set up proper module resolution

5. **Set Up Linting**
   - Install ESLint with Vue plugin
   - Install Prettier
   - Configure .eslintrc.cjs
   - Configure .prettierrc

6. **Create Folder Structure**
   - Create all component folders
   - Create stores, types, data, views folders
   - Add placeholder index.ts files

7. **Test Setup**
   - Run `npm run dev` and verify server starts
   - Test hot reload by editing App.vue
   - Run `npm run build` and verify build succeeds
   - Check for TypeScript errors with `npm run type-check`

---

## Definition of Done

- [ ] Project runs with `npm run dev` on http://localhost:5173
- [ ] No console errors or warnings
- [ ] Hot module reload works when editing files
- [ ] TypeScript compilation has no errors
- [ ] ESLint reports no errors
- [ ] Production build completes successfully
- [ ] Folder structure matches architecture specification
- [ ] Basic "Hello World" appears in browser

---

## Testing

### Manual Testing Steps
1. Start dev server: `npm run dev`
2. Open browser to http://localhost:5173
3. Verify page loads and shows Vue + Vite welcome
4. Edit App.vue, save, verify HMR updates page
5. Run `npm run build`, verify dist/ folder created
6. Run `npm run type-check`, verify no TypeScript errors
7. Run `npm run lint`, verify no ESLint errors

---

## Dependencies

**Blocks**: All other stories (this is the foundation)
**Blocked By**: None

---

## Notes

- Use latest stable versions of all packages
- Verify Node.js version is 18+ before starting
- Document any configuration changes in code comments
- Keep package.json scripts standard (dev, build, lint, type-check)

---

## Resources

- **Vue 3 Docs**: https://vuejs.org
- **Vuetify 3 Docs**: https://vuetifyjs.com
- **Vite Docs**: https://vitejs.dev
- **Knowledge Base**: `/knowledgebase/vue3.md`, `/knowledgebase/vuetify3.md`
