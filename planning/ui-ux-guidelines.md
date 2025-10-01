# UI/UX Guidelines

## Overview

This document outlines the UI/UX design principles, patterns, and implementation guidelines for the Document Management System using Vue 3 and Vuetify 3.

---

## Design System

### Material Design 3
- Follow Material Design principles
- Use Vuetify 3 components
- Consistent spacing, typography, and elevation
- Responsive design for all screen sizes

### Color Palette

#### Light Theme
```
Primary:    #1976D2 (Blue)
Secondary:  #424242 (Dark Grey)
Accent:     #82B1FF (Light Blue)
Error:      #FF5252 (Red)
Info:       #2196F3 (Blue)
Success:    #4CAF50 (Green)
Warning:    #FB8C00 (Orange)
Background: #FFFFFF (White)
Surface:    #FFFFFF (White)
```

#### Dark Theme
```
Primary:    #2196F3 (Lighter Blue)
Secondary:  #616161 (Grey)
Accent:     #FF4081 (Pink)
Error:      #FF5252 (Red)
Info:       #2196F3 (Blue)
Success:    #4CAF50 (Green)
Warning:    #FB8C00 (Orange)
Background: #121212 (Dark)
Surface:    #1E1E1E (Dark Grey)
```

### Typography
- **Headers**: Roboto font family
- **Body**: Roboto font family
- **Font Sizes**:
  - h1: 96px / 6rem
  - h2: 60px / 3.75rem
  - h3: 48px / 3rem
  - h4: 34px / 2.125rem
  - h5: 24px / 1.5rem
  - h6: 20px / 1.25rem
  - body1: 16px / 1rem
  - body2: 14px / 0.875rem
  - caption: 12px / 0.75rem

### Spacing
- Use 8px grid system
- Common spacing values: 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px

---

## UI State Management

### Global UI Store
```typescript
// stores/ui/index.ts
- Theme management (light/dark)
- Layout state (drawer, rail, breadcrumbs)
- Global loading (with message)
- View caching (keep-alive)
- Modal management (centralized)
```

### Key UI States
1. **Theme**
   - Light/dark mode toggle
   - Persisted in localStorage
   - System preference detection
   - Smooth transitions

2. **Layout**
   - Navigation drawer (open/closed)
   - Rail mode for desktop
   - Breadcrumb navigation
   - Responsive breakpoints

3. **Loading**
   - Global loading overlay
   - Skeleton loaders
   - Progress indicators
   - Spinner components

4. **Notifications**
   - Success messages (green)
   - Error messages (red)
   - Warning messages (orange)
   - Info messages (blue)
   - Auto-dismiss after 5 seconds
   - Action buttons (optional)

---

## Component Patterns

### Feedback Components

#### Notifications (Snackbars)
```vue
<v-snackbar
  v-model="visible"
  :color="type"
  :timeout="5000"
  location="top right"
>
  <div class="d-flex align-center">
    <v-icon :icon="icon" class="mr-3" />
    <span>{{ message }}</span>
  </div>
  <template #actions>
    <v-btn icon="mdi-close" @click="close" />
  </template>
</v-snackbar>
```

**Types**:
- Success: `mdi-check-circle` icon, green
- Error: `mdi-alert-circle` icon, red
- Warning: `mdi-alert` icon, orange
- Info: `mdi-information` icon, blue

#### Loading States
1. **Global Loading**: Full-page overlay with spinner
2. **Component Loading**: Skeleton loaders
3. **Button Loading**: Spinner in button
4. **Progress**: Linear progress bar

#### Empty States
- Illustration or icon
- Clear message
- Action button (if applicable)
- Example: "No documents yet. Upload your first document!"

### Form Components

#### Secure Text Field
```vue
<v-text-field
  v-model="value"
  :label="label"
  :type="type"
  :rules="validationRules"
  validate-on="blur"
  variant="outlined"
  density="comfortable"
  :prepend-inner-icon="icon"
/>
```

**Features**:
- Real-time validation (debounced)
- Sanitization on input
- Password visibility toggle
- Character counter
- Helper text
- Error messages

#### File Upload
```vue
<v-file-input
  v-model="files"
  label="Select file"
  prepend-icon="mdi-paperclip"
  show-size
  :rules="fileRules"
  accept=".pdf,.doc,.docx,.xls,.xlsx"
/>
```

**Validation**:
- File type checking
- File size limits
- Multiple file support
- Drag-and-drop zone

### Modal Management

#### Centralized Modal System
```typescript
// Usage
uiStore.openModal('confirm-dialog', {
  title: 'Delete Document',
  message: 'Are you sure?',
  onConfirm: handleDelete
})
```

**Available Modals**:
- Confirm Dialog
- Upload Dialog
- Edit Dialog
- Error Dialog
- Info Dialog

---

## Responsive Design

### Breakpoints
```
xs:  0-600px   (Mobile portrait)
sm:  600-960px (Mobile landscape / small tablet)
md:  960-1264px (Tablet)
lg:  1264-1904px (Desktop)
xl:  1904px+ (Large desktop)
```

### Responsive Patterns

#### Navigation
- **Mobile (xs)**: Bottom navigation or hamburger menu
- **Tablet (sm-md)**: Side drawer with overlay
- **Desktop (lg-xl)**: Persistent drawer or rail

#### Data Display
- **Mobile**: Card list view
- **Tablet**: 2-column grid or table
- **Desktop**: Full data table with all columns

#### Forms
- **Mobile**: Single column, full width
- **Tablet**: Single column, max-width 600px
- **Desktop**: Two columns (optional)

### Touch Targets
- Minimum size: 44x44px (WCAG AAA)
- Comfortable spacing between targets
- Increased padding on mobile

---

## Accessibility (WCAG AA)

### Requirements
- [ ] Color contrast ratio ≥ 4.5:1 for text
- [ ] Color contrast ratio ≥ 3:1 for UI components
- [ ] Keyboard navigation support
- [ ] ARIA labels on all interactive elements
- [ ] Focus indicators visible
- [ ] Screen reader support
- [ ] Reduced motion support

### Implementation

#### ARIA Labels
```vue
<v-btn
  icon="mdi-delete"
  aria-label="Delete document"
  @click="handleDelete"
/>
```

#### Focus Management
```typescript
// composables/ui/useFocusTrap.ts
- Trap focus within modals
- Return focus on close
- Tab navigation within container
```

#### Keyboard Navigation
```vue
<div
  role="button"
  tabindex="0"
  @click="handleClick"
  @keydown.enter="handleClick"
  @keydown.space="handleClick"
>
  Interactive element
</div>
```

#### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Animation Guidelines

### Transitions
- **Duration**: 200-300ms for small UI changes
- **Easing**: `cubic-bezier(0.4, 0.0, 0.2, 1)` (standard)
- **Page transitions**: Fade or slide (300ms)

### Micro-interactions
- Button hover: Scale 1.02
- Card hover: Elevation increase
- Icon animations: Rotate or bounce

### Loading Animations
- Skeleton loaders: Shimmer effect
- Spinners: Rotate 360° in 1s
- Progress bars: Smooth animation

---

## Component Library

### Common Components

#### Cards
```vue
<v-card elevation="2" rounded="lg">
  <v-card-title>Title</v-card-title>
  <v-card-text>Content</v-card-text>
  <v-card-actions>
    <v-btn>Action</v-btn>
  </v-card-actions>
</v-card>
```

#### Lists
```vue
<v-list>
  <v-list-item
    v-for="item in items"
    :key="item.id"
    @click="handleClick(item)"
  >
    <template #prepend>
      <v-icon :icon="item.icon" />
    </template>
    <v-list-item-title>{{ item.title }}</v-list-item-title>
    <v-list-item-subtitle>{{ item.subtitle }}</v-list-item-subtitle>
  </v-list-item>
</v-list>
```

#### Data Tables
```vue
<v-data-table
  :headers="headers"
  :items="items"
  :loading="loading"
  :search="search"
>
  <template #item.actions="{ item }">
    <v-btn icon="mdi-pencil" size="small" />
    <v-btn icon="mdi-delete" size="small" />
  </template>
</v-data-table>
```

#### Dialogs
```vue
<v-dialog v-model="dialog" max-width="600" persistent>
  <v-card>
    <v-card-title>Dialog Title</v-card-title>
    <v-card-text>Content</v-card-text>
    <v-card-actions>
      <v-spacer />
      <v-btn @click="dialog = false">Cancel</v-btn>
      <v-btn color="primary" @click="handleConfirm">Confirm</v-btn>
    </v-card-actions>
  </v-card>
</v-dialog>
```

---

## Performance Guidelines

### Optimization Strategies
1. **Code Splitting**
   - Lazy load routes
   - Lazy load heavy components
   - Dynamic imports for modals

2. **Image Optimization**
   - WebP format
   - Responsive images
   - Lazy loading

3. **Component Performance**
   - Use `v-show` for frequent toggling
   - Use `v-if` for conditional rendering
   - Memoize computed properties
   - Debounce user inputs

4. **Virtual Scrolling**
   - For long lists (>100 items)
   - Vuetify v-virtual-scroll

### Performance Budgets
- First Contentful Paint: < 1.5s
- Time to Interactive: < 3s
- Largest Contentful Paint: < 2.5s
- Cumulative Layout Shift: < 0.1
- Total Bundle Size: < 250KB (gzipped)

---

## Testing UI/UX

### Visual Testing
- [ ] Test light and dark themes
- [ ] Test all breakpoints (xs, sm, md, lg, xl)
- [ ] Test touch interactions
- [ ] Test keyboard navigation
- [ ] Screenshot tests (Playwright)

### Accessibility Testing
- [ ] Automated tests (axe-playwright)
- [ ] Manual screen reader testing
- [ ] Keyboard navigation testing
- [ ] Color contrast validation
- [ ] Focus indicator visibility

### User Testing
- [ ] Task completion rates
- [ ] Time on task
- [ ] Error rates
- [ ] User satisfaction scores
- [ ] Accessibility feedback

---

## Best Practices Checklist

### Design
- [ ] Consistent spacing throughout
- [ ] Appropriate color usage (semantic colors)
- [ ] Clear visual hierarchy
- [ ] Adequate whitespace
- [ ] Responsive on all devices

### Usability
- [ ] Clear call-to-action buttons
- [ ] Helpful error messages
- [ ] Progress indicators for long operations
- [ ] Confirmation dialogs for destructive actions
- [ ] Consistent navigation

### Accessibility
- [ ] WCAG AA compliance
- [ ] Keyboard navigation
- [ ] Screen reader support
- [ ] Color contrast
- [ ] Focus indicators

### Performance
- [ ] Fast load times
- [ ] Smooth animations (60fps)
- [ ] No layout shifts
- [ ] Lazy loading implemented
- [ ] Bundle size optimized

---

## Related Documents
- [Architecture](./architecture.md)
- [Technical Specification](./technical-spec.md)
- [Testing Strategy](./testing-strategy.md)
- [Security](./security.md)

## Prompt References
- [UI/UX Prompt](../prompts/10-UI-UX.md)
- [Components Prompt](../prompts/03-COMPONENTS.md)
- [Testing Prompt](../prompts/08-TESTING.md)
