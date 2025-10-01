# Story 06: Upload Dialog (UI Mockup)

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Feature
**Priority**: High
**Estimate**: 10 hours

---

## User Story

As a **user**, I want to **select files and enter metadata before uploading**, so that **I can organize my documents with relevant information**.

---

## Acceptance Criteria

- [ ] Upload dialog opens from button click or FAB
- [ ] File selection via browse button or drag-and-drop
- [ ] Display selected file name, size, and type icon
- [ ] Form for document name (defaults to filename)
- [ ] Tag input with autocomplete from existing tags
- [ ] Custom metadata key-value fields (add/remove)
- [ ] Upload progress bar simulation (mock)
- [ ] Success message and document added to list
- [ ] Error state mockup
- [ ] Cancel button clears form and closes dialog
- [ ] Validation: required fields, file size limit
- [ ] Responsive design for mobile

---

## Technical Details

### Component: UploadDialog.vue

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useDocumentStore } from '@/stores/documentStore'
import { useFolderStore } from '@/stores/folderStore'
import { useUIStore } from '@/stores/uiStore'

const documentStore = useDocumentStore()
const folderStore = useFolderStore()
const uiStore = useUIStore()

const { selectedFolder } = storeToRefs(folderStore)
const { allTags } = storeToRefs(documentStore)

const dialog = ref(false)
const dragOver = ref(false)
const uploading = ref(false)
const uploadProgress = ref(0)

// Form data
const selectedFile = ref<File | null>(null)
const documentName = ref('')
const selectedTags = ref<string[]>([])
const customMetadata = ref<Array<{ key: string; value: string }>>([
  { key: '', value: '' }
])

const form = ref()
const valid = ref(false)

const rules = {
  required: (v: any) => !!v || 'This field is required',
  fileSize: (v: File | null) => {
    if (!v) return 'File is required'
    const maxSize = 100 * 1024 * 1024 // 100MB
    return v.size <= maxSize || `File must be less than ${maxSize / 1024 / 1024}MB`
  }
}

const fileIcon = computed(() => {
  if (!selectedFile.value) return 'mdi-file'
  const type = selectedFile.value.type
  if (type.includes('pdf')) return 'mdi-file-pdf-box'
  if (type.includes('word')) return 'mdi-file-word-box'
  if (type.includes('excel')) return 'mdi-file-excel-box'
  if (type.includes('image')) return 'mdi-file-image'
  return 'mdi-file-document'
})

const fileSize = computed(() => {
  if (!selectedFile.value) return ''
  const bytes = selectedFile.value.size
  const mb = (bytes / (1024 * 1024)).toFixed(2)
  return `${mb} MB`
})

function handleFileSelect(files: File[]) {
  if (files.length > 0) {
    selectedFile.value = files[0]
    documentName.value = files[0].name
  }
}

function handleDrop(event: DragEvent) {
  dragOver.value = false
  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    selectedFile.value = files[0]
    documentName.value = files[0].name
  }
}

function addMetadataField() {
  customMetadata.value.push({ key: '', value: '' })
}

function removeMetadataField(index: number) {
  customMetadata.value.splice(index, 1)
}

async function handleUpload() {
  const isValid = await form.value.validate()
  if (!isValid.valid || !selectedFile.value) return

  uploading.value = true
  uploadProgress.value = 0

  // Simulate upload progress
  const interval = setInterval(() => {
    uploadProgress.value += 10
    if (uploadProgress.value >= 100) {
      clearInterval(interval)
      completeUpload()
    }
  }, 200)
}

function completeUpload() {
  // Create mock document
  const metadata: Record<string, string> = {}
  customMetadata.value.forEach(item => {
    if (item.key && item.value) {
      metadata[item.key] = item.value
    }
  })

  documentStore.createDocument({
    name: documentName.value,
    folderId: selectedFolder.value?.id || 'root',
    size: selectedFile.value!.size,
    contentType: selectedFile.value!.type,
    metadata,
    tags: selectedTags.value
  })

  uiStore.showNotification('success', `"${documentName.value}" uploaded successfully`)

  // Reset and close
  resetForm()
  dialog.value = false
  uploading.value = false
  uploadProgress.value = 0
}

function resetForm() {
  selectedFile.value = null
  documentName.value = ''
  selectedTags.value = []
  customMetadata.value = [{ key: '', value: '' }]
  form.value?.reset()
}

function handleCancel() {
  resetForm()
  dialog.value = false
}

defineExpose({ open: () => { dialog.value = true } })
</script>

<template>
  <v-dialog
    v-model="dialog"
    max-width="700"
    persistent
  >
    <template #activator="{ props }">
      <v-btn
        color="primary"
        prepend-icon="mdi-upload"
        v-bind="props"
      >
        Upload Document
      </v-btn>
    </template>

    <v-card>
      <v-card-title>
        <v-icon icon="mdi-upload" class="mr-2" />
        Upload Document
      </v-card-title>

      <v-divider />

      <v-card-text>
        <v-form ref="form" v-model="valid">
          <!-- File Selection -->
          <div class="mb-4">
            <v-file-input
              v-model="selectedFile"
              label="Select file"
              prepend-icon="mdi-paperclip"
              show-size
              :rules="[rules.required, rules.fileSize]"
              @update:model-value="handleFileSelect"
            />

            <div class="text-caption text-grey mb-2">Or drag and drop below:</div>

            <div
              class="drop-zone"
              :class="{ 'drag-over': dragOver }"
              @dragover.prevent="dragOver = true"
              @dragleave="dragOver = false"
              @drop.prevent="handleDrop"
            >
              <v-icon
                size="64"
                :icon="selectedFile ? fileIcon : 'mdi-cloud-upload'"
                :color="selectedFile ? 'success' : 'grey'"
              />
              <p v-if="!selectedFile" class="text-center mt-4">
                Drag and drop file here
              </p>
              <div v-else class="text-center mt-4">
                <p class="font-weight-bold">{{ selectedFile.name }}</p>
                <p class="text-caption">{{ fileSize }}</p>
              </div>
            </div>
          </div>

          <v-divider class="my-4" />

          <!-- Document Name -->
          <v-text-field
            v-model="documentName"
            label="Document Name"
            prepend-inner-icon="mdi-file-document"
            :rules="[rules.required]"
            counter="100"
            hint="Name to display in the system"
            persistent-hint
          />

          <!-- Folder Selection -->
          <v-text-field
            :model-value="selectedFolder?.path || '/'"
            label="Destination Folder"
            prepend-inner-icon="mdi-folder"
            readonly
            hint="Currently selected folder"
            persistent-hint
            class="mt-4"
          />

          <!-- Tags -->
          <v-combobox
            v-model="selectedTags"
            :items="allTags"
            label="Tags"
            prepend-inner-icon="mdi-tag-multiple"
            multiple
            chips
            closable-chips
            hint="Press enter to add a new tag"
            persistent-hint
            class="mt-4"
          />

          <!-- Custom Metadata -->
          <div class="mt-6">
            <div class="d-flex align-center mb-2">
              <v-icon icon="mdi-information" class="mr-2" />
              <span class="font-weight-medium">Custom Metadata</span>
              <v-spacer />
              <v-btn
                size="small"
                prepend-icon="mdi-plus"
                variant="text"
                @click="addMetadataField"
              >
                Add Field
              </v-btn>
            </div>

            <v-row
              v-for="(field, index) in customMetadata"
              :key="index"
              class="mb-2"
            >
              <v-col cols="5">
                <v-text-field
                  v-model="field.key"
                  label="Key"
                  density="compact"
                  hide-details
                />
              </v-col>
              <v-col cols="5">
                <v-text-field
                  v-model="field.value"
                  label="Value"
                  density="compact"
                  hide-details
                />
              </v-col>
              <v-col cols="2">
                <v-btn
                  icon="mdi-delete"
                  size="small"
                  variant="text"
                  color="error"
                  @click="removeMetadataField(index)"
                />
              </v-col>
            </v-row>
          </div>

          <!-- Upload Progress -->
          <div v-if="uploading" class="mt-6">
            <v-progress-linear
              :model-value="uploadProgress"
              color="primary"
              height="25"
              striped
            >
              <template #default="{ value }">
                <strong>{{ Math.ceil(value) }}%</strong>
              </template>
            </v-progress-linear>
            <p class="text-center text-caption mt-2">
              Uploading {{ documentName }}...
            </p>
          </div>
        </v-form>
      </v-card-text>

      <v-divider />

      <v-card-actions>
        <v-spacer />
        <v-btn
          variant="text"
          :disabled="uploading"
          @click="handleCancel"
        >
          Cancel
        </v-btn>
        <v-btn
          color="primary"
          :disabled="!valid || uploading"
          :loading="uploading"
          @click="handleUpload"
        >
          Upload
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.drop-zone {
  border: 2px dashed #ccc;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s;
  cursor: pointer;
}

.drop-zone:hover {
  border-color: rgb(var(--v-theme-primary));
  background-color: rgba(var(--v-theme-primary), 0.05);
}

.drop-zone.drag-over {
  border-color: rgb(var(--v-theme-primary));
  background-color: rgba(var(--v-theme-primary), 0.1);
  transform: scale(1.02);
}
</style>
```

---

## Tasks

1. **Create Upload Dialog Component**
   - Set up v-dialog with activator button
   - Create dialog header with icon
   - Add persistent prop to prevent closing on backdrop click

2. **Implement File Selection**
   - Add v-file-input component
   - Handle file selection callback
   - Display selected file info
   - Add file size validation

3. **Create Drag-and-Drop Zone**
   - Add drop zone div with styling
   - Handle dragover, dragleave, drop events
   - Show visual feedback on drag over
   - Display file info after drop

4. **Add Form Fields**
   - Document name text field
   - Destination folder display (readonly)
   - Tags combobox with autocomplete
   - Custom metadata key-value pairs

5. **Implement Metadata Fields**
   - Dynamic list of key-value inputs
   - Add/remove field buttons
   - Validate non-empty keys

6. **Create Upload Simulation**
   - Mock progress bar (0-100%)
   - Animate progress with setInterval
   - Show uploading state
   - Disable form during upload

7. **Handle Upload Completion**
   - Create document in store
   - Show success notification
   - Reset form
   - Close dialog

8. **Add Validation**
   - Required file
   - File size limit (100MB)
   - Required document name
   - Form validity check before upload

9. **Style Dialog**
   - Proper spacing and layout
   - Drag zone hover/active states
   - Responsive on mobile
   - Touch-friendly buttons

10. **Test All Scenarios**
    - File selection via browse
    - File selection via drag-drop
    - Form validation
    - Upload progress
    - Cancel action
    - Success flow

---

## Definition of Done

- [ ] Dialog opens from button click
- [ ] File can be selected via browse button
- [ ] File can be selected via drag-and-drop
- [ ] Selected file displays name, size, icon
- [ ] Document name field defaults to filename
- [ ] Tags autocomplete from existing tags
- [ ] Custom metadata fields can be added/removed
- [ ] Upload button validates form
- [ ] Progress bar animates from 0-100%
- [ ] Success notification shows
- [ ] Document appears in list after upload
- [ ] Cancel button resets form and closes dialog
- [ ] Form validates required fields and file size
- [ ] Responsive on mobile

---

## Testing

### Manual Testing Steps

1. **Open Dialog**
   - Click "Upload Document" button
   - Verify dialog opens
   - Verify form is empty

2. **File Selection (Browse)**
   - Click file input "Choose file"
   - Select a file
   - Verify file name displays
   - Verify file size shows
   - Verify icon changes based on type

3. **File Selection (Drag-Drop)**
   - Clear form
   - Drag file over drop zone
   - Verify visual feedback (border/background change)
   - Drop file
   - Verify file info displays

4. **Form Fields**
   - Verify document name auto-fills
   - Change document name
   - Add tags (existing and new)
   - Add custom metadata fields
   - Remove metadata fields
   - Verify folder path displays

5. **Validation**
   - Try to upload without file - verify error
   - Try with file > 100MB - verify error
   - Leave name blank - verify error
   - Fill all required fields - verify upload enabled

6. **Upload Simulation**
   - Click "Upload"
   - Verify progress bar appears
   - Verify progress animates 0-100%
   - Verify "Uploading..." message
   - Verify form disabled during upload

7. **Success Flow**
   - Wait for upload to complete
   - Verify success notification
   - Verify dialog closes
   - Check document list
   - Verify new document appears

8. **Cancel**
   - Open dialog
   - Select file
   - Click "Cancel"
   - Verify form resets
   - Verify dialog closes
   - Reopen - verify form is empty

9. **Mobile Testing**
   - Test on mobile viewport
   - Verify dialog is responsive
   - Test touch interactions
   - Verify readable on small screen

---

## Dependencies

**Depends On**:
- Story 03 (Mock Data & Stores)
- Story 04 (Folder Tree) - for selected folder
- Story 05 (Document List) - to show uploaded document

---

## Notes

- This is a UI mockup only - no real file upload to backend
- Progress bar is simulated with setTimeout
- File is not actually uploaded, just added to mock store
- Real implementation will use FormData and multipart/form-data
- Consider adding file type restrictions (e.g., only PDF, Office docs)
- Future: Add multiple file upload support

---

## Resources

- **Vuetify File Input**: https://vuetifyjs.com/en/components/file-inputs/
- **Vuetify Dialog**: https://vuetifyjs.com/en/components/dialogs/
- **Vuetify Combobox**: https://vuetifyjs.com/en/components/combobox/
- **HTML5 Drag and Drop**: https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API
