# Story 03: Mock Data and Pinia Stores

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Foundation
**Priority**: Critical
**Estimate**: 4 hours

---

## User Story

As a **developer**, I want to **create mock data and Pinia stores**, so that **I can build UI components with realistic data without backend dependencies**.

---

## Acceptance Criteria

- [ ] TypeScript types defined for Document, Folder, Tag
- [ ] Mock folder data created (20-30 folders with realistic hierarchy)
- [ ] Mock document data created (50-100 documents with varied metadata)
- [ ] documentStore created with state, getters, and actions
- [ ] folderStore created with state, getters, and actions
- [ ] searchStore created for search/filter state
- [ ] uiStore created for UI state (drawer, dialogs, notifications)
- [ ] All stores registered with Pinia
- [ ] Mock data is realistic and covers edge cases
- [ ] Store actions work with mock data

---

## Technical Details

### Type Definitions

#### types/document.ts
```typescript
export interface Document {
  id: string
  name: string
  folderId: string
  size: number // bytes
  contentType: string
  blobUrl?: string // Will be empty in POC
  uploadedAt: string // ISO date string
  modifiedAt?: string // ISO date string
  metadata?: Record<string, string>
  tags?: string[]
}

export interface DocumentDto extends Document {
  folderPath?: string
  formattedSize?: string
  formattedDate?: string
}
```

#### types/folder.ts
```typescript
export interface Folder {
  id: string
  name: string
  parentId: string | null
  path: string
  documentCount: number
  createdAt: string
  modifiedAt?: string
  children?: Folder[]
}

export interface FolderTreeNode extends Folder {
  level: number
  expanded: boolean
}
```

#### types/common.ts
```typescript
export interface Tag {
  name: string
  color?: string
  count: number
}

export interface SearchFilters {
  query: string
  folderId?: string
  tags?: string[]
  dateRange?: {
    start: string
    end: string
  }
  contentTypes?: string[]
}

export interface NotificationMessage {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  timeout?: number
}
```

### Mock Data

#### data/mockFolders.ts
```typescript
import type { Folder } from '@/types/folder'

export const mockFolders: Folder[] = [
  {
    id: 'root',
    name: 'Documents',
    parentId: null,
    path: '/',
    documentCount: 0,
    createdAt: '2025-01-01T00:00:00Z'
  },
  {
    id: 'projects',
    name: 'Projects',
    parentId: 'root',
    path: '/Projects',
    documentCount: 15,
    createdAt: '2025-01-15T10:00:00Z'
  },
  {
    id: 'project-alpha',
    name: 'Project Alpha',
    parentId: 'projects',
    path: '/Projects/Project Alpha',
    documentCount: 8,
    createdAt: '2025-02-01T10:00:00Z'
  },
  {
    id: 'project-beta',
    name: 'Project Beta',
    parentId: 'projects',
    path: '/Projects/Project Beta',
    documentCount: 7,
    createdAt: '2025-02-15T10:00:00Z'
  },
  {
    id: 'finance',
    name: 'Finance',
    parentId: 'root',
    path: '/Finance',
    documentCount: 24,
    createdAt: '2025-01-10T10:00:00Z'
  },
  {
    id: 'finance-reports',
    name: 'Reports',
    parentId: 'finance',
    path: '/Finance/Reports',
    documentCount: 12,
    createdAt: '2025-02-01T10:00:00Z'
  },
  {
    id: 'finance-invoices',
    name: 'Invoices',
    parentId: 'finance',
    path: '/Finance/Invoices',
    documentCount: 8,
    createdAt: '2025-02-01T10:00:00Z'
  },
  {
    id: 'finance-budgets',
    name: 'Budgets',
    parentId: 'finance',
    path: '/Finance/Budgets',
    documentCount: 4,
    createdAt: '2025-02-01T10:00:00Z'
  },
  {
    id: 'hr',
    name: 'Human Resources',
    parentId: 'root',
    path: '/Human Resources',
    documentCount: 18,
    createdAt: '2025-01-20T10:00:00Z'
  },
  {
    id: 'hr-policies',
    name: 'Policies',
    parentId: 'hr',
    path: '/Human Resources/Policies',
    documentCount: 10,
    createdAt: '2025-02-10T10:00:00Z'
  },
  {
    id: 'hr-training',
    name: 'Training Materials',
    parentId: 'hr',
    path: '/Human Resources/Training Materials',
    documentCount: 8,
    createdAt: '2025-02-10T10:00:00Z'
  },
  {
    id: 'legal',
    name: 'Legal',
    parentId: 'root',
    path: '/Legal',
    documentCount: 15,
    createdAt: '2025-01-25T10:00:00Z'
  },
  {
    id: 'legal-contracts',
    name: 'Contracts',
    parentId: 'legal',
    path: '/Legal/Contracts',
    documentCount: 10,
    createdAt: '2025-02-20T10:00:00Z'
  },
  {
    id: 'legal-compliance',
    name: 'Compliance',
    parentId: 'legal',
    path: '/Legal/Compliance',
    documentCount: 5,
    createdAt: '2025-02-20T10:00:00Z'
  },
  {
    id: 'marketing',
    name: 'Marketing',
    parentId: 'root',
    path: '/Marketing',
    documentCount: 22,
    createdAt: '2025-01-30T10:00:00Z'
  },
  {
    id: 'marketing-campaigns',
    name: 'Campaigns',
    parentId: 'marketing',
    path: '/Marketing/Campaigns',
    documentCount: 12,
    createdAt: '2025-03-01T10:00:00Z'
  },
  {
    id: 'marketing-assets',
    name: 'Assets',
    parentId: 'marketing',
    path: '/Marketing/Assets',
    documentCount: 10,
    createdAt: '2025-03-01T10:00:00Z'
  }
]

// Helper to build folder tree
export function buildFolderTree(folders: Folder[]): Folder[] {
  const folderMap = new Map<string, Folder>()
  const rootFolders: Folder[] = []

  // Create map
  folders.forEach(folder => {
    folderMap.set(folder.id, { ...folder, children: [] })
  })

  // Build tree
  folderMap.forEach(folder => {
    if (folder.parentId === null) {
      rootFolders.push(folder)
    } else {
      const parent = folderMap.get(folder.parentId)
      if (parent && parent.children) {
        parent.children.push(folder)
      }
    }
  })

  return rootFolders
}
```

#### data/mockDocuments.ts
```typescript
import type { Document } from '@/types/document'

export const mockDocuments: Document[] = [
  {
    id: 'doc-001',
    name: 'Q4 2024 Financial Report.pdf',
    folderId: 'finance-reports',
    size: 2457600,
    contentType: 'application/pdf',
    uploadedAt: '2025-01-15T14:30:00Z',
    modifiedAt: '2025-01-20T09:15:00Z',
    metadata: {
      category: 'Financial Report',
      year: '2024',
      quarter: 'Q4',
      department: 'Finance'
    },
    tags: ['finance', 'report', 'quarterly', '2024']
  },
  {
    id: 'doc-002',
    name: 'Project Alpha Requirements.docx',
    folderId: 'project-alpha',
    size: 524288,
    contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    uploadedAt: '2025-02-05T10:00:00Z',
    metadata: {
      project: 'Alpha',
      documentType: 'Requirements',
      version: '1.0'
    },
    tags: ['project', 'alpha', 'requirements']
  },
  {
    id: 'doc-003',
    name: 'Employee Handbook 2025.pdf',
    folderId: 'hr-policies',
    size: 3145728,
    contentType: 'application/pdf',
    uploadedAt: '2025-02-12T11:30:00Z',
    metadata: {
      category: 'Policy',
      year: '2025',
      department: 'HR'
    },
    tags: ['hr', 'policy', 'handbook', '2025']
  },
  {
    id: 'doc-004',
    name: 'Marketing Campaign Q1.pptx',
    folderId: 'marketing-campaigns',
    size: 8388608,
    contentType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    uploadedAt: '2025-03-01T15:45:00Z',
    metadata: {
      campaign: 'Q1 2025',
      quarter: 'Q1',
      year: '2025'
    },
    tags: ['marketing', 'campaign', 'q1', '2025']
  },
  {
    id: 'doc-005',
    name: 'Vendor Contract - Acme Corp.pdf',
    folderId: 'legal-contracts',
    size: 1048576,
    contentType: 'application/pdf',
    uploadedAt: '2025-02-28T09:00:00Z',
    metadata: {
      vendor: 'Acme Corp',
      contractType: 'Service Agreement',
      expiryDate: '2026-02-28'
    },
    tags: ['legal', 'contract', 'vendor', 'acme']
  },
  // Add 45+ more documents with variety...
]

// Helper functions
export function getDocumentsByFolder(folderId: string): Document[] {
  return mockDocuments.filter(doc => doc.folderId === folderId)
}

export function searchDocuments(query: string): Document[] {
  const lowerQuery = query.toLowerCase()
  return mockDocuments.filter(doc =>
    doc.name.toLowerCase().includes(lowerQuery) ||
    doc.tags?.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
    Object.values(doc.metadata || {}).some(val =>
      val.toLowerCase().includes(lowerQuery)
    )
  )
}
```

### Pinia Stores

#### stores/folderStore.ts
```typescript
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import type { Folder } from '@/types/folder'
import { mockFolders, buildFolderTree } from '@/data/mockFolders'

export const useFolderStore = defineStore('folder', () => {
  // State
  const folders = ref<Folder[]>([...mockFolders])
  const selectedFolder = ref<Folder | null>(null)
  const loading = ref(false)

  // Getters
  const folderTree = computed(() => buildFolderTree(folders.value))

  const rootFolders = computed(() =>
    folders.value.filter(f => f.parentId === null)
  )

  const getFolderById = (id: string) =>
    folders.value.find(f => f.id === id)

  const getSubfolders = (parentId: string) =>
    folders.value.filter(f => f.parentId === parentId)

  // Actions
  function selectFolder(folder: Folder | null) {
    selectedFolder.value = folder
  }

  function createFolder(folder: Omit<Folder, 'id' | 'createdAt'>) {
    const newFolder: Folder = {
      ...folder,
      id: `folder-${Date.now()}`,
      createdAt: new Date().toISOString(),
      documentCount: 0
    }
    folders.value.push(newFolder)
    return newFolder
  }

  function updateFolder(id: string, updates: Partial<Folder>) {
    const index = folders.value.findIndex(f => f.id === id)
    if (index !== -1) {
      folders.value[index] = { ...folders.value[index], ...updates }
    }
  }

  function deleteFolder(id: string) {
    folders.value = folders.value.filter(f => f.id !== id)
  }

  return {
    folders,
    selectedFolder,
    loading,
    folderTree,
    rootFolders,
    getFolderById,
    getSubfolders,
    selectFolder,
    createFolder,
    updateFolder,
    deleteFolder
  }
})
```

#### stores/documentStore.ts
```typescript
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import type { Document } from '@/types/document'
import { mockDocuments } from '@/data/mockDocuments'

export const useDocumentStore = defineStore('document', () => {
  // State
  const documents = ref<Document[]>([...mockDocuments])
  const selectedDocument = ref<Document | null>(null)
  const loading = ref(false)

  // Getters
  const documentsByFolder = computed(() => (folderId: string) =>
    documents.value.filter(doc => doc.folderId === folderId)
  )

  const documentCount = computed(() => documents.value.length)

  const allTags = computed(() => {
    const tagSet = new Set<string>()
    documents.value.forEach(doc => {
      doc.tags?.forEach(tag => tagSet.add(tag))
    })
    return Array.from(tagSet).sort()
  })

  // Actions
  function selectDocument(doc: Document | null) {
    selectedDocument.value = doc
  }

  function createDocument(doc: Omit<Document, 'id' | 'uploadedAt'>) {
    const newDoc: Document = {
      ...doc,
      id: `doc-${Date.now()}`,
      uploadedAt: new Date().toISOString()
    }
    documents.value.push(newDoc)
    return newDoc
  }

  function updateDocument(id: string, updates: Partial<Document>) {
    const index = documents.value.findIndex(d => d.id === id)
    if (index !== -1) {
      documents.value[index] = { ...documents.value[index], ...updates }
    }
  }

  function deleteDocument(id: string) {
    documents.value = documents.value.filter(d => d.id !== id)
  }

  return {
    documents,
    selectedDocument,
    loading,
    documentsByFolder,
    documentCount,
    allTags,
    selectDocument,
    createDocument,
    updateDocument,
    deleteDocument
  }
})
```

#### stores/uiStore.ts
```typescript
import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { NotificationMessage } from '@/types/common'

export const useUIStore = defineStore('ui', () => {
  // Drawer state
  const drawerOpen = ref(true)
  const drawerRail = ref(false)

  // Dialog state
  const uploadDialogOpen = ref(false)
  const createFolderDialogOpen = ref(false)
  const editMetadataDialogOpen = ref(false)

  // Notifications
  const notifications = ref<NotificationMessage[]>([])

  // Actions
  function toggleDrawer() {
    drawerOpen.value = !drawerOpen.value
  }

  function showNotification(
    type: NotificationMessage['type'],
    message: string,
    timeout = 5000
  ) {
    const notification: NotificationMessage = {
      id: `notif-${Date.now()}`,
      type,
      message,
      timeout
    }
    notifications.value.push(notification)

    if (timeout > 0) {
      setTimeout(() => {
        dismissNotification(notification.id)
      }, timeout)
    }
  }

  function dismissNotification(id: string) {
    notifications.value = notifications.value.filter(n => n.id !== id)
  }

  return {
    drawerOpen,
    drawerRail,
    uploadDialogOpen,
    createFolderDialogOpen,
    editMetadataDialogOpen,
    notifications,
    toggleDrawer,
    showNotification,
    dismissNotification
  }
})
```

---

## Tasks

1. **Create Type Definitions**
   - Define Document, Folder, Tag interfaces
   - Create common types for filters and notifications
   - Ensure all types are exported

2. **Create Mock Folder Data**
   - Generate 20-30 realistic folders
   - Create 3-4 levels of hierarchy
   - Add realistic names and paths
   - Include document counts

3. **Create Mock Document Data**
   - Generate 50-100 documents
   - Vary file types (PDF, DOCX, XLSX, images)
   - Add realistic metadata and tags
   - Distribute across folders

4. **Implement Folder Store**
   - Set up state with mock data
   - Create computed getters (tree, lookup)
   - Implement CRUD actions
   - Add folder selection

5. **Implement Document Store**
   - Set up state with mock data
   - Create getters (by folder, all tags)
   - Implement CRUD actions
   - Add document selection

6. **Implement UI Store**
   - Add drawer state
   - Add dialog state management
   - Implement notification system

7. **Test Stores**
   - Test all getters return correct data
   - Test CRUD actions modify state
   - Test notification system

---

## Definition of Done

- [ ] All TypeScript types defined and exported
- [ ] Mock folders created (20-30 with hierarchy)
- [ ] Mock documents created (50-100 with variety)
- [ ] folderStore implemented and working
- [ ] documentStore implemented and working
- [ ] uiStore implemented and working
- [ ] All stores registered in main.ts
- [ ] Stores can be imported and used in components
- [ ] No TypeScript errors
- [ ] Mock data is realistic and covers edge cases

---

## Testing

### Testing Store Actions
```typescript
// In browser console or component
import { useFolderStore } from '@/stores/folderStore'

const folderStore = useFolderStore()

// Test folder selection
folderStore.selectFolder(folderStore.folders[0])
console.log(folderStore.selectedFolder)

// Test folder creation
const newFolder = folderStore.createFolder({
  name: 'Test Folder',
  parentId: 'root',
  path: '/Test Folder',
  documentCount: 0
})
console.log(folderStore.folders.length)
```

---

## Dependencies

**Depends On**: Story 01 (Project Setup)
**Blocks**: All feature stories that use data

---

## Resources

- **Pinia Docs**: https://pinia.vuejs.org
- **Knowledge Base**: `/knowledgebase/pinia.md`
