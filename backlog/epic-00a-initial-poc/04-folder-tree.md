# Story 04: Folder Tree Navigation Component

**Epic**: Epic 00a - Initial POC (UI Only)
**Story Type**: Feature
**Priority**: Critical
**Estimate**: 8 hours

---

## User Story

As a **user**, I want to **see a hierarchical folder tree and navigate through it**, so that **I can browse my documents organized in folders**.

---

## Acceptance Criteria

- [ ] Folder tree displays all folders in hierarchical structure
- [ ] Folders can be expanded and collapsed
- [ ] Selected folder is visually highlighted
- [ ] Document count badge displayed for each folder
- [ ] Folder icons change based on open/closed state
- [ ] Smooth expand/collapse animations
- [ ] Clicking folder selects it and shows documents in main view
- [ ] Tree maintains state (expanded folders) during navigation
- [ ] Works with deeply nested folders (3-4 levels)
- [ ] Responsive design for mobile

---

## Technical Details

### Components to Create

#### 1. FolderTree.vue
```vue
<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useFolderStore } from '@/stores/folderStore'
import FolderNode from './FolderNode.vue'

const folderStore = useFolderStore()
const { folderTree, selectedFolder } = storeToRefs(folderStore)

const expanded = ref<string[]>(['root']) // IDs of expanded folders

function handleSelect(folder: any) {
  folderStore.selectFolder(folder)
}

function toggleExpand(folderId: string) {
  const index = expanded.value.indexOf(folderId)
  if (index > -1) {
    expanded.value.splice(index, 1)
  } else {
    expanded.value.push(folderId)
  }
}

function isExpanded(folderId: string): boolean {
  return expanded.value.includes(folderId)
}

function isSelected(folderId: string): boolean {
  return selectedFolder.value?.id === folderId
}
</script>

<template>
  <div class="folder-tree">
    <v-card variant="flat">
      <v-card-title class="d-flex align-center">
        <v-icon icon="mdi-folder-multiple" class="mr-2" />
        Folders
        <v-spacer />
        <v-btn
          icon="mdi-folder-plus"
          size="small"
          variant="text"
        />
      </v-card-title>

      <v-divider />

      <v-card-text class="pa-0">
        <v-list density="compact" nav>
          <folder-node
            v-for="folder in folderTree"
            :key="folder.id"
            :folder="folder"
            :level="0"
            :expanded="isExpanded(folder.id)"
            :selected="isSelected(folder.id)"
            @select="handleSelect"
            @toggle="toggleExpand"
          />
        </v-list>
      </v-card-text>
    </v-card>
  </div>
</template>

<style scoped>
.folder-tree {
  height: 100%;
  overflow-y: auto;
}
</style>
```

#### 2. FolderNode.vue (Recursive)
```vue
<script setup lang="ts">
import { computed } from 'vue'
import type { Folder } from '@/types/folder'

interface Props {
  folder: Folder
  level: number
  expanded: boolean
  selected: boolean
}

interface Emits {
  (e: 'select', folder: Folder): void
  (e: 'toggle', folderId: string): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const hasChildren = computed(() =>
  props.folder.children && props.folder.children.length > 0
)

const folderIcon = computed(() => {
  if (!hasChildren.value) return 'mdi-folder'
  return props.expanded ? 'mdi-folder-open' : 'mdi-folder'
})

const indentStyle = computed(() => ({
  paddingLeft: `${props.level * 16}px`
}))

function handleClick() {
  emit('select', props.folder)
}

function handleToggle(event: Event) {
  event.stopPropagation()
  emit('toggle', props.folder.id)
}
</script>

<template>
  <div class="folder-node">
    <v-list-item
      :active="selected"
      :style="indentStyle"
      @click="handleClick"
    >
      <template #prepend>
        <v-btn
          v-if="hasChildren"
          :icon="expanded ? 'mdi-chevron-down' : 'mdi-chevron-right'"
          size="x-small"
          variant="text"
          density="compact"
          @click="handleToggle"
        />
        <div v-else style="width: 28px" />
        <v-icon :icon="folderIcon" class="ml-2" />
      </template>

      <v-list-item-title>
        {{ folder.name }}
      </v-list-item-title>

      <template #append>
        <v-chip
          v-if="folder.documentCount > 0"
          size="x-small"
          variant="outlined"
        >
          {{ folder.documentCount }}
        </v-chip>
      </template>
    </v-list-item>

    <!-- Recursive children -->
    <div v-if="expanded && hasChildren" class="folder-children">
      <folder-node
        v-for="child in folder.children"
        :key="child.id"
        :folder="child"
        :level="level + 1"
        :expanded="$attrs.isExpanded?.(child.id)"
        :selected="$attrs.isSelected?.(child.id)"
        @select="$emit('select', $event)"
        @toggle="$emit('toggle', $event)"
      />
    </div>
  </div>
</template>

<style scoped>
.folder-node {
  user-select: none;
}

.folder-children {
  transition: all 0.2s ease;
}

.v-list-item {
  min-height: 40px;
}
</style>
```

### Alternative: Using Vuetify v-treeview

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useFolderStore } from '@/stores/folderStore'

const folderStore = useFolderStore()
const { folderTree, selectedFolder } = storeToRefs(folderStore)

const selected = ref<string[]>([])
const opened = ref<string[]>(['root'])

// Transform folders to v-treeview format
const treeItems = computed(() =>
  transformFolders(folderTree.value)
)

function transformFolders(folders: any[]): any[] {
  return folders.map(folder => ({
    id: folder.id,
    title: folder.name,
    value: folder.id,
    prependIcon: opened.value.includes(folder.id) ? 'mdi-folder-open' : 'mdi-folder',
    subtitle: `${folder.documentCount} documents`,
    children: folder.children ? transformFolders(folder.children) : []
  }))
}

function handleSelect(items: string[]) {
  if (items.length > 0) {
    const folder = folderStore.getFolderById(items[0])
    if (folder) {
      folderStore.selectFolder(folder)
    }
  }
}
</script>

<template>
  <v-card variant="flat">
    <v-card-title>
      <v-icon icon="mdi-folder-multiple" class="mr-2" />
      Folders
    </v-card-title>

    <v-divider />

    <v-card-text>
      <v-treeview
        v-model:selected="selected"
        v-model:opened="opened"
        :items="treeItems"
        activatable
        open-on-click
        item-value="id"
        @update:selected="handleSelect"
      >
        <template #append="{ item }">
          <v-chip
            v-if="item.subtitle"
            size="x-small"
            variant="outlined"
          >
            {{ item.subtitle }}
          </v-chip>
        </template>
      </v-treeview>
    </v-card-text>
  </v-card>
</template>
```

---

## Tasks

1. **Create FolderNode Component**
   - Build recursive component structure
   - Add expand/collapse toggle
   - Add folder icon with state
   - Add document count badge
   - Implement click to select
   - Style with proper indentation

2. **Create FolderTree Component**
   - Set up tree container
   - Manage expanded state
   - Manage selected state
   - Connect to folderStore
   - Add "New Folder" button in header

3. **Implement Expand/Collapse Logic**
   - Track expanded folder IDs
   - Toggle on chevron click
   - Prevent selection on toggle click
   - Add smooth transition animation

4. **Implement Selection Logic**
   - Highlight selected folder
   - Update store on selection
   - Visual feedback (background color)
   - Emit selection event

5. **Style Tree**
   - Proper indentation per level
   - Hover states
   - Active/selected states
   - Touch-friendly on mobile
   - Scrollable container

6. **Test with Mock Data**
   - Test with deeply nested folders
   - Test expand/collapse
   - Test selection
   - Test document count display

---

## Definition of Done

- [ ] FolderTree component renders all folders
- [ ] FolderNode component renders recursively
- [ ] Folders can be expanded and collapsed
- [ ] Chevron icon rotates on expand/collapse
- [ ] Folder icon changes (open/closed)
- [ ] Selected folder is visually highlighted
- [ ] Document count badge displays correctly
- [ ] Clicking folder selects it
- [ ] Expand/collapse has smooth animation
- [ ] Works with 3-4 levels of nesting
- [ ] Responsive on mobile devices

---

## Testing

### Manual Testing Steps

1. **Render Test**
   - Open app with mock data
   - Verify all root folders display
   - Check folder icons render

2. **Expand/Collapse Test**
   - Click chevron on folder with children
   - Verify folder expands and children show
   - Verify chevron rotates
   - Verify folder icon changes to open
   - Click again to collapse
   - Verify smooth animation

3. **Selection Test**
   - Click folder name
   - Verify folder highlights
   - Verify selected state persists
   - Click different folder
   - Verify only one folder selected at a time

4. **Document Count Test**
   - Verify count badge shows on folders with documents
   - Verify count matches mock data
   - Verify no badge on empty folders

5. **Deep Nesting Test**
   - Expand folders 3-4 levels deep
   - Verify indentation increases per level
   - Verify all actions work at any level

6. **Mobile Test**
   - Test on mobile viewport
   - Verify touch targets are adequate
   - Verify tree is scrollable
   - Test expand/collapse on mobile

---

## Dependencies

**Depends On**:
- Story 01 (Project Setup)
- Story 02 (Core Layout)
- Story 03 (Mock Data & Stores)

**Blocks**:
- Story 05 (Document List) - needs folder selection

---

## Notes

- Consider using Vuetify's v-treeview for simpler implementation
- Custom component gives more control over styling and behavior
- Expanded state could be persisted in localStorage (future enhancement)
- Context menu for folders (rename, delete) can be added later

---

## Resources

- **Vuetify Treeview**: https://vuetifyjs.com/en/components/treeview/
- **Vuetify List**: https://vuetifyjs.com/en/components/lists/
- **Vue Recursive Components**: https://vuejs.org/guide/essentials/component-basics.html#recursive-components
