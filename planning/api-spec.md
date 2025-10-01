# API Specification

## Base URL
```
Development: https://docmgr-func-dev-eastus.azurewebsites.net
Staging: https://docmgr-func-staging-eastus.azurewebsites.net
Production: https://docmgr-func-prod-eastus.azurewebsites.net
```

## Authentication
All API requests require authentication via API key in the request header:
```
X-API-Key: <api-key>
```

**Unauthorized Response (401)**:
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing API key"
}
```

## Common Response Codes
- `200 OK` - Successful request
- `201 Created` - Resource created successfully
- `204 No Content` - Successful request with no content to return
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid API key
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

## Endpoints

### Document Management

#### 1. Upload Document
**POST** `/api/documents`

Upload a new document to a specific folder.

**Request Headers**:
```
Content-Type: multipart/form-data
X-API-Key: <api-key>
```

**Request Body** (multipart/form-data):
```
file: <binary file>
folderId: string (optional, defaults to root)
name: string (optional, uses filename if not provided)
metadata: JSON string (optional)
tags: JSON array of strings (optional)
```

**Example**:
```
file: document.pdf
folderId: "folder-123"
name: "Q4 Report"
metadata: '{"author": "John Doe", "department": "Finance"}'
tags: '["report", "2024", "finance"]'
```

**Response (201)**:
```json
{
  "id": "doc-abc123",
  "name": "Q4 Report",
  "fileName": "document.pdf",
  "folderId": "folder-123",
  "size": 2048576,
  "contentType": "application/pdf",
  "blobUrl": "https://storage.blob.core.windows.net/documents/doc-abc123",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "metadata": {
    "author": "John Doe",
    "department": "Finance"
  },
  "tags": ["report", "2024", "finance"]
}
```

#### 2. Get Document
**GET** `/api/documents/{id}`

Retrieve document metadata by ID.

**Response (200)**:
```json
{
  "id": "doc-abc123",
  "name": "Q4 Report",
  "fileName": "document.pdf",
  "folderId": "folder-123",
  "size": 2048576,
  "contentType": "application/pdf",
  "blobUrl": "https://storage.blob.core.windows.net/documents/doc-abc123",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "modifiedAt": "2024-01-15T10:30:00Z",
  "metadata": {
    "author": "John Doe",
    "department": "Finance"
  },
  "tags": ["report", "2024", "finance"]
}
```

#### 3. Download Document
**GET** `/api/documents/{id}/download`

Download the actual document file.

**Response (200)**:
- Binary file stream
- Headers:
  ```
  Content-Type: application/pdf (or appropriate type)
  Content-Disposition: attachment; filename="document.pdf"
  Content-Length: 2048576
  ```

#### 4. Update Document Metadata
**PUT** `/api/documents/{id}`

Update document name, metadata, or tags (does not update file content).

**Request Body**:
```json
{
  "name": "Q4 Financial Report",
  "metadata": {
    "author": "John Doe",
    "department": "Finance",
    "year": "2024"
  },
  "tags": ["report", "2024", "finance", "quarterly"]
}
```

**Response (200)**:
```json
{
  "id": "doc-abc123",
  "name": "Q4 Financial Report",
  "fileName": "document.pdf",
  "folderId": "folder-123",
  "size": 2048576,
  "contentType": "application/pdf",
  "blobUrl": "https://storage.blob.core.windows.net/documents/doc-abc123",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "modifiedAt": "2024-01-15T11:00:00Z",
  "metadata": {
    "author": "John Doe",
    "department": "Finance",
    "year": "2024"
  },
  "tags": ["report", "2024", "finance", "quarterly"]
}
```

#### 5. Delete Document
**DELETE** `/api/documents/{id}`

Delete a document and its file from blob storage.

**Response (204)**:
- No content

#### 6. List Documents
**GET** `/api/documents`

List all documents or filter by folder.

**Query Parameters**:
- `folderId` (optional) - Filter by folder ID
- `tags` (optional) - Comma-separated tags to filter by
- `limit` (optional, default: 100) - Number of results
- `offset` (optional, default: 0) - Pagination offset

**Example**:
```
GET /api/documents?folderId=folder-123&limit=50&offset=0
```

**Response (200)**:
```json
{
  "documents": [
    {
      "id": "doc-abc123",
      "name": "Q4 Report",
      "fileName": "document.pdf",
      "folderId": "folder-123",
      "size": 2048576,
      "contentType": "application/pdf",
      "uploadedAt": "2024-01-15T10:30:00Z",
      "tags": ["report", "2024", "finance"]
    }
  ],
  "total": 150,
  "limit": 50,
  "offset": 0
}
```

#### 7. Move Document
**PATCH** `/api/documents/{id}/move`

Move a document to a different folder.

**Request Body**:
```json
{
  "targetFolderId": "folder-456"
}
```

**Response (200)**:
```json
{
  "id": "doc-abc123",
  "name": "Q4 Report",
  "folderId": "folder-456",
  "movedAt": "2024-01-15T12:00:00Z"
}
```

### Folder Management

#### 8. Create Folder
**POST** `/api/folders`

Create a new folder.

**Request Body**:
```json
{
  "name": "Financial Reports",
  "parentId": null,
  "description": "All financial reports"
}
```
- `parentId`: null for root-level folder, or parent folder ID for nested folder

**Response (201)**:
```json
{
  "id": "folder-123",
  "name": "Financial Reports",
  "parentId": null,
  "path": "/Financial Reports",
  "description": "All financial reports",
  "createdAt": "2024-01-15T09:00:00Z",
  "modifiedAt": "2024-01-15T09:00:00Z",
  "documentCount": 0,
  "subfolderCount": 0
}
```

#### 9. Get Folder
**GET** `/api/folders/{id}`

Get folder details including document and subfolder counts.

**Response (200)**:
```json
{
  "id": "folder-123",
  "name": "Financial Reports",
  "parentId": null,
  "path": "/Financial Reports",
  "description": "All financial reports",
  "createdAt": "2024-01-15T09:00:00Z",
  "modifiedAt": "2024-01-15T09:00:00Z",
  "documentCount": 25,
  "subfolderCount": 3
}
```

#### 10. Get Folder Tree
**GET** `/api/folders/tree`

Get complete folder hierarchy (tree structure).

**Query Parameters**:
- `rootId` (optional) - Start from specific folder (default: root)
- `depth` (optional) - Maximum depth to retrieve (default: unlimited)

**Response (200)**:
```json
{
  "folders": [
    {
      "id": "folder-root",
      "name": "Root",
      "parentId": null,
      "path": "/",
      "children": [
        {
          "id": "folder-123",
          "name": "Financial Reports",
          "parentId": "folder-root",
          "path": "/Financial Reports",
          "documentCount": 25,
          "children": [
            {
              "id": "folder-456",
              "name": "2024",
              "parentId": "folder-123",
              "path": "/Financial Reports/2024",
              "documentCount": 10,
              "children": []
            }
          ]
        }
      ]
    }
  ]
}
```

#### 11. Update Folder
**PUT** `/api/folders/{id}`

Update folder name or description.

**Request Body**:
```json
{
  "name": "Financial Reports 2024",
  "description": "All financial reports for 2024"
}
```

**Response (200)**:
```json
{
  "id": "folder-123",
  "name": "Financial Reports 2024",
  "parentId": null,
  "path": "/Financial Reports 2024",
  "description": "All financial reports for 2024",
  "modifiedAt": "2024-01-15T10:00:00Z"
}
```

#### 12. Delete Folder
**DELETE** `/api/folders/{id}`

Delete a folder (must be empty or use force parameter).

**Query Parameters**:
- `force` (optional, default: false) - If true, delete folder and all contents

**Response (204)**:
- No content

**Error (400)** if folder not empty and force=false:
```json
{
  "error": "FolderNotEmpty",
  "message": "Cannot delete folder with documents or subfolders. Use force=true to delete all contents."
}
```

#### 13. Move Folder
**PATCH** `/api/folders/{id}/move`

Move a folder to a different parent folder.

**Request Body**:
```json
{
  "targetParentId": "folder-789"
}
```
- `targetParentId`: null to move to root level

**Response (200)**:
```json
{
  "id": "folder-123",
  "name": "Financial Reports",
  "parentId": "folder-789",
  "path": "/Archive/Financial Reports",
  "movedAt": "2024-01-15T11:00:00Z"
}
```

#### 14. List Folder Contents
**GET** `/api/folders/{id}/contents`

List all documents and subfolders within a folder.

**Query Parameters**:
- `limit` (optional, default: 100)
- `offset` (optional, default: 0)

**Response (200)**:
```json
{
  "folderId": "folder-123",
  "folders": [
    {
      "id": "folder-456",
      "name": "2024",
      "documentCount": 10,
      "subfolderCount": 2
    }
  ],
  "documents": [
    {
      "id": "doc-abc123",
      "name": "Q4 Report",
      "size": 2048576,
      "uploadedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "total": {
    "folders": 1,
    "documents": 25
  }
}
```

### Search

#### 15. Search Documents
**GET** `/api/search`

Search documents by name, metadata, or tags.

**Query Parameters**:
- `query` (required) - Search term
- `folderId` (optional) - Limit search to folder
- `tags` (optional) - Comma-separated tags
- `limit` (optional, default: 50)
- `offset` (optional, default: 0)

**Example**:
```
GET /api/search?query=report&tags=finance,2024&limit=20
```

**Response (200)**:
```json
{
  "results": [
    {
      "id": "doc-abc123",
      "name": "Q4 Financial Report",
      "fileName": "document.pdf",
      "folderId": "folder-123",
      "folderPath": "/Financial Reports/2024",
      "size": 2048576,
      "uploadedAt": "2024-01-15T10:30:00Z",
      "tags": ["report", "2024", "finance"],
      "relevanceScore": 0.95
    }
  ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

## Request/Response Formats

### Common Data Models

#### Document Object
```json
{
  "id": "string",
  "name": "string",
  "fileName": "string",
  "folderId": "string",
  "size": "number (bytes)",
  "contentType": "string",
  "blobUrl": "string",
  "uploadedAt": "ISO 8601 datetime",
  "modifiedAt": "ISO 8601 datetime",
  "metadata": "object (key-value pairs)",
  "tags": "array of strings"
}
```

#### Folder Object
```json
{
  "id": "string",
  "name": "string",
  "parentId": "string or null",
  "path": "string",
  "description": "string",
  "createdAt": "ISO 8601 datetime",
  "modifiedAt": "ISO 8601 datetime",
  "documentCount": "number",
  "subfolderCount": "number"
}
```

#### Error Response
```json
{
  "error": "string (error code)",
  "message": "string (human-readable message)",
  "details": "object (optional additional details)"
}
```

### Validation Rules

**Document Upload**:
- File size: Max 5GB per file
- Supported file types: All (no restrictions for POC)
- Name: Max 255 characters
- Tags: Max 50 tags per document
- Metadata: Max 20 key-value pairs

**Folder**:
- Name: Max 100 characters, required
- Path depth: Max 10 levels of nesting
- Description: Max 500 characters

### Pagination
All list endpoints support pagination with:
- `limit`: Number of items (max 1000)
- `offset`: Number of items to skip

Response includes:
- `total`: Total number of items
- `limit`: Current limit
- `offset`: Current offset

### Rate Limiting
- 1000 requests per minute per API key
- Response headers:
  ```
  X-RateLimit-Limit: 1000
  X-RateLimit-Remaining: 950
  X-RateLimit-Reset: 1642252800
  ```

**Rate Limit Exceeded (429)**:
```json
{
  "error": "RateLimitExceeded",
  "message": "Too many requests. Please try again later.",
  "retryAfter": 60
}
```
