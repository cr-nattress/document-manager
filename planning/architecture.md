# Architecture

## System Architecture

### Overview
Cloud-native document management system built on Azure with a serverless backend and modern SPA frontend.

### Architecture Diagram (Logical)
```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                            │
│  Vue 3 + Vuetify + Pinia (SPA)                             │
│  - Document UI                                              │
│  - Folder Tree Navigation                                   │
│  - Metadata/Tag Management                                  │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTPS/REST API
┌─────────────────▼───────────────────────────────────────────┐
│                    Azure Functions (C#)                     │
│  - Document CRUD Operations                                 │
│  - Folder Management                                        │
│  - Metadata/Tag Operations                                  │
│  - Search & Query                                           │
└───┬─────────────┬─────────────┬────────────────────────┬────┘
    │             │             │                        │
    ▼             ▼             ▼                        ▼
┌────────┐  ┌──────────┐  ┌─────────┐           ┌──────────┐
│ Cosmos │  │   Blob   │  │  Redis  │           │  Azure   │
│   DB   │  │ Storage  │  │  Cache  │           │ Services │
│        │  │          │  │         │           │          │
└────────┘  └──────────┘  └─────────┘           └──────────┘
 Metadata    Documents     Sessions/             Monitoring
   Tags       Files        Cache                 Identity
  Folders                                        etc.
```

### Components

#### Frontend Layer
- **Technology**: Vue 3 SPA (Composition API with `<script setup>`)
- **UI Framework**: Vuetify 3 (Material Design)
- **State Management**: Pinia (with advanced patterns)
  - Request caching (5-minute TTL)
  - Optimistic updates with rollback
  - Batch operations
  - AbortController for request cancellation
  - Pinia plugins (persist, router injection)
- **Testing**: Vitest + Vue Test Utils + Playwright
- **Responsibilities**:
  - Document upload/download interface
  - Dynamic folder tree visualization
  - Metadata and tag management UI
  - Search and filter capabilities
  - Responsive mobile/desktop layouts
  - Theme management (light/dark mode)
  - Global UI state (modals, loading, notifications)

#### API Layer (Azure Functions)
- **Technology**: C# Azure Functions (HTTP Triggered)
- **Hosting**: Azure Functions Premium or Consumption Plan
- **Endpoints**:
  - `/api/documents/*` - Document CRUD operations
  - `/api/folders/*` - Folder structure management
  - `/api/metadata/*` - Metadata and tag operations
  - `/api/search/*` - Search and query functionality
- **Responsibilities**:
  - Business logic execution
  - Input validation
  - Azure service orchestration
  - Caching layer interaction
  - API authentication

#### Data Layer

**Cosmos DB**
- **Purpose**: Metadata storage
- **Data Stored**:
  - Document metadata (name, size, type, upload date, etc.)
  - Folder hierarchy structure
  - Tags and custom metadata fields
  - Document-to-blob references
- **Container Design**:
  - `documents` - Document metadata
  - `folders` - Folder structure
  - `tags` - Tag definitions and mappings
- **Partitioning**: By folder path or document type

**Azure Blob Storage**
- **Purpose**: Document file storage
- **Container Strategy**:
  - Hot tier for frequently accessed documents
  - Cool/Archive tier for older documents (future)
- **Structure**: Organized by document ID or folder path
- **Features**: Large file support, streaming uploads/downloads

**Redis Cache**
- **Purpose**: Performance optimization
- **Cached Data**:
  - Frequently accessed folder structures
  - Document metadata for recent queries
  - Search results
  - Session data (if needed)
- **Strategy**: Cache-aside pattern with TTL

#### Azure Services
- **Azure App Service** (optional): Host Functions or separate API
- **Azure Key Vault**: Store secrets, connection strings, API keys
- **Azure Monitor**: Logging and monitoring
- **Azure Application Insights**: Performance tracking
- **Managed Identity**: Secure Azure resource access

## Tech Stack

### Frontend
- **Framework**: Vue 3 (Composition API with `<script setup>`)
- **UI Library**: Vuetify 3 (Material Design)
- **State Management**: Pinia (with plugins and advanced patterns)
- **Build Tool**: Vite
- **HTTP Client**: Axios (with interceptors for CSRF, auth)
- **Languages**: TypeScript (strict mode), JavaScript, HTML, CSS
- **Validation**: Zod schemas
- **Sanitization**: DOMPurify
- **Testing**:
  - Vitest (unit/component tests)
  - Playwright (E2E tests)
  - Vue Test Utils (component testing)
  - @faker-js/faker (test data generation)
- **Code Quality**:
  - ESLint + TypeScript ESLint
  - File size limits enforced (components: 200 lines, composables: 100 lines)
  - 80%+ test coverage required

### Backend
- **Runtime**: .NET 8 (or .NET 7)
- **Framework**: Azure Functions v4
- **Language**: C# 12
- **Azure SDKs**:
  - Azure.Storage.Blobs
  - Microsoft.Azure.Cosmos
  - StackExchange.Redis

### Data Storage
- **Document Storage**: Azure Blob Storage
- **Metadata Database**: Azure Cosmos DB (NoSQL)
- **Cache**: Azure Cache for Redis

### DevOps & Infrastructure
- **Deployment**: Azure DevOps / GitHub Actions
- **IaC**: ARM Templates or Bicep
- **Monitoring**: Azure Monitor + Application Insights
- **Secret Management**: Azure Key Vault

## Design Decisions

### 1. Serverless Architecture (Azure Functions)
**Rationale**:
- Auto-scaling for high performance requirements
- Pay-per-execution cost model
- Simplified deployment and maintenance
- Integrates natively with Azure services

### 2. Cosmos DB for Metadata
**Rationale**:
- High-scale NoSQL database for 100k+ documents
- Fast queries with proper indexing
- Flexible schema for dynamic metadata
- Global distribution capability
- Low-latency reads/writes

**Alternatives Considered**: Azure SQL, Table Storage
- Cosmos chosen for scale and flexibility

### 3. Blob Storage for Documents
**Rationale**:
- Optimized for large file storage (multi-GB)
- Cost-effective for high volume
- Built-in redundancy and durability
- Streaming support for large files
- Integration with Azure CDN (future)

### 4. Redis Caching Layer
**Rationale**:
- Critical for "high performance" requirement
- Reduce Cosmos DB queries for frequent operations
- Faster folder tree navigation
- Cache search results
- Reduce latency for mobile users

### 5. Vue 3 + Vuetify Frontend
**Rationale**:
- Vue 3 Composition API for maintainable code
- Vuetify provides mobile-responsive components
- Pinia for simple, type-safe state management
- Rich component library reduces development time
- Good performance for SPA

### 6. Separation of Concerns
**Rationale**:
- Frontend (Vue) handles presentation only
- Functions (C#) handle business logic
- Cosmos DB handles metadata queries
- Blob Storage handles file operations
- Redis handles caching
- Clear boundaries enable independent scaling

### 7. C# for Backend Services
**Rationale**:
- Strong typing for reliability
- Rich Azure SDK support
- Excellent tooling and debugging
- Good performance
- Familiar for .NET developers

### 8. API-First Design
**Rationale**:
- Enables future mobile apps
- Clear contract between frontend/backend
- Testable API endpoints
- Easier to add authentication/authorization later
- Supports multiple clients

### 9. Folder Structure in Cosmos DB
**Rationale**:
- NoSQL flexible schema for dynamic folder trees
- Fast queries with proper indexing on folder paths
- Easier to manage hierarchy than relational model
- Supports unlimited nesting
