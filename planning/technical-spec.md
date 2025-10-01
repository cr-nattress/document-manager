# Technical Specification

## Implementation Details

### Frontend Implementation (Vue 3 + Vuetify)

#### Project Structure
```
/frontend
├── src/
│   ├── main.ts                       # App entry point with Pinia setup
│   ├── App.vue                       # Root component
│   ├── router/
│   │   ├── index.ts                  # Vue Router config
│   │   └── routes.ts                 # Route definitions with guards
│   ├── stores/                       # Pinia stores (max 150 lines each)
│   │   ├── index.ts                  # Store initialization with plugins
│   │   ├── modules/                  # Domain-specific stores
│   │   │   ├── documentStore.ts      # Document state with caching
│   │   │   ├── folderStore.ts        # Folder tree state
│   │   │   ├── userStore.ts          # User management with optimistic updates
│   │   │   └── authStore.ts          # Authentication state
│   │   ├── ui/                       # UI state stores
│   │   │   ├── index.ts              # UI state (theme, modals, loading)
│   │   │   └── notificationStore.ts  # Notification system
│   │   └── plugins/                  # Pinia plugins
│   │       ├── persist.ts            # State persistence plugin
│   │       └── security.ts           # Security plugin
│   ├── services/                     # API services (max 150 lines each)
│   │   ├── api/
│   │   │   ├── baseApiClient.ts      # Axios with interceptors, CSRF
│   │   │   ├── documentApi.ts        # Document API calls
│   │   │   ├── folderApi.ts          # Folder API calls
│   │   │   ├── searchApi.ts          # Search API calls
│   │   │   └── authApi.ts            # Authentication API
│   │   └── security/
│   │       ├── authService.ts        # Auth logic
│   │       ├── csrfService.ts        # CSRF token management
│   │       └── encryptionService.ts  # Client-side encryption
│   ├── components/                   # Reusable components (max 200 lines)
│   │   ├── common/                   # Generic components
│   │   │   ├── feedback/             # Alerts, snackbars, dialogs
│   │   │   │   ├── NotificationContainer.vue
│   │   │   │   ├── GlobalLoading.vue
│   │   │   │   └── ConfirmDialog.vue
│   │   │   ├── forms/                # Form components
│   │   │   │   ├── SecureTextField.vue
│   │   │   │   ├── FileUploadSecure.vue
│   │   │   │   └── PasswordField.vue
│   │   │   └── layout/               # Layout components
│   │   │       ├── EmptyState.vue
│   │   │       └── LoadingSpinner.vue
│   │   ├── features/                 # Feature-specific components
│   │   │   ├── documents/
│   │   │   │   ├── DocumentList.vue
│   │   │   │   ├── DocumentCard.vue
│   │   │   │   ├── UploadDialog.vue
│   │   │   │   └── MetadataEditor.vue
│   │   │   └── folders/
│   │   │       ├── FolderTree.vue
│   │   │       ├── FolderNode.vue
│   │   │       └── CreateFolderDialog.vue
│   │   └── layouts/                  # App layouts
│   │       ├── AppLayout.vue
│   │       ├── AppBar.vue
│   │       └── NavigationDrawer.vue
│   ├── views/                        # Page components
│   │   ├── DashboardView.vue
│   │   ├── BrowseView.vue
│   │   ├── SearchView.vue
│   │   └── LoginView.vue
│   ├── composables/                  # Composition functions (max 100 lines)
│   │   ├── ui/
│   │   │   ├── useFocusTrap.ts
│   │   │   └── useResponsive.ts
│   │   ├── forms/
│   │   │   ├── useForm.ts            # Form validation with Zod
│   │   │   ├── useFormValidation.ts
│   │   │   └── useDebouncedValidation.ts
│   │   ├── useSecureFileUpload.ts    # Secure file upload
│   │   ├── useRateLimiter.ts         # Client-side rate limiting
│   │   ├── useInactivityTimer.ts     # Auto-logout
│   │   └── useApiRequest.ts          # API request with cancellation
│   ├── guards/                       # Route guards
│   │   ├── authGuard.ts
│   │   ├── roleGuard.ts
│   │   └── securityGuard.ts
│   ├── utils/                        # Pure utilities (max 50 lines per fn)
│   │   ├── validators/
│   │   │   ├── sanitizer.ts          # DOMPurify wrapper, text sanitization
│   │   │   ├── schemas.ts            # Zod schemas
│   │   │   └── fileValidator.ts      # File validation
│   │   ├── formatters/
│   │   │   ├── dateFormatter.ts
│   │   │   ├── byteFormatter.ts
│   │   │   └── numberFormatter.ts
│   │   ├── security/
│   │   │   ├── urlSecurity.ts
│   │   │   ├── cspHelper.ts
│   │   │   └── tokenManager.ts
│   │   └── test-utils/               # Testing utilities
│   │       ├── test-factory.ts       # @faker-js/faker data generation
│   │       ├── vuetify-test-helper.ts
│   │       └── mock-server.ts        # MSW handlers
│   ├── types/                        # TypeScript types
│   │   ├── models/                   # Domain models
│   │   │   ├── document.ts
│   │   │   ├── folder.ts
│   │   │   └── user.ts
│   │   ├── api/                      # API types
│   │   │   ├── requests.ts
│   │   │   └── responses.ts
│   │   ├── security/                 # Security types
│   │   │   ├── auth.ts               # Branded types for tokens
│   │   │   └── validation.ts
│   │   ├── state.ts                  # AsyncState types
│   │   └── utils.ts                  # Utility types
│   ├── constants/
│   │   ├── app.ts
│   │   ├── routes.ts
│   │   └── security/
│   │       ├── csp.ts                # CSP directives
│   │       └── validation.ts         # Validation constants
│   ├── styles/
│   │   ├── main.css
│   │   └── variables.css
│   ├── plugins/
│   │   └── vuetify.ts                # Vuetify configuration
│   └── config/
│       ├── env.ts                    # Environment validation
│       └── environments.ts           # Environment configs
├── public/
├── tests/
│   ├── setup.ts                      # Vitest + Vuetify setup
│   ├── unit/                         # Unit tests
│   │   ├── components/
│   │   ├── composables/
│   │   ├── stores/
│   │   └── utils/
│   ├── e2e/                          # Playwright E2E tests
│   │   ├── pages/                    # Page Object Model
│   │   │   ├── BasePage.ts
│   │   │   ├── LoginPage.ts
│   │   │   └── DashboardPage.ts
│   │   └── specs/
│   │       ├── authentication.spec.ts
│   │       ├── accessibility.spec.ts
│   │       └── performance.spec.ts
│   └── utils/                        # Test utilities
├── package.json
├── vite.config.ts                    # Vite with security config
├── vitest.config.ts                  # Vitest configuration
├── playwright.config.ts              # Playwright configuration
└── tsconfig.json                     # TypeScript strict mode
```

#### Key Components Implementation

**FolderTree.vue**:
```vue
<template>
  <v-treeview
    :items="folderTree"
    item-value="id"
    item-title="name"
    activatable
    open-on-click
    @update:activated="onFolderSelect"
  >
    <template v-slot:prepend="{ item }">
      <v-icon>{{ item.icon || 'mdi-folder' }}</v-icon>
    </template>
    <template v-slot:append="{ item }">
      <span class="text-caption">{{ item.documentCount }}</span>
    </template>
  </v-treeview>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useFolderStore } from '@/stores/folderStore'

const folderStore = useFolderStore()
const folderTree = computed(() => folderStore.tree)

const onFolderSelect = (ids: string[]) => {
  if (ids.length > 0) {
    folderStore.setActiveFolder(ids[0])
  }
}
</script>
```

**DocumentList.vue**:
```vue
<template>
  <v-data-table
    :items="documents"
    :headers="headers"
    :loading="loading"
    @click:row="onDocumentClick"
  >
    <template v-slot:item.size="{ item }">
      {{ formatFileSize(item.size) }}
    </template>
    <template v-slot:item.actions="{ item }">
      <v-btn icon @click.stop="onDownload(item)">
        <v-icon>mdi-download</v-icon>
      </v-btn>
      <v-btn icon @click.stop="onEdit(item)">
        <v-icon>mdi-pencil</v-icon>
      </v-btn>
      <v-btn icon @click.stop="onDelete(item)">
        <v-icon>mdi-delete</v-icon>
      </v-btn>
    </template>
  </v-data-table>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useDocumentStore } from '@/stores/documentStore'
import { formatFileSize } from '@/utils/formatters'

const documentStore = useDocumentStore()
const documents = computed(() => documentStore.documents)
const loading = computed(() => documentStore.loading)

const headers = [
  { title: 'Name', key: 'name' },
  { title: 'Size', key: 'size' },
  { title: 'Modified', key: 'modifiedAt' },
  { title: 'Actions', key: 'actions', sortable: false }
]

const onDocumentClick = (item: Document) => {
  documentStore.setActiveDocument(item)
}

const onDownload = async (item: Document) => {
  await documentStore.downloadDocument(item.id)
}

const onEdit = (item: Document) => {
  documentStore.openEditDialog(item)
}

const onDelete = async (item: Document) => {
  await documentStore.deleteDocument(item.id)
}
</script>
```

#### State Management (Pinia)

**documentStore.ts**:
```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { documentService } from '@/services/documentService'
import type { Document } from '@/types/document'

export const useDocumentStore = defineStore('document', () => {
  const documents = ref<Document[]>([])
  const loading = ref(false)
  const currentFolderId = ref<string | null>(null)

  const fetchDocuments = async (folderId: string) => {
    loading.value = true
    try {
      const response = await documentService.list(folderId)
      documents.value = response.documents
      currentFolderId.value = folderId
    } finally {
      loading.value = false
    }
  }

  const uploadDocument = async (file: File, folderId: string, metadata?: any) => {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('folderId', folderId)
    if (metadata) {
      formData.append('metadata', JSON.stringify(metadata))
    }

    const document = await documentService.upload(formData)
    documents.value.push(document)
    return document
  }

  const deleteDocument = async (id: string) => {
    await documentService.delete(id)
    documents.value = documents.value.filter(d => d.id !== id)
  }

  return {
    documents,
    loading,
    fetchDocuments,
    uploadDocument,
    deleteDocument
  }
})
```

#### API Service Layer

**apiClient.ts**:
```typescript
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Add API key to all requests
apiClient.interceptors.request.use(config => {
  const apiKey = import.meta.env.VITE_API_KEY
  if (apiKey) {
    config.headers['X-API-Key'] = apiKey
  }
  return config
})

// Handle errors globally
apiClient.interceptors.response.use(
  response => response,
  error => {
    // Handle 401, 403, 500, etc.
    return Promise.reject(error)
  }
)

export default apiClient
```

**documentService.ts**:
```typescript
import apiClient from './apiClient'
import type { Document } from '@/types/document'

export const documentService = {
  async list(folderId?: string) {
    const params = folderId ? { folderId } : {}
    const response = await apiClient.get('/api/documents', { params })
    return response.data
  },

  async get(id: string): Promise<Document> {
    const response = await apiClient.get(`/api/documents/${id}`)
    return response.data
  },

  async upload(formData: FormData): Promise<Document> {
    const response = await apiClient.post('/api/documents', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },

  async update(id: string, data: Partial<Document>): Promise<Document> {
    const response = await apiClient.put(`/api/documents/${id}`, data)
    return response.data
  },

  async delete(id: string): Promise<void> {
    await apiClient.delete(`/api/documents/${id}`)
  },

  async download(id: string): Promise<Blob> {
    const response = await apiClient.get(`/api/documents/${id}/download`, {
      responseType: 'blob'
    })
    return response.data
  }
}
```

### Backend Implementation (C# Azure Functions)

#### Project Structure
```
/backend
├── DocumentManager.Functions/
│   ├── Functions/
│   │   ├── DocumentFunctions.cs
│   │   ├── FolderFunctions.cs
│   │   └── SearchFunctions.cs
│   ├── Services/
│   │   ├── ICosmosDbService.cs
│   │   ├── CosmosDbService.cs
│   │   ├── IBlobStorageService.cs
│   │   ├── BlobStorageService.cs
│   │   ├── ICacheService.cs
│   │   └── CacheService.cs
│   ├── Models/
│   │   ├── Document.cs
│   │   ├── Folder.cs
│   │   └── Tag.cs
│   ├── DTOs/
│   │   ├── DocumentDto.cs
│   │   ├── UploadDocumentRequest.cs
│   │   └── CreateFolderRequest.cs
│   ├── Middleware/
│   │   └── ApiKeyAuthMiddleware.cs
│   ├── Validators/
│   │   └── DocumentValidator.cs
│   ├── Startup.cs
│   └── host.json
├── DocumentManager.Tests/
│   ├── Unit/
│   └── Integration/
└── DocumentManager.sln
```

#### Key Functions Implementation

**DocumentFunctions.cs**:
```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

public class DocumentFunctions
{
    private readonly ICosmosDbService _cosmosDb;
    private readonly IBlobStorageService _blobStorage;
    private readonly ICacheService _cache;
    private readonly ILogger<DocumentFunctions> _logger;

    public DocumentFunctions(
        ICosmosDbService cosmosDb,
        IBlobStorageService blobStorage,
        ICacheService cache,
        ILogger<DocumentFunctions> logger)
    {
        _cosmosDb = cosmosDb;
        _blobStorage = blobStorage;
        _cache = cache;
        _logger = logger;
    }

    [Function("UploadDocument")]
    public async Task<HttpResponseData> UploadDocument(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "documents")]
        HttpRequestData req)
    {
        try
        {
            // Parse multipart form data
            var formData = await req.ReadFormDataAsync();
            var file = formData.Files["file"];
            var folderId = formData["folderId"] ?? "root";

            // Validate
            if (file == null || file.Length == 0)
                return req.CreateResponse(HttpStatusCode.BadRequest);

            // Generate document ID
            var documentId = $"doc-{Guid.NewGuid()}";

            // Upload to Blob Storage
            var blobUrl = await _blobStorage.UploadAsync(
                documentId,
                file.OpenReadStream(),
                file.ContentType);

            // Create metadata document
            var document = new Document
            {
                Id = documentId,
                Name = formData["name"] ?? file.FileName,
                FileName = file.FileName,
                FolderId = folderId,
                Size = file.Length,
                ContentType = file.ContentType,
                BlobUrl = blobUrl,
                UploadedAt = DateTime.UtcNow,
                ModifiedAt = DateTime.UtcNow
            };

            // Save to Cosmos DB
            await _cosmosDb.CreateDocumentAsync(document);

            // Invalidate cache
            await _cache.InvalidateFolderContentsAsync(folderId);

            var response = req.CreateResponse(HttpStatusCode.Created);
            await response.WriteAsJsonAsync(document);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading document");
            return req.CreateResponse(HttpStatusCode.InternalServerError);
        }
    }

    [Function("GetDocument")]
    public async Task<HttpResponseData> GetDocument(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "documents/{id}")]
        HttpRequestData req,
        string id)
    {
        // Check cache first
        var cached = await _cache.GetDocumentAsync(id);
        if (cached != null)
        {
            var cachedResponse = req.CreateResponse(HttpStatusCode.OK);
            await cachedResponse.WriteAsJsonAsync(cached);
            return cachedResponse;
        }

        // Get from Cosmos DB
        var document = await _cosmosDb.GetDocumentAsync(id);
        if (document == null)
            return req.CreateResponse(HttpStatusCode.NotFound);

        // Cache it
        await _cache.SetDocumentAsync(id, document);

        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(document);
        return response;
    }

    [Function("DownloadDocument")]
    public async Task<HttpResponseData> DownloadDocument(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "documents/{id}/download")]
        HttpRequestData req,
        string id)
    {
        var document = await _cosmosDb.GetDocumentAsync(id);
        if (document == null)
            return req.CreateResponse(HttpStatusCode.NotFound);

        var stream = await _blobStorage.DownloadAsync(document.BlobStorageId);

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", document.ContentType);
        response.Headers.Add("Content-Disposition",
            $"attachment; filename=\"{document.FileName}\"");

        await stream.CopyToAsync(response.Body);
        return response;
    }

    [Function("DeleteDocument")]
    public async Task<HttpResponseData> DeleteDocument(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "documents/{id}")]
        HttpRequestData req,
        string id)
    {
        var document = await _cosmosDb.GetDocumentAsync(id);
        if (document == null)
            return req.CreateResponse(HttpStatusCode.NotFound);

        // Delete blob
        await _blobStorage.DeleteAsync(document.BlobStorageId);

        // Delete metadata
        await _cosmosDb.DeleteDocumentAsync(id);

        // Invalidate cache
        await _cache.InvalidateDocumentAsync(id);
        await _cache.InvalidateFolderContentsAsync(document.FolderId);

        return req.CreateResponse(HttpStatusCode.NoContent);
    }
}
```

#### Service Implementations

**CosmosDbService.cs**:
```csharp
using Microsoft.Azure.Cosmos;

public class CosmosDbService : ICosmosDbService
{
    private readonly Container _documentsContainer;
    private readonly Container _foldersContainer;

    public CosmosDbService(CosmosClient cosmosClient, string databaseName)
    {
        var database = cosmosClient.GetDatabase(databaseName);
        _documentsContainer = database.GetContainer("documents");
        _foldersContainer = database.GetContainer("folders");
    }

    public async Task<Document> CreateDocumentAsync(Document document)
    {
        var response = await _documentsContainer.CreateItemAsync(
            document,
            new PartitionKey(document.FolderId));
        return response.Resource;
    }

    public async Task<Document> GetDocumentAsync(string id, string folderId)
    {
        try
        {
            var response = await _documentsContainer.ReadItemAsync<Document>(
                id,
                new PartitionKey(folderId));
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<List<Document>> QueryDocumentsAsync(string folderId)
    {
        var query = new QueryDefinition(
            "SELECT * FROM documents d WHERE d.folderId = @folderId ORDER BY d.uploadedAt DESC")
            .WithParameter("@folderId", folderId);

        var iterator = _documentsContainer.GetItemQueryIterator<Document>(query);
        var results = new List<Document>();

        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            results.AddRange(response);
        }

        return results;
    }
}
```

**BlobStorageService.cs**:
```csharp
using Azure.Storage.Blobs;

public class BlobStorageService : IBlobStorageService
{
    private readonly BlobContainerClient _containerClient;

    public BlobStorageService(BlobServiceClient blobServiceClient, string containerName)
    {
        _containerClient = blobServiceClient.GetBlobContainerClient(containerName);
    }

    public async Task<string> UploadAsync(string blobName, Stream content, string contentType)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);

        await blobClient.UploadAsync(content, new BlobHttpHeaders
        {
            ContentType = contentType
        });

        return blobClient.Uri.ToString();
    }

    public async Task<Stream> DownloadAsync(string blobName)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);
        var response = await blobClient.DownloadAsync();
        return response.Value.Content;
    }

    public async Task DeleteAsync(string blobName)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);
        await blobClient.DeleteIfExistsAsync();
    }
}
```

**CacheService.cs**:
```csharp
using StackExchange.Redis;
using System.Text.Json;

public class CacheService : ICacheService
{
    private readonly IDatabase _cache;
    private readonly TimeSpan _defaultExpiry = TimeSpan.FromMinutes(10);

    public CacheService(IConnectionMultiplexer redis)
    {
        _cache = redis.GetDatabase();
    }

    public async Task<Document> GetDocumentAsync(string id)
    {
        var key = $"document:{id}";
        var cached = await _cache.StringGetAsync(key);

        if (cached.HasValue)
        {
            return JsonSerializer.Deserialize<Document>(cached);
        }

        return null;
    }

    public async Task SetDocumentAsync(string id, Document document)
    {
        var key = $"document:{id}";
        var json = JsonSerializer.Serialize(document);
        await _cache.StringSetAsync(key, json, _defaultExpiry);
    }

    public async Task InvalidateDocumentAsync(string id)
    {
        var key = $"document:{id}";
        await _cache.KeyDeleteAsync(key);
    }

    public async Task InvalidateFolderContentsAsync(string folderId)
    {
        var key = $"folder:contents:{folderId}";
        await _cache.KeyDeleteAsync(key);
    }
}
```

#### Dependency Injection (Startup.cs)

```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        // Cosmos DB
        services.AddSingleton(sp =>
        {
            var connectionString = Environment.GetEnvironmentVariable("CosmosDbConnectionString");
            return new CosmosClient(connectionString);
        });
        services.AddSingleton<ICosmosDbService, CosmosDbService>();

        // Blob Storage
        services.AddSingleton(sp =>
        {
            var connectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString");
            return new BlobServiceClient(connectionString);
        });
        services.AddSingleton<IBlobStorageService, BlobStorageService>();

        // Redis Cache
        services.AddSingleton<IConnectionMultiplexer>(sp =>
        {
            var connectionString = Environment.GetEnvironmentVariable("RedisConnectionString");
            return ConnectionMultiplexer.Connect(connectionString);
        });
        services.AddSingleton<ICacheService, CacheService>();
    })
    .Build();

host.Run();
```

## Technical Constraints

### Performance Constraints
- API response time: p95 < 500ms for metadata operations
- Document upload: Support files up to 5GB
- Concurrent uploads: Handle 100 simultaneous uploads
- Search performance: < 200ms for 100k+ document searches
- Folder tree loading: < 1 second for 1000+ folders

### Scalability Constraints
- Azure Functions: Auto-scale from 1 to 100 instances
- Cosmos DB: 400 RU/s minimum, 10,000+ RU/s maximum
- Blob Storage: No practical limit on storage
- Redis: Standard tier (C1) minimum for 1GB cache

### Security Constraints
- API authentication: Required on all endpoints
- HTTPS only: No HTTP traffic allowed
- Blob access: Private containers with SAS tokens
- API keys: Stored in Key Vault, not in code
- Input validation: All user input sanitized

### Browser Compatibility
- Chrome/Edge: Latest 2 versions
- Firefox: Latest 2 versions
- Safari: Latest 2 versions
- Mobile browsers: iOS Safari 14+, Chrome Mobile

### Mobile Constraints
- Responsive breakpoints: 600px, 960px, 1264px
- Touch targets: Minimum 44x44px
- Offline support: Not required for POC
- PWA features: Not required for POC

### Data Constraints
- File size: Max 5GB per document
- File types: All types supported
- Document name: Max 255 characters
- Folder name: Max 100 characters
- Folder depth: Max 10 levels
- Tags per document: Max 50
- Metadata fields: Max 20 key-value pairs
- Total documents: Designed for 100k+ documents

### Azure Resource Constraints
- Region: Single region deployment (multi-region optional)
- Cosmos DB consistency: Session level
- Blob Storage: LRS or GRS replication
- Redis: Standard or Premium tier
- Functions: Premium or Consumption plan

### Development Constraints
- .NET version: .NET 8
- Node.js version: 18+ for frontend build
- TypeScript: Strict mode enabled
- Code style: ESLint + Prettier (frontend), StyleCop (backend)
- Git workflow: Feature branches, PR reviews required

### Operational Constraints
- Monitoring: Application Insights required
- Logging: Structured logging with Serilog
- Health checks: Required on all services
- Deployment: CI/CD via GitHub Actions
- Backup: Cosmos DB continuous backup mode
