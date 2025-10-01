# Epic 000a: Initial POC - UI Only

**Epic Type**: Foundation / POC
**Status**: Not Started
**Priority**: Critical
**Timeline**: 1-2 weeks

---

## 📋 Overview

Create a minimal Proof of Concept (POC) that demonstrates the Document Management System UI with mock data. This POC focuses exclusively on the frontend to validate design decisions, user flows, and component architecture before backend integration.

### Goals
- ✅ Validate UI/UX design and user flows
- ✅ Prove Vue 3 + Vuetify 3 + Pinia architecture
- ✅ Test responsive design on mobile and desktop
- ✅ Establish component patterns and reusable components
- ✅ Create foundation for full implementation

### Non-Goals (Out of Scope)
- ❌ Backend API integration
- ❌ Real file uploads/downloads
- ❌ Azure service integration
- ❌ Authentication/authorization
- ❌ Database persistence
- ❌ Production deployment

---

## 🎯 Success Criteria

### Must Have
1. Working folder tree navigation with mock data
2. Document list view with mock documents
3. Upload dialog UI (no actual upload)
4. Document detail view/preview mockup
5. Search/filter interface
6. Responsive layout (mobile + desktop)
7. Basic metadata and tag management UI

### Should Have
1. Folder creation/edit dialogs
2. Document edit metadata dialog
3. Loading states and animations
4. Error state mockups
5. Empty state designs

### Nice to Have
1. Drag-and-drop file upload zone
2. Document type icons
3. Breadcrumb navigation
4. Context menus
5. Keyboard shortcuts

---

## 🏗️ Architecture

### Technology Stack
- **Framework**: Vue 3 with Composition API + `<script setup>`
- **UI Library**: Vuetify 3 (Material Design)
- **State Management**: Pinia stores with mock data
- **Routing**: Vue Router (if multi-page)
- **Build Tool**: Vite
- **Language**: TypeScript (strict mode)

### Project Structure
```
frontend/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── AppLayout.vue          # Main app layout
│   │   │   ├── AppBar.vue             # Top navigation bar
│   │   │   ├── NavigationDrawer.vue   # Side navigation
│   │   │   └── Footer.vue             # Footer (optional)
│   │   ├── folders/
│   │   │   ├── FolderTree.vue         # Folder tree component
│   │   │   ├── FolderNode.vue         # Single folder node
│   │   │   └── CreateFolderDialog.vue # New folder dialog
│   │   ├── documents/
│   │   │   ├── DocumentList.vue       # Document list table
│   │   │   ├── DocumentCard.vue       # Document card view
│   │   │   ├── DocumentPreview.vue    # Preview dialog
│   │   │   ├── UploadDialog.vue       # Upload UI mockup
│   │   │   └── EditMetadataDialog.vue # Edit metadata
│   │   ├── search/
│   │   │   ├── SearchBar.vue          # Search input
│   │   │   ├── SearchFilters.vue      # Filter panel
│   │   │   └── SearchResults.vue      # Results display
│   │   └── common/
│   │       ├── EmptyState.vue         # Empty state component
│   │       ├── LoadingSpinner.vue     # Loading indicator
│   │       └── ErrorMessage.vue       # Error display
│   ├── stores/
│   │   ├── documentStore.ts           # Mock document store
│   │   ├── folderStore.ts             # Mock folder store
│   │   ├── searchStore.ts             # Search state store
│   │   └── uiStore.ts                 # UI state (drawer, dialogs)
│   ├── types/
│   │   ├── document.ts                # Document types
│   │   ├── folder.ts                  # Folder types
│   │   └── common.ts                  # Common types
│   ├── data/
│   │   ├── mockDocuments.ts           # Mock document data
│   │   └── mockFolders.ts             # Mock folder data
│   ├── views/
│   │   ├── DashboardView.vue          # Main dashboard
│   │   ├── BrowseView.vue             # Browse documents
│   │   └── SearchView.vue             # Search page
│   ├── App.vue
│   └── main.ts
├── public/
├── index.html
├── vite.config.ts
├── tsconfig.json
└── package.json
```

---

## 📦 Features Breakdown

### Feature 1: Folder Tree Navigation
**Description**: Hierarchical folder tree with expand/collapse, selection, and navigation

**Components**:
- `FolderTree.vue` - Main tree container
- `FolderNode.vue` - Recursive folder node

**Mock Data**:
```typescript
const mockFolders = [
  {
    id: 'root',
    name: 'Documents',
    parentId: null,
    children: [
      {
        id: 'folder-1',
        name: 'Projects',
        parentId: 'root',
        documentCount: 15,
        children: [...]
      },
      {
        id: 'folder-2',
        name: 'Finance',
        parentId: 'root',
        documentCount: 8,
        children: []
      }
    ]
  }
]
```

**User Actions**:
- Click to select folder
- Expand/collapse folders
- Visual indication of selected folder
- Show document count badge

**Time Estimate**: 8 hours

---

### Feature 2: Document List View
**Description**: Table/grid view of documents with sorting, filtering, and actions

**Components**:
- `DocumentList.vue` - Main list with v-data-table
- `DocumentCard.vue` - Card view (alternative)

**Mock Data**:
```typescript
const mockDocuments = [
  {
    id: 'doc-1',
    name: 'Q4 Financial Report.pdf',
    folderId: 'folder-2',
    size: 2457600, // bytes
    contentType: 'application/pdf',
    uploadedAt: '2025-09-15T10:30:00Z',
    modifiedAt: '2025-09-20T14:22:00Z',
    metadata: {
      category: 'Financial',
      year: '2024',
      quarter: 'Q4'
    },
    tags: ['finance', 'report', 'quarterly']
  }
  // ... more documents
]
```

**Features**:
- Sortable columns (name, size, date)
- Search/filter documents
- Action buttons (view, download, edit, delete)
- Empty state when no documents
- Loading state skeleton

**Time Estimate**: 12 hours

---

### Feature 3: Upload Dialog (UI Only)
**Description**: Document upload interface with drag-and-drop zone and metadata entry

**Components**:
- `UploadDialog.vue` - Upload dialog

**Features**:
- File selection via button or drag-and-drop
- Display selected file name and size
- Metadata entry form (name, tags, custom fields)
- Progress bar simulation (visual only)
- Mock success/error messages

**Mock Flow**:
1. User selects file
2. Shows file preview/info
3. User enters metadata
4. Clicks "Upload"
5. Shows animated progress bar
6. Displays success message
7. Closes dialog
8. Document appears in list (from mock store)

**Time Estimate**: 10 hours

---

### Feature 4: Document Preview/Details
**Description**: View document details, metadata, and preview placeholder

**Components**:
- `DocumentPreview.vue` - Preview dialog
- Show document metadata
- Display tags
- Preview placeholder (e.g., PDF icon, "Preview not available in POC")
- Action buttons (download, edit, delete)

**Time Estimate**: 6 hours

---

### Feature 5: Search and Filter
**Description**: Search bar with live filtering and advanced filters

**Components**:
- `SearchBar.vue` - Header search input
- `SearchFilters.vue` - Advanced filter panel
- `SearchResults.vue` - Results display

**Features**:
- Live search as user types (debounced)
- Filter by folder, tags, date range, file type
- Display search results count
- Clear filters button
- No results state

**Mock Implementation**:
- Filter mock documents array by search term
- Simple string matching on name, tags, metadata

**Time Estimate**: 8 hours

---

### Feature 6: Responsive Layout
**Description**: Mobile-friendly responsive design with drawer, breakpoints

**Components**:
- `AppLayout.vue` - Responsive container
- `AppBar.vue` - Top bar with hamburger menu
- `NavigationDrawer.vue` - Collapsible side drawer

**Features**:
- Desktop: Permanent side drawer with folder tree
- Mobile: Collapsible hamburger menu
- Responsive breakpoints (xs, sm, md, lg, xl)
- Touch-friendly buttons and spacing on mobile
- Optimized layout for tablets

**Time Estimate**: 6 hours

---

### Feature 7: Metadata and Tag Management
**Description**: UI for viewing and editing document metadata and tags

**Components**:
- `EditMetadataDialog.vue` - Metadata editor
- Tag input with autocomplete
- Custom metadata key-value pairs
- Save/cancel actions

**Mock Implementation**:
- Edit mock document in Pinia store
- Tag autocomplete from existing tags in mock data

**Time Estimate**: 6 hours

---

### Feature 8: Folder Management
**Description**: Create, edit, rename, delete folders (UI only)

**Components**:
- `CreateFolderDialog.vue` - New folder dialog
- `EditFolderDialog.vue` - Rename folder dialog
- `DeleteConfirmDialog.vue` - Delete confirmation

**Features**:
- Select parent folder from tree
- Enter folder name and description
- Show folder path preview
- Validation (e.g., duplicate names)
- Mock folder creation in store

**Time Estimate**: 6 hours

---

### Feature 9: UI States (Loading, Empty, Error)
**Description**: Consistent UI states across all components

**Components**:
- `LoadingSpinner.vue` - Loading indicator
- `EmptyState.vue` - No data states
- `ErrorMessage.vue` - Error displays

**States to Mock**:
- Loading: Skeleton loaders, spinners
- Empty: "No documents", "No folders", "No results"
- Error: "Failed to load", "Upload failed"
- Success: Snackbar notifications

**Time Estimate**: 4 hours

---

## 📊 Mock Data Strategy

### Folder Mock Data (20-30 folders)
- Root folder with 3-4 main categories
- 2-3 levels of nesting
- Realistic folder names (Projects, Finance, HR, Legal, Marketing)
- Document counts per folder

### Document Mock Data (50-100 documents)
- Various file types (PDF, DOCX, XLSX, JPG, PNG)
- Different sizes (KB to GB)
- Realistic names and metadata
- Mix of recent and old dates
- Various tag combinations

### Data Generation
```typescript
// data/mockFolders.ts
export const mockFolders: Folder[] = [
  { id: 'root', name: 'Documents', parentId: null, children: [...] },
  { id: 'projects', name: 'Projects', parentId: 'root', children: [...] },
  { id: 'finance', name: 'Finance', parentId: 'root', children: [...] },
  // ... more folders
]

// data/mockDocuments.ts
export const mockDocuments: Document[] = [
  {
    id: 'doc-1',
    name: 'Q4 Financial Report.pdf',
    folderId: 'finance',
    size: 2457600,
    contentType: 'application/pdf',
    uploadedAt: '2025-09-15T10:30:00Z',
    tags: ['finance', 'report', 'q4-2024']
  },
  // ... 50+ more documents
]
```

---

## 🎨 Design Guidelines

### Color Scheme
- Primary: Material Blue (#1976D2)
- Secondary: Material Grey (#424242)
- Success: Green (#4CAF50)
- Error: Red (#F44336)
- Warning: Orange (#FF9800)

### Typography
- Headings: Roboto Bold
- Body: Roboto Regular
- Monospace: Roboto Mono (for file sizes, dates)

### Spacing
- Use Vuetify spacing utilities (ma-4, pa-2, etc.)
- Consistent padding: 16px for cards, 8px for list items
- 8px grid system

### Icons
- Material Design Icons (MDI)
- Document icons by type
- Action icons (edit, delete, download, upload)

---

## 🧪 Testing Strategy

### Manual Testing Checklist
- [ ] Folder tree expands and collapses
- [ ] Documents display in list and card views
- [ ] Upload dialog opens and accepts "files"
- [ ] Search filters documents correctly
- [ ] Mobile layout works on small screens
- [ ] All dialogs open and close properly
- [ ] Loading states appear correctly
- [ ] Empty states show when no data
- [ ] Error messages display as expected
- [ ] Navigation works between views

### Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Chrome (Android)
- [ ] Mobile Safari (iOS)

---

## 📝 Implementation Plan

### Phase 1: Project Setup (Day 1 - 4 hours)
**Tasks**:
1. Initialize Vite + Vue 3 + TypeScript project
2. Install dependencies (Vuetify, Pinia, Vue Router)
3. Configure Vuetify plugin with theme
4. Set up TypeScript strict mode
5. Create folder structure
6. Configure ESLint and Prettier
7. Test hot reload and build

**Deliverable**: Working dev environment with "Hello World"

---

### Phase 2: Core Layout (Day 1-2 - 8 hours)
**Tasks**:
1. Create `AppLayout.vue` with Vuetify layout components
2. Implement `AppBar.vue` with app title and search
3. Implement `NavigationDrawer.vue` with responsive behavior
4. Set up basic routing (if needed)
5. Add theme toggle (light/dark)
6. Test on mobile and desktop breakpoints

**Deliverable**: Responsive app shell

---

### Phase 3: Mock Data & Stores (Day 2 - 4 hours)
**Tasks**:
1. Define TypeScript types (Document, Folder)
2. Create mock folder data (20 folders)
3. Create mock document data (50 documents)
4. Set up Pinia documentStore with mock data
5. Set up Pinia folderStore with mock data
6. Set up Pinia uiStore for UI state
7. Implement basic store actions (filter, search)

**Deliverable**: Working Pinia stores with mock data

---

### Phase 4: Folder Tree (Day 3 - 8 hours)
**Tasks**:
1. Create `FolderTree.vue` component
2. Create `FolderNode.vue` recursive component
3. Implement expand/collapse logic
4. Add folder selection (highlight selected)
5. Show document count badges
6. Connect to folderStore
7. Style with Vuetify v-treeview or custom
8. Test with mock data

**Deliverable**: Working folder tree navigation

---

### Phase 5: Document List (Day 4 - 12 hours)
**Tasks**:
1. Create `DocumentList.vue` with v-data-table
2. Display documents from selected folder
3. Add sortable columns
4. Add search/filter input
5. Implement action buttons (view, edit, delete)
6. Add empty state component
7. Add loading state with skeleton
8. Format file sizes and dates
9. Add document type icons
10. Test sorting and filtering

**Deliverable**: Working document list view

---

### Phase 6: Upload Dialog (Day 5 - 10 hours)
**Tasks**:
1. Create `UploadDialog.vue` component
2. Implement v-file-input for file selection
3. Add drag-and-drop zone
4. Create metadata entry form
5. Add tag input with autocomplete
6. Implement mock upload with progress bar
7. Show success/error messages
8. Add document to store on "upload"
9. Close dialog and refresh list
10. Test user flow

**Deliverable**: Working upload dialog UI

---

### Phase 7: Document Preview & Details (Day 6 - 6 hours)
**Tasks**:
1. Create `DocumentPreview.vue` dialog
2. Display document metadata and tags
3. Add preview placeholder (icon/message)
4. Add action buttons (download, edit, delete)
5. Connect to documentStore
6. Test opening from document list

**Deliverable**: Working document preview

---

### Phase 8: Search & Filter (Day 6-7 - 8 hours)
**Tasks**:
1. Create `SearchBar.vue` in AppBar
2. Create `SearchFilters.vue` panel
3. Implement live search with debouncing
4. Add filters (folder, tags, date, type)
5. Connect to searchStore
6. Filter mock documents on change
7. Display results count
8. Add "no results" state
9. Test search functionality

**Deliverable**: Working search and filters

---

### Phase 9: Metadata & Folder Management (Day 7-8 - 12 hours)
**Tasks**:
1. Create `EditMetadataDialog.vue`
2. Implement metadata editing form
3. Add tag management with autocomplete
4. Create `CreateFolderDialog.vue`
5. Implement folder creation form with path preview
6. Create `DeleteConfirmDialog.vue`
7. Connect dialogs to stores
8. Test all dialogs and actions

**Deliverable**: Working metadata and folder management

---

### Phase 10: Polish & States (Day 9 - 6 hours)
**Tasks**:
1. Create loading states for all components
2. Create empty states with illustrations
3. Create error states with retry buttons
4. Add transitions and animations
5. Implement snackbar notifications
6. Test all UI states
7. Fix any visual bugs

**Deliverable**: Polished UI with all states

---

### Phase 11: Responsive Testing (Day 10 - 4 hours)
**Tasks**:
1. Test on mobile devices (or browser dev tools)
2. Adjust layouts for small screens
3. Test touch interactions
4. Fix any mobile-specific issues
5. Test on tablet sizes
6. Verify all features work on mobile

**Deliverable**: Fully responsive POC

---

### Phase 12: Final Review & Demo Prep (Day 10 - 4 hours)
**Tasks**:
1. Complete manual testing checklist
2. Test in all browsers
3. Fix any remaining bugs
4. Add demo data variety
5. Prepare demo script
6. Document any known limitations
7. Take screenshots/video

**Deliverable**: Demo-ready POC

---

## 📅 Timeline Summary

| Phase | Duration | Cumulative |
|-------|----------|------------|
| 1. Project Setup | 4 hours | 4 hours |
| 2. Core Layout | 8 hours | 12 hours |
| 3. Mock Data & Stores | 4 hours | 16 hours |
| 4. Folder Tree | 8 hours | 24 hours |
| 5. Document List | 12 hours | 36 hours |
| 6. Upload Dialog | 10 hours | 46 hours |
| 7. Document Preview | 6 hours | 52 hours |
| 8. Search & Filter | 8 hours | 60 hours |
| 9. Metadata & Folders | 12 hours | 72 hours |
| 10. Polish & States | 6 hours | 78 hours |
| 11. Responsive Testing | 4 hours | 82 hours |
| 12. Final Review | 4 hours | 86 hours |

**Total Estimated Time**: 86 hours (~11 days at 8 hours/day, or ~2 weeks with buffer)

---

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ installed
- npm or pnpm package manager
- VS Code (recommended) with Volar extension

### Initial Setup Commands
```bash
# Create project
npm create vite@latest frontend -- --template vue-ts

# Navigate to project
cd frontend

# Install dependencies
npm install

# Add Vuetify
npm install vuetify @mdi/font

# Add Pinia
npm install pinia

# Add Vue Router (optional)
npm install vue-router@4

# Start dev server
npm run dev
```

### Recommended VS Code Extensions
- Volar (Vue Language Features)
- TypeScript Vue Plugin (Volar)
- ESLint
- Prettier
- Material Icon Theme

---

## 📖 References

- **Planning Documents**: `/planning/` folder
- **Architecture Diagram**: `/diagrams/01-system-architecture.md`
- **User Flows**: `/diagrams/07-user-flow-diagrams.md`
- **Component Diagram**: `/diagrams/04-component-diagram.md`
- **Vue 3 Guide**: `/knowledgebase/vue3.md`
- **TypeScript Guide**: `/knowledgebase/typescript.md`
- **Vuetify 3 Guide**: `/knowledgebase/vuetify3.md`
- **Pinia Guide**: `/knowledgebase/pinia.md`

---

## ✅ Acceptance Criteria

### Definition of Done
- [ ] All 12 phases completed
- [ ] All "Must Have" features implemented
- [ ] Manual testing checklist passed
- [ ] Responsive design verified on mobile/desktop
- [ ] All UI states (loading, empty, error) working
- [ ] Code follows Vue 3 Composition API patterns
- [ ] TypeScript strict mode with no errors
- [ ] ESLint passing with no warnings
- [ ] Demo prepared with realistic mock data
- [ ] Screenshots/video captured for documentation

### Demo Scenarios
1. **Folder Navigation**: Browse folder tree, select folders, view document counts
2. **Document Management**: View documents, sort/filter, open details
3. **Upload Flow**: Open upload dialog, select file, enter metadata, mock upload
4. **Search**: Use search bar, apply filters, view results
5. **Mobile**: Demonstrate responsive layout on mobile screen
6. **States**: Show loading, empty, and error states

---

## 🔄 Next Steps (Post-POC)

After POC is complete and approved:

1. **Epic 001**: Backend API Foundation (Azure Functions setup)
2. **Epic 002**: Azure Blob Storage Integration (real file uploads)
3. **Epic 003**: Cosmos DB Integration (metadata persistence)
4. **Epic 004**: Frontend-Backend Integration (connect UI to APIs)
5. **Epic 005**: Authentication & Security
6. **Epic 006**: Production Deployment

---

**Created**: 2025-09-30
**Last Updated**: 2025-09-30
**Owner**: Development Team
