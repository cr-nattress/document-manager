# API Endpoint Map

**Purpose:** Shows the complete REST API structure and endpoint organization

**Last Updated:** 2025-09-30

**Version:** 1.0.0

## API Endpoint Tree Structure

```
/api
├── /documents
│   ├── POST      /                      Upload document
│   ├── GET       /                      List documents (with filters)
│   ├── GET       /{id}                  Get document metadata
│   ├── GET       /{id}/download         Download document file
│   ├── PUT       /{id}                  Update document metadata
│   ├── DELETE    /{id}                  Delete document
│   └── PATCH     /{id}/move             Move document to folder
│
├── /folders
│   ├── POST      /                      Create folder
│   ├── GET       /                      List all folders
│   ├── GET       /{id}                  Get folder details
│   ├── GET       /tree                  Get folder tree structure
│   ├── GET       /{id}/contents         Get folder contents
│   ├── PUT       /{id}                  Update folder
│   ├── DELETE    /{id}                  Delete folder
│   └── PATCH     /{id}/move             Move folder to different parent
│
└── /search
    └── GET       /                      Search documents
```

## API Endpoint Details Map

```mermaid
graph TB
    subgraph "Document Management API"
        DOCROOT[/api/documents]

        DOCUPLOAD[POST /<br/>Upload Document<br/>multipart/form-data<br/>Auth: Required<br/>Returns: 201]

        DOCLIST[GET /<br/>List Documents<br/>Query: folderId, limit, offset<br/>Auth: Required<br/>Returns: 200]

        DOCGET[GET /{id}<br/>Get Document Metadata<br/>Params: id<br/>Auth: Required<br/>Returns: 200]

        DOCDOWNLOAD[GET /{id}/download<br/>Download Document<br/>Params: id<br/>Auth: Required<br/>Returns: 200 + Blob URL]

        DOCUPDATE[PUT /{id}<br/>Update Metadata<br/>Body: name, metadata, tags<br/>Auth: Required<br/>Returns: 200]

        DOCDELETE[DELETE /{id}<br/>Delete Document<br/>Params: id<br/>Auth: Required<br/>Returns: 204]

        DOCMOVE[PATCH /{id}/move<br/>Move to Folder<br/>Body: targetFolderId<br/>Auth: Required<br/>Returns: 200]

        DOCROOT --> DOCUPLOAD
        DOCROOT --> DOCLIST
        DOCROOT --> DOCGET
        DOCROOT --> DOCDOWNLOAD
        DOCROOT --> DOCUPDATE
        DOCROOT --> DOCDELETE
        DOCROOT --> DOCMOVE
    end

    subgraph "Folder Management API"
        FOLDROOT[/api/folders]

        FOLDCREATE[POST /<br/>Create Folder<br/>Body: name, parentId, description<br/>Auth: Required<br/>Returns: 201]

        FOLDLIST[GET /<br/>List All Folders<br/>Query: parentId optional<br/>Auth: Required<br/>Returns: 200]

        FOLDGET[GET /{id}<br/>Get Folder Details<br/>Params: id<br/>Auth: Required<br/>Returns: 200]

        FOLDTREE[GET /tree<br/>Get Tree Structure<br/>Query: rootId optional<br/>Auth: Required<br/>Returns: 200]

        FOLDCONTENTS[GET /{id}/contents<br/>Get Folder Contents<br/>Params: id<br/>Auth: Required<br/>Returns: 200]

        FOLDUPDATE[PUT /{id}<br/>Update Folder<br/>Body: name, description<br/>Auth: Required<br/>Returns: 200]

        FOLDDELETE[DELETE /{id}<br/>Delete Folder<br/>Params: id, Query: force<br/>Auth: Required<br/>Returns: 204]

        FOLDMOVE[PATCH /{id}/move<br/>Move to Parent<br/>Body: targetParentId<br/>Auth: Required<br/>Returns: 200]

        FOLDROOT --> FOLDCREATE
        FOLDROOT --> FOLDLIST
        FOLDROOT --> FOLDGET
        FOLDROOT --> FOLDTREE
        FOLDROOT --> FOLDCONTENTS
        FOLDROOT --> FOLDUPDATE
        FOLDROOT --> FOLDDELETE
        FOLDROOT --> FOLDMOVE
    end

    subgraph "Search API"
        SEARCHROOT[/api/search]

        SEARCHDOCS[GET /<br/>Search Documents<br/>Query: q, tags, folderId, limit<br/>Auth: Required<br/>Returns: 200]

        SEARCHROOT --> SEARCHDOCS
    end

    classDef rootStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef postStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef getStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef putStyle fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    classDef deleteStyle fill:#ffccbc,stroke:#d84315,stroke-width:2px
    classDef patchStyle fill:#b2dfdb,stroke:#00695c,stroke-width:2px

    class DOCROOT,FOLDROOT,SEARCHROOT rootStyle
    class DOCUPLOAD,FOLDCREATE postStyle
    class DOCLIST,DOCGET,DOCDOWNLOAD,FOLDLIST,FOLDGET,FOLDTREE,FOLDCONTENTS,SEARCHDOCS getStyle
    class DOCUPDATE,FOLDUPDATE putStyle
    class DOCDELETE,FOLDDELETE deleteStyle
    class DOCMOVE,FOLDMOVE patchStyle
```

## API Endpoint Matrix

| Endpoint | Method | Purpose | Auth | Request Body | Query Params | Success | Error Codes |
|----------|--------|---------|------|--------------|--------------|---------|-------------|
| `/api/documents` | POST | Upload document | Required | multipart/form-data | - | 201 | 400, 401, 413, 500 |
| `/api/documents` | GET | List documents | Required | - | folderId, limit, offset | 200 | 401, 500 |
| `/api/documents/{id}` | GET | Get metadata | Required | - | - | 200 | 401, 404, 500 |
| `/api/documents/{id}/download` | GET | Download file | Required | - | - | 200 | 401, 404, 500 |
| `/api/documents/{id}` | PUT | Update metadata | Required | JSON | - | 200 | 400, 401, 404, 500 |
| `/api/documents/{id}` | DELETE | Delete document | Required | - | - | 204 | 401, 404, 500 |
| `/api/documents/{id}/move` | PATCH | Move to folder | Required | JSON | - | 200 | 400, 401, 404, 409, 500 |
| `/api/folders` | POST | Create folder | Required | JSON | - | 201 | 400, 401, 409, 500 |
| `/api/folders` | GET | List folders | Required | - | parentId | 200 | 401, 500 |
| `/api/folders/{id}` | GET | Get folder | Required | - | - | 200 | 401, 404, 500 |
| `/api/folders/tree` | GET | Get tree | Required | - | rootId | 200 | 401, 500 |
| `/api/folders/{id}/contents` | GET | Get contents | Required | - | - | 200 | 401, 404, 500 |
| `/api/folders/{id}` | PUT | Update folder | Required | JSON | - | 200 | 400, 401, 404, 500 |
| `/api/folders/{id}` | DELETE | Delete folder | Required | - | force | 204 | 401, 404, 409, 500 |
| `/api/folders/{id}/move` | PATCH | Move folder | Required | JSON | - | 200 | 400, 401, 404, 409, 500 |
| `/api/search` | GET | Search documents | Required | - | q, tags, folderId, limit | 200 | 400, 401, 500 |

## Request/Response Examples

### 1. Upload Document

**Request**:
```http
POST /api/documents HTTP/1.1
Host: api.docmanager.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary
X-API-Key: your-api-key-here

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="report.pdf"
Content-Type: application/pdf

[binary file content]
------WebKitFormBoundary
Content-Disposition: form-data; name="folderId"

folder-abc123
------WebKitFormBoundary
Content-Disposition: form-data; name="name"

Q4 Financial Report
------WebKitFormBoundary
Content-Disposition: form-data; name="metadata"

{"author":"John Doe","year":"2024"}
------WebKitFormBoundary
Content-Disposition: form-data; name="tags"

["finance","report","2024"]
------WebKitFormBoundary--
```

**Response (201 Created)**:
```json
{
  "id": "doc-xyz789",
  "name": "Q4 Financial Report",
  "fileName": "report.pdf",
  "folderId": "folder-abc123",
  "folderPath": "/Financial Reports",
  "size": 2048576,
  "contentType": "application/pdf",
  "blobUrl": "https://docmgrstorage.blob.core.windows.net/documents/doc-xyz789",
  "uploadedAt": "2024-01-20T10:30:00Z",
  "modifiedAt": "2024-01-20T10:30:00Z",
  "metadata": {
    "author": "John Doe",
    "year": "2024"
  },
  "tags": ["finance", "report", "2024"]
}
```

### 2. Get Folder Tree

**Request**:
```http
GET /api/folders/tree HTTP/1.1
Host: api.docmanager.com
X-API-Key: your-api-key-here
```

**Response (200 OK)**:
```json
{
  "id": "root",
  "name": "Root",
  "path": "/",
  "documentCount": 0,
  "subfolderCount": 3,
  "children": [
    {
      "id": "folder-abc123",
      "name": "Financial Reports",
      "path": "/Financial Reports",
      "documentCount": 25,
      "subfolderCount": 2,
      "children": [
        {
          "id": "folder-def456",
          "name": "2024",
          "path": "/Financial Reports/2024",
          "documentCount": 12,
          "subfolderCount": 0,
          "children": []
        },
        {
          "id": "folder-ghi789",
          "name": "2023",
          "path": "/Financial Reports/2023",
          "documentCount": 13,
          "subfolderCount": 0,
          "children": []
        }
      ]
    },
    {
      "id": "folder-jkl012",
      "name": "HR Documents",
      "path": "/HR Documents",
      "documentCount": 8,
      "subfolderCount": 0,
      "children": []
    },
    {
      "id": "folder-mno345",
      "name": "Marketing",
      "path": "/Marketing",
      "documentCount": 15,
      "subfolderCount": 1,
      "children": [
        {
          "id": "folder-pqr678",
          "name": "Campaigns",
          "path": "/Marketing/Campaigns",
          "documentCount": 10,
          "subfolderCount": 0,
          "children": []
        }
      ]
    }
  ]
}
```

### 3. Search Documents

**Request**:
```http
GET /api/search?q=financial&tags=report,2024&folderId=folder-abc123&limit=10 HTTP/1.1
Host: api.docmanager.com
X-API-Key: your-api-key-here
```

**Response (200 OK)**:
```json
{
  "results": [
    {
      "id": "doc-xyz789",
      "name": "Q4 Financial Report",
      "fileName": "report.pdf",
      "folderId": "folder-abc123",
      "folderPath": "/Financial Reports",
      "size": 2048576,
      "contentType": "application/pdf",
      "uploadedAt": "2024-01-20T10:30:00Z",
      "tags": ["finance", "report", "2024"],
      "relevanceScore": 0.95
    },
    {
      "id": "doc-abc123",
      "name": "Q3 Financial Report",
      "fileName": "q3-report.pdf",
      "folderId": "folder-abc123",
      "folderPath": "/Financial Reports",
      "size": 1876543,
      "contentType": "application/pdf",
      "uploadedAt": "2024-10-15T14:20:00Z",
      "tags": ["finance", "report", "2024"],
      "relevanceScore": 0.87
    }
  ],
  "total": 2,
  "page": 1,
  "pageSize": 10
}
```

### 4. Move Document

**Request**:
```http
PATCH /api/documents/doc-xyz789/move HTTP/1.1
Host: api.docmanager.com
Content-Type: application/json
X-API-Key: your-api-key-here

{
  "targetFolderId": "folder-new123"
}
```

**Response (200 OK)**:
```json
{
  "id": "doc-xyz789",
  "name": "Q4 Financial Report",
  "fileName": "report.pdf",
  "folderId": "folder-new123",
  "folderPath": "/Archive/2024",
  "size": 2048576,
  "contentType": "application/pdf",
  "uploadedAt": "2024-01-20T10:30:00Z",
  "modifiedAt": "2024-01-25T16:45:00Z",
  "metadata": {
    "author": "John Doe",
    "year": "2024"
  },
  "tags": ["finance", "report", "2024"]
}
```

## HTTP Status Codes

### Success Codes
- **200 OK**: Request successful, resource retrieved or updated
- **201 Created**: Resource successfully created (POST operations)
- **204 No Content**: Request successful, no content to return (DELETE operations)

### Client Error Codes
- **400 Bad Request**: Invalid request format or parameters
- **401 Unauthorized**: Missing or invalid API key
- **404 Not Found**: Resource not found
- **409 Conflict**: Resource conflict (duplicate name, invalid move)
- **413 Payload Too Large**: File size exceeds 5GB limit
- **429 Too Many Requests**: Rate limit exceeded

### Server Error Codes
- **500 Internal Server Error**: Unexpected server error
- **502 Bad Gateway**: Upstream service error
- **503 Service Unavailable**: Service temporarily unavailable
- **504 Gateway Timeout**: Request timeout (>30 seconds)

## Authentication

All API endpoints require authentication using one of the following methods:

### API Key Header
```http
X-API-Key: your-api-key-here
```

### Bearer Token (Alternative)
```http
Authorization: Bearer your-token-here
```

## Rate Limiting

**Limits** (per API key):
- **Development**: 100 requests/minute
- **Production**: 1000 requests/minute

**Response Headers**:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1642694400
```

**Rate Limit Exceeded Response (429)**:
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again later.",
  "retryAfter": 60
}
```

## Error Response Format

All error responses follow this format:

```json
{
  "error": "Error category",
  "message": "Human-readable error message",
  "details": {
    "field": "Specific field that caused error",
    "reason": "Detailed reason"
  },
  "requestId": "req-abc123",
  "timestamp": "2024-01-20T10:30:00Z"
}
```

**Examples**:

**400 Bad Request**:
```json
{
  "error": "Validation error",
  "message": "File size exceeds maximum allowed",
  "details": {
    "maxSize": 5368709120,
    "actualSize": 6000000000
  },
  "requestId": "req-abc123",
  "timestamp": "2024-01-20T10:30:00Z"
}
```

**404 Not Found**:
```json
{
  "error": "Resource not found",
  "message": "Document not found",
  "details": {
    "id": "doc-xyz789"
  },
  "requestId": "req-def456",
  "timestamp": "2024-01-20T10:31:00Z"
}
```

**409 Conflict**:
```json
{
  "error": "Conflict",
  "message": "Folder name already exists",
  "details": {
    "name": "Financial Reports",
    "parentId": "root"
  },
  "requestId": "req-ghi789",
  "timestamp": "2024-01-20T10:32:00Z"
}
```

## API Versioning

Currently using **v1** (implicit in base URL).

Future versions will use explicit versioning:
```
/api/v2/documents
```

## CORS Configuration

**Allowed Origins** (configurable):
- Development: `http://localhost:3000`, `http://localhost:5173`
- Staging: `https://staging.docmanager.com`
- Production: `https://app.docmanager.com`

**Allowed Methods**: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`

**Allowed Headers**: `Content-Type`, `X-API-Key`, `Authorization`

**Max Age**: 3600 seconds (1 hour)

## Pagination

Endpoints that return lists support pagination:

**Query Parameters**:
- `limit`: Number of items per page (default: 50, max: 100)
- `offset`: Number of items to skip (default: 0)

**Response Format**:
```json
{
  "results": [...],
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0,
    "hasNext": true,
    "nextOffset": 50
  }
}
```

## Sorting

List endpoints support sorting:

**Query Parameter**:
- `sortBy`: Field name (e.g., `name`, `uploadedAt`, `size`)
- `sortOrder`: `asc` or `desc` (default: `asc`)

**Example**:
```http
GET /api/documents?sortBy=uploadedAt&sortOrder=desc
```

## Filtering

Document list endpoint supports filtering:

**Query Parameters**:
- `folderId`: Filter by folder
- `tags`: Comma-separated list of tags
- `contentType`: Filter by MIME type
- `minSize`: Minimum file size in bytes
- `maxSize`: Maximum file size in bytes
- `uploadedAfter`: ISO 8601 date
- `uploadedBefore`: ISO 8601 date

**Example**:
```http
GET /api/documents?folderId=folder-abc123&tags=finance,report&uploadedAfter=2024-01-01T00:00:00Z
```

## Notes

- All timestamps in ISO 8601 format (UTC)
- All endpoints return JSON (except file downloads)
- File downloads return blob URL with SAS token (not direct stream)
- Maximum request size: 5GB (for file uploads)
- Request timeout: 30 seconds
- All operations logged to Application Insights
- Idempotency: PUT and DELETE operations are idempotent
