# Azure Cosmos DB - Comprehensive Guide

**Technology**: Azure Cosmos DB
**Category**: NoSQL Database
**Official Docs**: https://learn.microsoft.com/azure/cosmos-db

---

## Overview

Azure Cosmos DB is a globally distributed, multi-model NoSQL database service designed for low-latency, high-availability applications. It offers turnkey global distribution, automatic scaling, and comprehensive SLAs.

### Key Features
- **Global Distribution** - Replicate data across any Azure region
- **Guaranteed Low Latency** - Single-digit millisecond response times
- **Multiple APIs** - SQL, MongoDB, Cassandra, Gremlin, Table
- **Automatic Indexing** - All properties indexed by default
- **Flexible Scaling** - Serverless, provisioned, or autoscale throughput
- **ACID Transactions** - Multi-document transactions
- **TTL Support** - Auto-expire documents
- **Change Feed** - Listen to data changes in real-time

---

## Design Patterns

### 1. Container Design with Partition Keys

**Purpose**: Optimize for scale and performance

```csharp
// Models/Document.cs
public class Document
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    // Partition key for documents container
    [JsonPropertyName("folderId")]
    public string FolderId { get; set; } = string.Empty;

    [JsonPropertyName("contentType")]
    public string ContentType { get; set; } = string.Empty;

    [JsonPropertyName("size")]
    public long Size { get; set; }

    [JsonPropertyName("blobUrl")]
    public string BlobUrl { get; set; } = string.Empty;

    [JsonPropertyName("uploadedAt")]
    public DateTime UploadedAt { get; set; }

    [JsonPropertyName("modifiedAt")]
    public DateTime? ModifiedAt { get; set; }

    [JsonPropertyName("metadata")]
    public Dictionary<string, string>? Metadata { get; set; }

    [JsonPropertyName("tags")]
    public List<string>? Tags { get; set; }

    // TTL in seconds (optional)
    [JsonPropertyName("ttl")]
    public int? Ttl { get; set; }

    // Cosmos DB system properties
    [JsonPropertyName("_ts")]
    public long Timestamp { get; set; }
}

// Models/Folder.cs
public class Folder
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    // Partition key for folders container
    [JsonPropertyName("parentId")]
    public string? ParentId { get; set; }

    [JsonPropertyName("path")]
    public string Path { get; set; } = "/";

    [JsonPropertyName("documentCount")]
    public int DocumentCount { get; set; }

    [JsonPropertyName("createdAt")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("modifiedAt")]
    public DateTime? ModifiedAt { get; set; }

    [JsonPropertyName("_ts")]
    public long Timestamp { get; set; }
}
```

### 2. Repository Pattern with Cosmos SDK

**Purpose**: Abstract Cosmos DB operations

```csharp
// Repositories/CosmosDbRepository.cs
using Microsoft.Azure.Cosmos;
using System.Net;

public class CosmosDbRepository<T> : IRepository<T> where T : class
{
    private readonly Container _container;
    private readonly ILogger<CosmosDbRepository<T>> _logger;

    public CosmosDbRepository(
        CosmosClient cosmosClient,
        string databaseName,
        string containerName,
        ILogger<CosmosDbRepository<T>> logger)
    {
        _container = cosmosClient.GetContainer(databaseName, containerName);
        _logger = logger;
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        var query = _container.GetItemQueryIterator<T>(
            new QueryDefinition("SELECT * FROM c")
        );

        var results = new List<T>();

        while (query.HasMoreResults)
        {
            var response = await query.ReadNextAsync();
            results.AddRange(response);

            _logger.LogInformation(
                "Query consumed {RU} RUs",
                response.RequestCharge
            );
        }

        return results;
    }

    public async Task<T?> GetByIdAsync(string id, string partitionKey)
    {
        try
        {
            var response = await _container.ReadItemAsync<T>(
                id,
                new PartitionKey(partitionKey)
            );

            _logger.LogInformation(
                "Read item consumed {RU} RUs",
                response.RequestCharge
            );

            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IEnumerable<T>> QueryAsync(
        string query,
        Dictionary<string, object>? parameters = null)
    {
        var queryDefinition = new QueryDefinition(query);

        if (parameters != null)
        {
            foreach (var param in parameters)
            {
                queryDefinition.WithParameter($"@{param.Key}", param.Value);
            }
        }

        var iterator = _container.GetItemQueryIterator<T>(queryDefinition);
        var results = new List<T>();

        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            results.AddRange(response);

            _logger.LogInformation(
                "Query consumed {RU} RUs",
                response.RequestCharge
            );
        }

        return results;
    }

    public async Task<T> CreateAsync(T item, string partitionKey)
    {
        var response = await _container.CreateItemAsync(
            item,
            new PartitionKey(partitionKey)
        );

        _logger.LogInformation(
            "Create consumed {RU} RUs",
            response.RequestCharge
        );

        return response.Resource;
    }

    public async Task<T> UpsertAsync(T item, string partitionKey)
    {
        var response = await _container.UpsertItemAsync(
            item,
            new PartitionKey(partitionKey)
        );

        _logger.LogInformation(
            "Upsert consumed {RU} RUs",
            response.RequestCharge
        );

        return response.Resource;
    }

    public async Task<T> UpdateAsync(string id, T item, string partitionKey)
    {
        var response = await _container.ReplaceItemAsync(
            item,
            id,
            new PartitionKey(partitionKey)
        );

        _logger.LogInformation(
            "Update consumed {RU} RUs",
            response.RequestCharge
        );

        return response.Resource;
    }

    public async Task<T> PatchAsync(
        string id,
        string partitionKey,
        List<PatchOperation> patchOperations)
    {
        var response = await _container.PatchItemAsync<T>(
            id,
            new PartitionKey(partitionKey),
            patchOperations
        );

        _logger.LogInformation(
            "Patch consumed {RU} RUs",
            response.RequestCharge
        );

        return response.Resource;
    }

    public async Task DeleteAsync(string id, string partitionKey)
    {
        var response = await _container.DeleteItemAsync<T>(
            id,
            new PartitionKey(partitionKey)
        );

        _logger.LogInformation(
            "Delete consumed {RU} RUs",
            response.RequestCharge
        );
    }

    public async Task<int> CountAsync(string query = "SELECT VALUE COUNT(1) FROM c")
    {
        var iterator = _container.GetItemQueryIterator<int>(
            new QueryDefinition(query)
        );

        var response = await iterator.ReadNextAsync();
        return response.FirstOrDefault();
    }
}
```

### 3. Transactional Batch Operations

**Purpose**: Execute multiple operations atomically

```csharp
public class DocumentBatchService
{
    private readonly Container _container;
    private readonly ILogger<DocumentBatchService> _logger;

    public DocumentBatchService(
        Container container,
        ILogger<DocumentBatchService> logger)
    {
        _container = container;
        _logger = logger;
    }

    public async Task<bool> MoveDocumentsBatchAsync(
        List<Document> documents,
        string targetFolderId)
    {
        // Group documents by current folder (partition key)
        var groupedByFolder = documents.GroupBy(d => d.FolderId);

        foreach (var group in groupedByFolder)
        {
            var partitionKey = new PartitionKey(group.Key);
            var batch = _container.CreateTransactionalBatch(partitionKey);

            foreach (var document in group)
            {
                // Delete from old partition
                batch.DeleteItem(document.Id);
            }

            try
            {
                using var response = await batch.ExecuteAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError(
                        "Batch delete failed: {StatusCode}",
                        response.StatusCode
                    );
                    return false;
                }

                _logger.LogInformation(
                    "Batch delete consumed {RU} RUs",
                    response.RequestCharge
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Batch operation failed");
                return false;
            }

            // Create in new partition
            var newPartitionKey = new PartitionKey(targetFolderId);
            var createBatch = _container.CreateTransactionalBatch(newPartitionKey);

            foreach (var document in group)
            {
                document.FolderId = targetFolderId;
                document.ModifiedAt = DateTime.UtcNow;
                createBatch.CreateItem(document);
            }

            try
            {
                using var response = await createBatch.ExecuteAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError(
                        "Batch create failed: {StatusCode}",
                        response.StatusCode
                    );
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Batch create failed");
                return false;
            }
        }

        return true;
    }
}
```

---

## Best Practices

### 1. Choose Appropriate Partition Keys

**Good Partition Keys**:
- High cardinality (many unique values)
- Even distribution of requests
- Logical grouping of related data

**Document Manager Example**:
```csharp
// Documents container: partition by folderId
// - Documents in same folder accessed together
// - Folders can have many documents (high cardinality)
[JsonPropertyName("folderId")]
public string FolderId { get; set; }

// Folders container: partition by parentId
// - Sub-folders of same parent accessed together
[JsonPropertyName("parentId")]
public string? ParentId { get; set; }
```

### 2. Use Parameterized Queries

**Do**:
```csharp
var query = new QueryDefinition(
    "SELECT * FROM c WHERE c.folderId = @folderId"
).WithParameter("@folderId", folderId);
```

**Don't**:
```csharp
var query = new QueryDefinition(
    $"SELECT * FROM c WHERE c.folderId = '{folderId}'"
); // SQL injection risk
```

### 3. Optimize Queries with Indexes

**indexingPolicy.json**:
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/*"
    }
  ],
  "excludedPaths": [
    {
      "path": "/blobUrl/?"
    },
    {
      "path": "/_etag/?"
    }
  ],
  "compositeIndexes": [
    [
      {
        "path": "/folderId",
        "order": "ascending"
      },
      {
        "path": "/uploadedAt",
        "order": "descending"
      }
    ]
  ]
}
```

### 4. Use Pagination for Large Result Sets

```csharp
public async Task<PagedResult<Document>> GetDocumentsPagedAsync(
    string? continuationToken,
    int pageSize = 20)
{
    var queryOptions = new QueryRequestOptions
    {
        MaxItemCount = pageSize
    };

    var query = _container.GetItemQueryIterator<Document>(
        queryDefinition: new QueryDefinition("SELECT * FROM c ORDER BY c.uploadedAt DESC"),
        continuationToken: continuationToken,
        requestOptions: queryOptions
    );

    var response = await query.ReadNextAsync();

    return new PagedResult<Document>
    {
        Items = response.ToList(),
        ContinuationToken = response.ContinuationToken,
        RequestCharge = response.RequestCharge
    };
}
```

### 5. Implement TTL for Auto-Expiration

```csharp
// Enable TTL on container (set to -1 for per-item TTL)
var containerProperties = new ContainerProperties
{
    Id = "documents",
    PartitionKeyPath = "/folderId",
    DefaultTimeToLive = -1 // Enable TTL, controlled per document
};

// Set TTL on individual document
var document = new Document
{
    Name = "temp.pdf",
    FolderId = "folder-1",
    Ttl = 86400 // Expires in 24 hours (seconds)
};
```

---

## Common Patterns for Document Manager

### 1. Document Search Service

```csharp
public class DocumentSearchService
{
    private readonly Container _container;

    public async Task<List<Document>> SearchDocumentsAsync(
        string searchTerm,
        string? folderId = null,
        List<string>? tags = null)
    {
        var conditions = new List<string> { "1=1" };
        var parameters = new Dictionary<string, object>();

        // Full-text search on name and metadata
        if (!string.IsNullOrEmpty(searchTerm))
        {
            conditions.Add("(CONTAINS(c.name, @searchTerm, true) OR EXISTS(SELECT VALUE m FROM m IN c.metadata WHERE CONTAINS(m, @searchTerm, true)))");
            parameters["searchTerm"] = searchTerm;
        }

        // Filter by folder
        if (!string.IsNullOrEmpty(folderId))
        {
            conditions.Add("c.folderId = @folderId");
            parameters["folderId"] = folderId;
        }

        // Filter by tags
        if (tags != null && tags.Any())
        {
            conditions.Add("EXISTS(SELECT VALUE t FROM t IN c.tags WHERE ARRAY_CONTAINS(@tags, t))");
            parameters["tags"] = tags;
        }

        var query = $"SELECT * FROM c WHERE {string.Join(" AND ", conditions)}";
        var queryDefinition = new QueryDefinition(query);

        foreach (var param in parameters)
        {
            queryDefinition.WithParameter($"@{param.Key}", param.Value);
        }

        var iterator = _container.GetItemQueryIterator<Document>(queryDefinition);
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

### 2. Folder Statistics Aggregation

```csharp
public class FolderStatsService
{
    private readonly Container _documentsContainer;
    private readonly Container _foldersContainer;

    public async Task<FolderStats> GetFolderStatsAsync(string folderId)
    {
        // Aggregate document statistics for folder
        var query = @"
            SELECT
                COUNT(1) as documentCount,
                SUM(c.size) as totalSize,
                AVG(c.size) as avgSize,
                MIN(c.uploadedAt) as oldestUpload,
                MAX(c.uploadedAt) as newestUpload
            FROM c
            WHERE c.folderId = @folderId";

        var queryDefinition = new QueryDefinition(query)
            .WithParameter("@folderId", folderId);

        var iterator = _documentsContainer.GetItemQueryIterator<FolderStats>(queryDefinition);
        var response = await iterator.ReadNextAsync();

        return response.FirstOrDefault() ?? new FolderStats();
    }

    public async Task UpdateFolderDocumentCountAsync(string folderId, int delta)
    {
        // Use patch to increment document count
        var patchOperations = new List<PatchOperation>
        {
            PatchOperation.Increment("/documentCount", delta),
            PatchOperation.Set("/modifiedAt", DateTime.UtcNow)
        };

        await _foldersContainer.PatchItemAsync<Folder>(
            folderId,
            new PartitionKey(folderId),
            patchOperations
        );
    }
}
```

### 3. Change Feed Processor

**Purpose**: React to document changes in real-time

```csharp
public class DocumentChangeFeedProcessor
{
    private readonly CosmosClient _cosmosClient;
    private readonly ILogger<DocumentChangeFeedProcessor> _logger;
    private ChangeFeedProcessor? _changeFeedProcessor;

    public async Task StartAsync()
    {
        var container = _cosmosClient.GetContainer("DocumentManager", "documents");
        var leaseContainer = _cosmosClient.GetContainer("DocumentManager", "leases");

        _changeFeedProcessor = container
            .GetChangeFeedProcessorBuilder<Document>(
                "documentChangeFeed",
                HandleChangesAsync)
            .WithInstanceName("changeFeedInstance1")
            .WithLeaseContainer(leaseContainer)
            .WithStartTime(DateTime.UtcNow.AddDays(-1)) // Process last 24 hours
            .Build();

        await _changeFeedProcessor.StartAsync();
        _logger.LogInformation("Change feed processor started");
    }

    private async Task HandleChangesAsync(
        ChangeFeedProcessorContext context,
        IReadOnlyCollection<Document> changes,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Processing {Count} changes",
            changes.Count
        );

        foreach (var document in changes)
        {
            // Update search index
            await UpdateSearchIndexAsync(document);

            // Update folder statistics
            await UpdateFolderStatsAsync(document.FolderId);

            // Send notifications
            await NotifyDocumentChangedAsync(document);
        }
    }

    public async Task StopAsync()
    {
        if (_changeFeedProcessor != null)
        {
            await _changeFeedProcessor.StopAsync();
        }
    }
}
```

---

## Connection and Configuration

### 1. Configure Cosmos Client

```csharp
// Program.cs
builder.Services.AddSingleton<CosmosClient>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();

    var cosmosClientOptions = new CosmosClientOptions
    {
        ApplicationName = "DocumentManager",
        ConnectionMode = ConnectionMode.Direct,
        MaxRetryAttemptsOnRateLimitedRequests = 5,
        MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(10),
        RequestTimeout = TimeSpan.FromSeconds(30),
        SerializerOptions = new CosmosSerializationOptions
        {
            PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
        }
    };

    return new CosmosClient(
        config["CosmosDb:Endpoint"],
        config["CosmosDb:Key"],
        cosmosClientOptions
    );
});
```

### 2. Initialize Database and Containers

```csharp
public class CosmosDbInitializer
{
    public static async Task InitializeAsync(CosmosClient client, IConfiguration config)
    {
        var databaseName = config["CosmosDb:DatabaseName"];

        // Create database with autoscale
        var databaseResponse = await client.CreateDatabaseIfNotExistsAsync(
            databaseName,
            ThroughputProperties.CreateAutoscaleThroughput(4000)
        );

        var database = databaseResponse.Database;

        // Create documents container
        await database.CreateContainerIfNotExistsAsync(
            new ContainerProperties
            {
                Id = "documents",
                PartitionKeyPath = "/folderId",
                DefaultTimeToLive = -1 // Enable per-item TTL
            },
            ThroughputProperties.CreateAutoscaleThroughput(4000)
        );

        // Create folders container
        await database.CreateContainerIfNotExistsAsync(
            new ContainerProperties
            {
                Id = "folders",
                PartitionKeyPath = "/parentId"
            },
            ThroughputProperties.CreateAutoscaleThroughput(1000)
        );

        // Create leases container for change feed
        await database.CreateContainerIfNotExistsAsync(
            new ContainerProperties
            {
                Id = "leases",
                PartitionKeyPath = "/id"
            }
        );
    }
}
```

---

## Performance Monitoring

### 1. Track Request Units (RUs)

```csharp
public class CosmosMetricsService
{
    private readonly ILogger<CosmosMetricsService> _logger;

    public async Task<T> ExecuteWithMetricsAsync<T>(
        Func<Task<Response<T>>> operation,
        string operationName)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            var response = await operation();
            stopwatch.Stop();

            _logger.LogInformation(
                "Operation: {Operation}, RUs: {RU}, Latency: {Latency}ms",
                operationName,
                response.RequestCharge,
                stopwatch.ElapsedMilliseconds
            );

            return response.Resource;
        }
        catch (CosmosException ex)
        {
            _logger.LogError(
                ex,
                "Operation: {Operation}, Status: {Status}, RUs: {RU}",
                operationName,
                ex.StatusCode,
                ex.RequestCharge
            );
            throw;
        }
    }
}
```

---

## Testing

### Unit Test Example (xUnit with Emulator)

```csharp
public class DocumentRepositoryTests : IAsyncLifetime
{
    private CosmosClient _client = null!;
    private Container _container = null!;

    public async Task InitializeAsync()
    {
        // Use Cosmos DB Emulator for testing
        _client = new CosmosClient(
            "https://localhost:8081",
            "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
        );

        var database = await _client.CreateDatabaseIfNotExistsAsync("TestDb");
        _container = await database.Database.CreateContainerIfNotExistsAsync(
            "documents",
            "/folderId"
        );
    }

    [Fact]
    public async Task CreateAsync_CreatesDocument()
    {
        // Arrange
        var document = new Document
        {
            Id = Guid.NewGuid().ToString(),
            Name = "test.pdf",
            FolderId = "folder-1"
        };

        // Act
        var response = await _container.CreateItemAsync(
            document,
            new PartitionKey(document.FolderId)
        );

        // Assert
        Assert.NotNull(response.Resource);
        Assert.Equal(document.Id, response.Resource.Id);
    }

    public async Task DisposeAsync()
    {
        await _client.GetDatabase("TestDb").DeleteAsync();
        _client.Dispose();
    }
}
```

---

## Common Pitfalls

### 1. Hot Partition

**Problem**: All requests go to single partition

**Solution**: Choose better partition key with high cardinality

### 2. Cross-Partition Queries

**Problem**: Queries without partition key are expensive

**Do**:
```csharp
// Query with partition key
var query = new QueryDefinition("SELECT * FROM c WHERE c.folderId = @folderId")
    .WithParameter("@folderId", folderId);
```

### 3. Large Documents

**Problem**: Documents > 2MB cause issues

**Solution**: Store large data in Blob Storage, reference URL in Cosmos DB

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://learn.microsoft.com/azure/cosmos-db
- **SQL API**: https://learn.microsoft.com/azure/cosmos-db/sql/
- **Best Practices**: https://learn.microsoft.com/azure/cosmos-db/sql/best-practice

### Learning Resources
- **Microsoft Learn**: https://learn.microsoft.com/training/paths/work-with-nosql-data-in-azure-cosmos-db-sql-api/
- **Samples**: https://github.com/Azure/azure-cosmos-dotnet-v3

---

**For this project**: Use Cosmos DB SQL API with serverless or autoscale throughput. Partition documents by `folderId`, folders by `parentId`. Implement caching to reduce RU consumption. Monitor RU usage and optimize queries.

**Last Updated**: 2025-09-30
