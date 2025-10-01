# Story 02: Core Layout and Responsive Shell

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Feature
**Priority**: Critical
**Estimate**: 8 hours

---

## User Story

As a **user**, I want to **see a responsive application layout with navigation**, so that **I can easily navigate the application on both desktop and mobile devices**.

---

## Acceptance Criteria

- [ ] App layout with header, navigation drawer, and main content area
- [ ] Top app bar with app title, search bar placeholder, and user menu
- [ ] Side navigation drawer with folder tree placeholder
- [ ] Responsive behavior: permanent drawer on desktop, collapsible on mobile
- [ ] Hamburger menu icon on mobile to toggle drawer
- [ ] Light/dark theme toggle in app bar
- [ ] Footer with app version and links (optional)
- [ ] Layout works on breakpoints: xs, sm, md, lg, xl
- [ ] Touch-friendly spacing on mobile (minimum 48px touch targets)
- [ ] Smooth transitions when opening/closing drawer

---

## Technical Details

### Components to Create

#### 1. AppLayout.vue
```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useDisplay } from 'vuetify'
import AppBar from '@/components/layout/AppBar.vue'
import NavigationDrawer from '@/components/layout/NavigationDrawer.vue'

const { mobile } = useDisplay()
const drawer = ref(!mobile.value)
const rail = ref(false)

function toggleDrawer() {
  drawer.value = !drawer.value
}

function toggleRail() {
  rail.value = !rail.value
}
</script>

<template>
  <v-app>
    <AppBar
      :drawer="drawer"
      @toggle-drawer="toggleDrawer"
    />

    <NavigationDrawer
      v-model="drawer"
      :rail="rail"
      @toggle-rail="toggleRail"
    />

    <v-main>
      <v-container fluid>
        <router-view />
      </v-container>
    </v-main>
  </v-app>
</template>
```

#### 2. AppBar.vue
```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useTheme } from 'vuetify'

interface Props {
  drawer: boolean
}

interface Emits {
  (e: 'toggle-drawer'): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const theme = useTheme()
const isDark = ref(theme.global.current.value.dark)

function toggleTheme() {
  theme.global.name.value = isDark.value ? 'light' : 'dark'
  isDark.value = !isDark.value
}
</script>

<template>
  <v-app-bar
    color="primary"
    prominent
    elevation="2"
  >
    <v-app-bar-nav-icon @click="emit('toggle-drawer')" />

    <v-toolbar-title>
      <v-icon icon="mdi-folder-multiple" class="mr-2" />
      Document Manager
    </v-toolbar-title>

    <v-spacer />

    <!-- Search bar placeholder -->
    <v-text-field
      prepend-inner-icon="mdi-magnify"
      placeholder="Search documents..."
      variant="outlined"
      density="compact"
      hide-details
      single-line
      class="mx-4 d-none d-md-flex"
      style="max-width: 400px"
    />

    <!-- Theme toggle -->
    <v-btn
      :icon="isDark ? 'mdi-weather-sunny' : 'mdi-weather-night'"
      @click="toggleTheme"
    />

    <!-- User menu -->
    <v-btn icon="mdi-account-circle" class="ml-2" />
  </v-app-bar>
</template>
```

#### 3. NavigationDrawer.vue
```vue
<script setup lang="ts">
interface Props {
  rail?: boolean
}

interface Emits {
  (e: 'toggle-rail'): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const menuItems = [
  { title: 'Dashboard', icon: 'mdi-view-dashboard', to: '/' },
  { title: 'Browse', icon: 'mdi-folder-open', to: '/browse' },
  { title: 'Search', icon: 'mdi-magnify', to: '/search' },
  { title: 'Upload', icon: 'mdi-upload', to: '/upload' },
]
</script>

<template>
  <v-navigation-drawer
    :rail="rail"
    permanent
    @click="rail && emit('toggle-rail')"
  >
    <v-list-item
      prepend-icon="mdi-folder-multiple"
      title="Document Manager"
      subtitle="POC Version"
      nav
    >
      <template #append>
        <v-btn
          icon="mdi-chevron-left"
          variant="text"
          size="small"
          @click.stop="emit('toggle-rail')"
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

    <v-divider />

    <v-list density="compact" nav>
      <v-list-item
        prepend-icon="mdi-cog"
        title="Settings"
      />
      <v-list-item
        prepend-icon="mdi-help-circle"
        title="Help"
      />
    </v-list>

    <template #append>
      <div class="pa-2">
        <v-btn
          block
          prepend-icon="mdi-folder-plus"
          variant="tonal"
          size="small"
        >
          New Folder
        </v-btn>
      </div>
    </template>
  </v-navigation-drawer>
</template>
```

### Responsive Breakpoints
- **xs**: < 600px (mobile)
- **sm**: 600px - 960px (tablet portrait)
- **md**: 960px - 1280px (tablet landscape/small desktop)
- **lg**: 1280px - 1920px (desktop)
- **xl**: > 1920px (large desktop)

### Drawer Behavior
- **Desktop (md+)**: Permanent drawer, collapsible to rail mode
- **Mobile (xs-sm)**: Temporary drawer, closes on item click
- **Tablet (sm-md)**: User preference, defaults to collapsed

---

## Tasks

1. **Create AppLayout Component**
   - Set up v-app with app bar and drawer
   - Add router-view for main content
   - Implement drawer state management
   - Add responsive behavior

2. **Create AppBar Component**
   - Add navigation icon for drawer toggle
   - Add app title with icon
   - Add search bar placeholder (desktop only)
   - Add theme toggle button
   - Add user menu button

3. **Create NavigationDrawer Component**
   - Add header with app info
   - Add navigation menu items
   - Add rail mode toggle
   - Add "New Folder" button at bottom
   - Add settings/help links

4. **Set Up Routing**
   - Create basic router configuration
   - Add placeholder views (Dashboard, Browse, Search)
   - Configure router in main.ts

5. **Implement Theme Toggle**
   - Use Vuetify's useTheme composable
   - Toggle between light and dark themes
   - Persist preference in localStorage (optional)

6. **Test Responsive Behavior**
   - Test on all breakpoints using browser dev tools
   - Verify drawer behavior on mobile
   - Check touch target sizes
   - Test theme toggle

---

## Definition of Done

- [ ] AppLayout renders with all sub-components
- [ ] App bar displays title, search, and icons
- [ ] Navigation drawer opens/closes on hamburger click
- [ ] Drawer is permanent on desktop, temporary on mobile
- [ ] Rail mode works on desktop
- [ ] Theme toggle switches between light and dark
- [ ] Navigation menu items render correctly
- [ ] Responsive at all breakpoints (xs, sm, md, lg, xl)
- [ ] No layout shift or overflow issues
- [ ] Touch targets are minimum 48px on mobile

---

## Testing

### Manual Testing Steps

**Desktop (lg/xl)**:
1. Open app in desktop resolution (1280px+)
2. Verify drawer is permanently visible
3. Click rail toggle, verify drawer collapses to rail
4. Click nav items, verify content area updates
5. Click theme toggle, verify theme changes

**Tablet (sm/md)**:
1. Resize to tablet resolution (600-1280px)
2. Verify drawer behavior is appropriate
3. Test navigation
4. Test theme toggle

**Mobile (xs)**:
1. Resize to mobile resolution (<600px)
2. Verify drawer is hidden by default
3. Click hamburger, verify drawer slides in
4. Click nav item, verify drawer closes
5. Verify search bar is hidden
6. Test touch interaction with minimum 48px targets
7. Test theme toggle

**Theme Testing**:
1. Click theme toggle
2. Verify colors change throughout app
3. Toggle back to light mode
4. Verify all components use correct theme colors

---

## Dependencies

**Depends On**: Story 01 (Project Setup)
**Blocks**: All feature stories (layout is required)

---

## Notes

- Use Vuetify's built-in responsive utilities (`useDisplay`)
- Follow Material Design guidelines for spacing and touch targets
- Consider adding breadcrumb navigation in future iterations
- Footer is optional for POC, can be added later

---

## Resources

- **Vuetify Layout**: https://vuetifyjs.com/en/components/application/
- **Vuetify App Bar**: https://vuetifyjs.com/en/components/app-bars/
- **Vuetify Navigation Drawer**: https://vuetifyjs.com/en/components/navigation-drawers/
- **Knowledge Base**: `/knowledgebase/vuetify3.md`
