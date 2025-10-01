# Data Model

## Overview

The document management system uses a multi-storage approach:
- **Cosmos DB**: Metadata, folder structure, tags
- **Azure Blob Storage**: Actual document files
- **Redis Cache**: Temporary data and performance optimization

## Database Schema

### Cosmos DB

**Database**: `DocumentManager`

#### Container: `documents`

**Partition Key**: `/folderId` (for efficient querying by folder)

**Document Schema**:
```json
{
  "id": "doc-abc123",
  "type": "document",
  "name": "Q4 Financial Report",
  "fileName": "Q4-Report.pdf",
  "folderId": "folder-123",
  "folderPath": "/Financial Reports/2024",
  "size": 2048576,
  "contentType": "application/pdf",
  "blobStorageId": "doc-abc123",
  "blobUrl": "https://docmgrstorage.blob.core.windows.net/documents/doc-abc123",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "modifiedAt": "2024-01-15T10:30:00Z",
  "metadata": {
    "author": "John Doe",
    "department": "Finance",
    "year": "2024",
    "quarter": "Q4"
  },
  "tags": ["report", "finance", "2024", "quarterly"],
  "_etag": "\"00000000-0000-0000-0000-000000000000\"",
  "_ts": 1705318200
}
```

**Indexes**:
- Default: All properties indexed
- Composite indexes:
  - `folderId` + `uploadedAt` (DESC) - For folder listing by date
  - `tags` + `uploadedAt` (DESC) - For tag-based searches
- Range indexes: `uploadedAt`, `modifiedAt`, `size`

**TTL**: None (documents persist indefinitely)

#### Container: `folders`

**Partition Key**: `/parentId` (for efficient parent-child queries)

**Document Schema**:
```json
{
  "id": "folder-123",
  "type": "folder",
  "name": "Financial Reports",
  "parentId": null,
  "path": "/Financial Reports",
  "level": 1,
  "description": "All financial reports",
  "createdAt": "2024-01-15T09:00:00Z",
  "modifiedAt": "2024-01-15T09:00:00Z",
  "documentCount": 25,
  "subfolderCount": 3,
  "metadata": {
    "color": "blue",
    "icon": "folder"
  },
  "_etag": "\"00000000-0000-0000-0000-000000000000\"",
  "_ts": 1705314600
}
```

**Special Root Folder**:
```json
{
  "id": "root",
  "type": "folder",
  "name": "Root",
  "parentId": null,
  "path": "/",
  "level": 0,
  "description": "Root folder",
  "createdAt": "2024-01-01T00:00:00Z",
  "modifiedAt": "2024-01-01T00:00:00Z",
  "documentCount": 0,
  "subfolderCount": 0
}
```

**Indexes**:
- Default: All properties indexed
- Composite indexes:
  - `parentId` + `name` (ASC) - For listing subfolders alphabetically
  - `path` (ASC) - For path-based lookups

**Business Rules**:
- Root folder (`id: "root"`) cannot be deleted or modified
- `path` is calculated: parent path + "/" + folder name
- `level` is calculated: parent level + 1
- Max `level`: 10 (enforced in application logic)

#### Container: `tags`

**Partition Key**: `/category` (allows tag grouping/categorization)

**Document Schema**:
```json
{
  "id": "tag-finance",
  "type": "tag",
  "name": "finance",
  "category": "department",
  "displayName": "Finance",
  "description": "Financial documents and reports",
  "color": "#4CAF50",
  "usageCount": 150,
  "createdAt": "2024-01-01T00:00:00Z",
  "lastUsedAt": "2024-01-15T10:30:00Z",
  "_etag": "\"00000000-0000-0000-0000-000000000000\"",
  "_ts": 1705318200
}
```

**Indexes**:
- Default: All properties indexed
- Range index: `usageCount` (DESC) - For popular tags

**Business Rules**:
- Tags are auto-created when first used
- `usageCount` incremented when tag applied to document
- Tag names are case-insensitive (stored lowercase)

### Azure Blob Storage

**Storage Account**: `docmgrstorage`
**Container**: `documents`

**Blob Naming Convention**:
```
{document-id}
```

**Examples**:
```
doc-abc123
doc-def456
doc-xyz789
```

**Blob Metadata** (stored with blob):
```
{
  "DocumentId": "doc-abc123",
  "OriginalFileName": "Q4-Report.pdf",
  "UploadedAt": "2024-01-15T10:30:00Z",
  "ContentType": "application/pdf"
}
```

**Container Configuration**:
- Access Level: Private (no anonymous access)
- Versioning: Enabled
- Soft Delete: 30 days retention
- Lifecycle Management:
  - Move to Cool tier after 90 days of no access
  - Archive after 365 days (future enhancement)

### Redis Cache

**Database**: 0 (default)

**Key Patterns**:

1. **Folder Tree Cache**:
```
Key: folder:tree:{rootId}
Type: String (JSON)
TTL: 300 seconds (5 minutes)
Value:
{
  "id": "folder-123",
  "name": "Financial Reports",
  "children": [...]
}
```

2. **Folder Contents Cache**:
```
Key: folder:contents:{folderId}
Type: String (JSON)
TTL: 180 seconds (3 minutes)
Value:
{
  "folders": [...],
  "documents": [...]
}
```

3. **Document Metadata Cache**:
```
Key: document:{documentId}
Type: String (JSON)
TTL: 600 seconds (10 minutes)
Value: {document object}
```

4. **Search Results Cache**:
```
Key: search:{hash-of-query}
Type: String (JSON)
TTL: 120 seconds (2 minutes)
Value:
{
  "results": [...],
  "total": 25
}
```

5. **User Session** (future):
```
Key: session:{sessionId}
Type: String (JSON)
TTL: 1800 seconds (30 minutes)
Value: {session data}
```

**Cache Invalidation Strategy**:
- Folder tree: Invalidate on folder create/update/delete/move
- Folder contents: Invalidate on document/folder changes within folder
- Document metadata: Invalidate on document update/delete
- Search results: Invalidate on any document changes (or rely on TTL)

## Data Structures

### C# Entity Models (Backend)

#### Document Entity
```csharp
public class Document
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("type")]
    public string Type { get; set; } = "document";

    [JsonProperty("name")]
    public string Name { get; set; }

    [JsonProperty("fileName")]
    public string FileName { get; set; }

    [JsonProperty("folderId")]
    public string FolderId { get; set; }

    [JsonProperty("folderPath")]
    public string FolderPath { get; set; }

    [JsonProperty("size")]
    public long Size { get; set; }

    [JsonProperty("contentType")]
    public string ContentType { get; set; }

    [JsonProperty("blobStorageId")]
    public string BlobStorageId { get; set; }

    [JsonProperty("blobUrl")]
    public string BlobUrl { get; set; }

    [JsonProperty("uploadedAt")]
    public DateTime UploadedAt { get; set; }

    [JsonProperty("modifiedAt")]
    public DateTime ModifiedAt { get; set; }

    [JsonProperty("metadata")]
    public Dictionary<string, object> Metadata { get; set; }

    [JsonProperty("tags")]
    public List<string> Tags { get; set; }
}
```

#### Folder Entity
```csharp
public class Folder
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("type")]
    public string Type { get; set; } = "folder";

    [JsonProperty("name")]
    public string Name { get; set; }

    [JsonProperty("parentId")]
    public string ParentId { get; set; }

    [JsonProperty("path")]
    public string Path { get; set; }

    [JsonProperty("level")]
    public int Level { get; set; }

    [JsonProperty("description")]
    public string Description { get; set; }

    [JsonProperty("createdAt")]
    public DateTime CreatedAt { get; set; }

    [JsonProperty("modifiedAt")]
    public DateTime ModifiedAt { get; set; }

    [JsonProperty("documentCount")]
    public int DocumentCount { get; set; }

    [JsonProperty("subfolderCount")]
    public int SubfolderCount { get; set; }

    [JsonProperty("metadata")]
    public Dictionary<string, object> Metadata { get; set; }
}
```

#### Tag Entity
```csharp
public class Tag
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("type")]
    public string Type { get; set; } = "tag";

    [JsonProperty("name")]
    public string Name { get; set; }

    [JsonProperty("category")]
    public string Category { get; set; }

    [JsonProperty("displayName")]
    public string DisplayName { get; set; }

    [JsonProperty("description")]
    public string Description { get; set; }

    [JsonProperty("color")]
    public string Color { get; set; }

    [JsonProperty("usageCount")]
    public int UsageCount { get; set; }

    [JsonProperty("createdAt")]
    public DateTime CreatedAt { get; set; }

    [JsonProperty("lastUsedAt")]
    public DateTime LastUsedAt { get; set; }
}
```

### TypeScript/JavaScript Models (Frontend - Vue/Pinia)

#### Document Interface
```typescript
export interface Document {
  id: string
  name: string
  fileName: string
  folderId: string
  folderPath?: string
  size: number
  contentType: string
  blobUrl: string
  uploadedAt: string // ISO 8601
  modifiedAt: string // ISO 8601
  metadata: Record<string, any>
  tags: string[]
}
```

#### Folder Interface
```typescript
export interface Folder {
  id: string
  name: string
  parentId: string | null
  path: string
  level?: number
  description?: string
  createdAt: string // ISO 8601
  modifiedAt: string // ISO 8601
  documentCount: number
  subfolderCount: number
  metadata?: Record<string, any>
  children?: Folder[] // For tree structure
}
```

#### Tag Interface
```typescript
export interface Tag {
  id: string
  name: string
  category?: string
  displayName: string
  description?: string
  color?: string
  usageCount?: number
}
```

#### FolderTreeNode Interface
```typescript
export interface FolderTreeNode {
  id: string
  name: string
  parentId: string | null
  path: string
  documentCount: number
  subfolderCount: number
  children: FolderTreeNode[]
  isExpanded?: boolean // UI state
  isLoading?: boolean // UI state
}
```

## Data Relationships

### Entity Relationship Diagram

```
┌─────────────────┐
│     Folder      │
│  (Cosmos DB)    │
│                 │
│ - id            │
│ - name          │
│ - parentId ────┼──┐ Self-referencing
│ - path          │  │ (parent-child)
│ - level         │  │
└────────┬────────┘  │
         │           │
         │ 1:N       │
         │           │
         ▼           │
┌─────────────────┐  │
│    Document     │  │
│  (Cosmos DB)    │  │
│                 │  │
│ - id            │  │
│ - folderId ─────┼──┘
│ - blobStorageId │
│ - tags[]        │
└────────┬────────┘
         │
         │ References
         │
         ▼
┌─────────────────┐
│   Blob File     │
│ (Blob Storage)  │
│                 │
│ - {documentId}  │
│ - binary data   │
└─────────────────┘

         ┌──────────────┐
         │     Tag      │
         │ (Cosmos DB)  │
         │              │
         │ - id         │
         │ - name       │
         │ - usageCount │
         └──────────────┘
         ▲
         │
         │ Referenced by
         │ document.tags[]
```

### Relationship Rules

**Folder → Folder** (Parent-Child):
- One folder can have many child folders
- Each folder has one parent (except root)
- Cascade delete: Deleting parent folder can delete children (with force flag)

**Folder → Document** (One-to-Many):
- One folder can contain many documents
- Each document belongs to exactly one folder
- Cascade delete: Deleting folder can delete documents (with force flag)

**Document → Blob** (One-to-One):
- Each document references exactly one blob
- Each blob is referenced by exactly one document
- Cascade delete: Deleting document deletes corresponding blob

**Document → Tags** (Many-to-Many):
- One document can have many tags
- One tag can be applied to many documents
- No cascade delete: Deleting document doesn't delete tags
- Soft relationship: Tags stored as array in document

## Data Validation & Constraints

### Document Constraints
```
- id: Required, unique, format: "doc-{guid}"
- name: Required, max 255 chars
- fileName: Required, max 255 chars
- folderId: Required, must exist in folders container
- size: Required, min 0, max 5GB (5,368,709,120 bytes)
- contentType: Required
- blobStorageId: Required, unique
- blobUrl: Required, valid URL
- uploadedAt: Required, ISO 8601
- modifiedAt: Required, ISO 8601, >= uploadedAt
- metadata: Optional, max 20 key-value pairs
- tags: Optional, max 50 tags, each tag max 50 chars
```

### Folder Constraints
```
- id: Required, unique, format: "folder-{guid}" or "root"
- name: Required, max 100 chars
- parentId: Optional (null for root), must exist in folders container
- path: Required, unique, max 1000 chars
- level: Required, min 0, max 10
- description: Optional, max 500 chars
- createdAt: Required, ISO 8601
- modifiedAt: Required, ISO 8601, >= createdAt
- documentCount: Required, min 0
- subfolderCount: Required, min 0
```

### Tag Constraints
```
- id: Required, unique, format: "tag-{name}"
- name: Required, lowercase, max 50 chars, alphanumeric + hyphen
- category: Optional, max 50 chars
- displayName: Required, max 50 chars
- color: Optional, hex color format
- usageCount: Required, min 0
- createdAt: Required, ISO 8601
- lastUsedAt: Required, ISO 8601
```

## Cosmos DB Query Examples

### Get all documents in a folder
```sql
SELECT * FROM documents d
WHERE d.folderId = 'folder-123'
ORDER BY d.uploadedAt DESC
```

### Get folder tree (all children of a folder)
```sql
SELECT * FROM folders f
WHERE STARTSWITH(f.path, '/Financial Reports/')
ORDER BY f.path ASC
```

### Search documents by tag
```sql
SELECT * FROM documents d
WHERE ARRAY_CONTAINS(d.tags, 'finance')
ORDER BY d.uploadedAt DESC
```

### Get popular tags
```sql
SELECT * FROM tags t
ORDER BY t.usageCount DESC
OFFSET 0 LIMIT 20
```

### Count documents by folder
```sql
SELECT d.folderId, COUNT(1) as count
FROM documents d
GROUP BY d.folderId
```
