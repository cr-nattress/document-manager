# Story 05: Document List View

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Feature
**Priority**: Critical
**Estimate**: 12 hours

---

## User Story

As a **user**, I want to **view documents in the selected folder as a sortable list**, so that **I can browse, search, and take actions on documents**.

---

## Acceptance Criteria

- [ ] Document list displays all documents in selected folder
- [ ] Table shows columns: name, type icon, size, modified date
- [ ] Columns are sortable (ascending/descending)
- [ ] Search bar filters documents by name in real-time
- [ ] Action buttons for each document: view, download, edit, delete
- [ ] File size formatted human-readable (KB, MB, GB)
- [ ] Dates formatted in user-friendly format
- [ ] Document type icons displayed (PDF, Word, Excel, image)
- [ ] Empty state when no documents in folder
- [ ] Loading state with skeleton loaders
- [ ] Pagination or virtual scrolling for large lists
- [ ] Responsive on mobile (card view)

---

## Technical Details

### Component Structure

#### DocumentList.vue
```vue
<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useDocumentStore } from '@/stores/documentStore'
import { useFolderStore } from '@/stores/folderStore'

const documentStore = useDocumentStore()
const folderStore = useFolderStore()

const { selectedFolder } = storeToRefs(folderStore)
const { loading } = storeToRefs(documentStore)

const search = ref('')
const page = ref(1)
const itemsPerPage = ref(25)

const headers = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Type', key: 'contentType', sortable: true },
  { title: 'Size', key: 'size', sortable: true },
  { title: 'Modified', key: 'modifiedAt', sortable: true },
  { title: 'Actions', key: 'actions', sortable: false, align: 'end' }
]

const documents = computed(() => {
  if (!selectedFolder.value) return []
  return documentStore.documentsByFolder(selectedFolder.value.id)
})

const filteredDocuments = computed(() => {
  if (!search.value) return documents.value

  const query = search.value.toLowerCase()
  return documents.value.filter(doc =>
    doc.name.toLowerCase().includes(query) ||
    doc.tags?.some(tag => tag.toLowerCase().includes(query))
  )
})

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function getFileIcon(contentType: string): string {
  if (contentType.includes('pdf')) return 'mdi-file-pdf-box'
  if (contentType.includes('word')) return 'mdi-file-word-box'
  if (contentType.includes('excel') || contentType.includes('spreadsheet')) return 'mdi-file-excel-box'
  if (contentType.includes('powerpoint') || contentType.includes('presentation')) return 'mdi-file-powerpoint-box'
  if (contentType.includes('image')) return 'mdi-file-image'
  return 'mdi-file-document'
}

function handleView(doc: any) {
  documentStore.selectDocument(doc)
  // Open preview dialog (to be implemented)
}

function handleDownload(doc: any) {
  console.log('Download:', doc.name)
  // Mock download action
}

function handleEdit(doc: any) {
  documentStore.selectDocument(doc)
  // Open edit dialog (to be implemented)
}

function handleDelete(doc: any) {
  if (confirm(`Delete "${doc.name}"?`)) {
    documentStore.deleteDocument(doc.id)
  }
}
</script>

<template>
  <div class="document-list">
    <v-card>
      <v-card-title>
        <v-row align="center">
          <v-col cols="12" md="6">
            <div class="d-flex align-center">
              <v-icon icon="mdi-file-document-multiple" class="mr-2" />
              <span v-if="selectedFolder">
                {{ selectedFolder.name }}
              </span>
              <span v-else>All Documents</span>
              <v-chip class="ml-2" size="small">
                {{ filteredDocuments.length }}
              </v-chip>
            </div>
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="search"
              prepend-inner-icon="mdi-magnify"
              label="Search documents"
              single-line
              hide-details
              clearable
              variant="outlined"
              density="compact"
            />
          </v-col>
        </v-row>
      </v-card-title>

      <v-divider />

      <!-- Desktop view: Data table -->
      <v-data-table
        :headers="headers"
        :items="filteredDocuments"
        :search="search"
        :loading="loading"
        :items-per-page="itemsPerPage"
        :page="page"
        class="d-none d-md-block"
        @update:page="page = $event"
        @update:items-per-page="itemsPerPage = $event"
      >
        <!-- Name with icon -->
        <template #item.name="{ item }">
          <div class="d-flex align-center">
            <v-icon
              :icon="getFileIcon(item.contentType)"
              class="mr-2"
              :color="getFileIcon(item.contentType).includes('pdf') ? 'red' : undefined"
            />
            <span class="text-truncate" style="max-width: 300px">
              {{ item.name }}
            </span>
          </div>
        </template>

        <!-- Type badge -->
        <template #item.contentType="{ item }">
          <v-chip size="small" variant="outlined">
            {{ item.contentType.split('/')[1].toUpperCase() }}
          </v-chip>
        </template>

        <!-- Size formatted -->
        <template #item.size="{ item }">
          {{ formatBytes(item.size) }}
        </template>

        <!-- Date formatted -->
        <template #item.modifiedAt="{ item }">
          {{ formatDate(item.modifiedAt || item.uploadedAt) }}
        </template>

        <!-- Actions -->
        <template #item.actions="{ item }">
          <v-btn
            icon="mdi-eye"
            size="small"
            variant="text"
            @click="handleView(item)"
          />
          <v-btn
            icon="mdi-download"
            size="small"
            variant="text"
            @click="handleDownload(item)"
          />
          <v-btn
            icon="mdi-pencil"
            size="small"
            variant="text"
            @click="handleEdit(item)"
          />
          <v-btn
            icon="mdi-delete"
            size="small"
            variant="text"
            color="error"
            @click="handleDelete(item)"
          />
        </template>

        <!-- Loading state -->
        <template #loading>
          <v-skeleton-loader type="table-row@10" />
        </template>

        <!-- No data state -->
        <template #no-data>
          <v-empty-state
            icon="mdi-file-document-outline"
            title="No documents found"
            text="This folder is empty. Upload your first document to get started."
          >
            <template #actions>
              <v-btn color="primary" prepend-icon="mdi-upload">
                Upload Document
              </v-btn>
            </template>
          </v-empty-state>
        </template>
      </v-data-table>

      <!-- Mobile view: Card list -->
      <v-list class="d-md-none">
        <v-list-item
          v-for="doc in filteredDocuments"
          :key="doc.id"
          @click="handleView(doc)"
        >
          <template #prepend>
            <v-icon :icon="getFileIcon(doc.contentType)" size="large" />
          </template>

          <v-list-item-title>{{ doc.name }}</v-list-item-title>
          <v-list-item-subtitle>
            {{ formatBytes(doc.size) }} • {{ formatDate(doc.modifiedAt || doc.uploadedAt) }}
          </v-list-item-subtitle>

          <template #append>
            <v-menu>
              <template #activator="{ props }">
                <v-btn
                  icon="mdi-dots-vertical"
                  variant="text"
                  v-bind="props"
                />
              </template>
              <v-list>
                <v-list-item @click="handleView(doc)">
                  <template #prepend>
                    <v-icon icon="mdi-eye" />
                  </template>
                  <v-list-item-title>View</v-list-item-title>
                </v-list-item>
                <v-list-item @click="handleDownload(doc)">
                  <template #prepend>
                    <v-icon icon="mdi-download" />
                  </template>
                  <v-list-item-title>Download</v-list-item-title>
                </v-list-item>
                <v-list-item @click="handleEdit(doc)">
                  <template #prepend>
                    <v-icon icon="mdi-pencil" />
                  </template>
                  <v-list-item-title>Edit</v-list-item-title>
                </v-list-item>
                <v-list-item @click="handleDelete(doc)">
                  <template #prepend>
                    <v-icon icon="mdi-delete" color="error" />
                  </template>
                  <v-list-item-title class="text-error">Delete</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </template>
        </v-list-item>

        <v-list-item v-if="filteredDocuments.length === 0">
          <v-empty-state
            icon="mdi-file-document-outline"
            title="No documents"
            text="This folder is empty"
          />
        </v-list-item>
      </v-list>
    </v-card>

    <!-- Floating action button for mobile -->
    <v-btn
      class="d-md-none"
      color="primary"
      icon="mdi-upload"
      size="large"
      position="fixed"
      location="bottom end"
      style="bottom: 80px; right: 16px"
    />
  </div>
</template>

<style scoped>
.document-list {
  height: 100%;
}
</style>
```

---

## Tasks

1. **Create DocumentList Component**
   - Set up v-data-table for desktop
   - Set up v-list for mobile
   - Connect to documentStore and folderStore

2. **Implement Columns**
   - Name column with file icon
   - Type badge column
   - Size column with formatting
   - Modified date column with formatting
   - Actions column with buttons

3. **Add File Type Icons**
   - Create icon mapping function
   - Use MDI icons for each file type
   - Add color coding (PDF red, etc.)

4. **Implement Formatting**
   - Format bytes to KB/MB/GB
   - Format dates to readable format
   - Truncate long file names with ellipsis

5. **Add Search/Filter**
   - Real-time search by name
   - Filter by tags
   - Clear search button

6. **Add Action Handlers**
   - View document (select and emit event)
   - Download document (mock action)
   - Edit metadata (open dialog)
   - Delete document (confirm and remove)

7. **Add Empty State**
   - Show when no documents
   - Include helpful message
   - Add upload button

8. **Add Loading State**
   - Skeleton loader for table rows
   - Loading spinner option

9. **Make Responsive**
   - Desktop: full data table
   - Mobile: card list with menu
   - Floating action button on mobile

10. **Test with Mock Data**
    - Test with various document types
    - Test sorting
    - Test search
    - Test actions

---

## Definition of Done

- [ ] Document list displays all documents in folder
- [ ] Sortable by all columns
- [ ] Search filters documents in real-time
- [ ] File type icons display correctly
- [ ] File sizes formatted correctly (KB, MB, GB)
- [ ] Dates formatted in readable format
- [ ] Action buttons work (view, download, edit, delete)
- [ ] Empty state shows when no documents
- [ ] Loading state shows skeleton
- [ ] Desktop view uses data table
- [ ] Mobile view uses card list with menu
- [ ] Responsive at all breakpoints
- [ ] No console errors

---

## Testing

### Desktop Testing
1. Select folder with documents
2. Verify table displays all documents
3. Click each column header to sort
4. Type in search, verify filtering
5. Click action buttons, verify behavior
6. Test with folder with no documents

### Mobile Testing
1. Switch to mobile viewport
2. Verify card list displays
3. Tap document to view
4. Tap menu icon, verify actions appear
5. Test FAB button
6. Verify touch targets are adequate

---

## Dependencies

**Depends On**:
- Story 03 (Mock Data & Stores)
- Story 04 (Folder Tree) - for folder selection

**Blocks**:
- Story 07 (Document Preview)
- Story 08 (Edit Metadata)

---

## Resources

- **Vuetify Data Table**: https://vuetifyjs.com/en/components/data-tables/
- **Vuetify Empty State**: https://vuetifyjs.com/en/components/empty-states/
