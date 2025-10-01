# .NET 8 - Comprehensive Guide

**Technology**: .NET 8
**Category**: Backend Runtime & Framework
**Official Docs**: https://learn.microsoft.com/dotnet

---

## Overview

.NET 8 is Microsoft's cross-platform framework for building modern applications. It's a Long-Term Support (LTS) release with enhanced performance, new features, and improved developer productivity.

### Key Features
- **Long-Term Support** - 3 years of support until November 2026
- **Cross-Platform** - Windows, Linux, macOS
- **High Performance** - Optimized runtime and JIT compiler
- **Cloud-Native** - Built for Azure and containerized workloads
- **Minimal APIs** - Simplified HTTP API development
- **Native AOT** - Ahead-of-time compilation for fast startup
- **Improved JSON** - Better System.Text.Json performance
- **C# 12 Support** - Latest language features

---

## Design Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access logic from business logic

```csharp
// IRepository.cs
public interface IRepository<T> where T : class
{
    Task<IEnumerable<T>> GetAllAsync();
    Task<T?> GetByIdAsync(string id);
    Task<T> CreateAsync(T entity);
    Task<T> UpdateAsync(string id, T entity);
    Task DeleteAsync(string id);
}

// DocumentRepository.cs
using Microsoft.Azure.Cosmos;

public class DocumentRepository : IRepository<Document>
{
    private readonly Container _container;
    private readonly ILogger<DocumentRepository> _logger;

    public DocumentRepository(
        CosmosClient cosmosClient,
        IConfiguration configuration,
        ILogger<DocumentRepository> logger)
    {
        var databaseName = configuration["CosmosDb:DatabaseName"];
        var containerName = configuration["CosmosDb:Containers:Documents"];

        _container = cosmosClient.GetContainer(databaseName, containerName);
        _logger = logger;
    }

    public async Task<IEnumerable<Document>> GetAllAsync()
    {
        try
        {
            var query = _container.GetItemQueryIterator<Document>();
            var results = new List<Document>();

            while (query.HasMoreResults)
            {
                var response = await query.ReadNextAsync();
                results.AddRange(response);
            }

            return results;
        }
        catch (CosmosException ex)
        {
            _logger.LogError(ex, "Error fetching all documents");
            throw;
        }
    }

    public async Task<Document?> GetByIdAsync(string id)
    {
        try
        {
            var response = await _container.ReadItemAsync<Document>(
                id,
                new PartitionKey(id)
            );
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<Document> CreateAsync(Document entity)
    {
        try
        {
            var response = await _container.CreateItemAsync(
                entity,
                new PartitionKey(entity.FolderId)
            );
            return response.Resource;
        }
        catch (CosmosException ex)
        {
            _logger.LogError(ex, "Error creating document");
            throw;
        }
    }

    public async Task<Document> UpdateAsync(string id, Document entity)
    {
        try
        {
            var response = await _container.ReplaceItemAsync(
                entity,
                id,
                new PartitionKey(entity.FolderId)
            );
            return response.Resource;
        }
        catch (CosmosException ex)
        {
            _logger.LogError(ex, "Error updating document {DocumentId}", id);
            throw;
        }
    }

    public async Task DeleteAsync(string id)
    {
        try
        {
            await _container.DeleteItemAsync<Document>(
                id,
                new PartitionKey(id)
            );
        }
        catch (CosmosException ex)
        {
            _logger.LogError(ex, "Error deleting document {DocumentId}", id);
            throw;
        }
    }
}
```

### 2. Service Layer Pattern

**Purpose**: Encapsulate business logic separate from data access

```csharp
// IDocumentService.cs
public interface IDocumentService
{
    Task<DocumentDto> GetDocumentAsync(string id);
    Task<IEnumerable<DocumentDto>> GetDocumentsByFolderAsync(string folderId);
    Task<DocumentDto> CreateDocumentAsync(CreateDocumentRequest request, Stream fileStream);
    Task<DocumentDto> UpdateDocumentAsync(string id, UpdateDocumentRequest request);
    Task DeleteDocumentAsync(string id);
    Task<string> GetDownloadUrlAsync(string id);
}

// DocumentService.cs
public class DocumentService : IDocumentService
{
    private readonly IRepository<Document> _documentRepository;
    private readonly IBlobStorageService _blobStorageService;
    private readonly ICacheService _cacheService;
    private readonly IMapper _mapper;
    private readonly ILogger<DocumentService> _logger;

    public DocumentService(
        IRepository<Document> documentRepository,
        IBlobStorageService blobStorageService,
        ICacheService cacheService,
        IMapper mapper,
        ILogger<DocumentService> logger)
    {
        _documentRepository = documentRepository;
        _blobStorageService = blobStorageService;
        _cacheService = cacheService;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<DocumentDto> GetDocumentAsync(string id)
    {
        // Try cache first
        var cacheKey = $"document:{id}";
        var cached = await _cacheService.GetAsync<DocumentDto>(cacheKey);
        if (cached != null)
        {
            return cached;
        }

        // Fetch from database
        var document = await _documentRepository.GetByIdAsync(id);
        if (document == null)
        {
            throw new NotFoundException($"Document {id} not found");
        }

        var dto = _mapper.Map<DocumentDto>(document);

        // Cache for 5 minutes
        await _cacheService.SetAsync(cacheKey, dto, TimeSpan.FromMinutes(5));

        return dto;
    }

    public async Task<IEnumerable<DocumentDto>> GetDocumentsByFolderAsync(string folderId)
    {
        var documents = await _documentRepository.GetAllAsync();
        var filtered = documents.Where(d => d.FolderId == folderId);
        return _mapper.Map<IEnumerable<DocumentDto>>(filtered);
    }

    public async Task<DocumentDto> CreateDocumentAsync(
        CreateDocumentRequest request,
        Stream fileStream)
    {
        // Upload to blob storage
        var blobName = Guid.NewGuid().ToString();
        var blobUrl = await _blobStorageService.UploadAsync(blobName, fileStream);

        // Create document entity
        var document = new Document
        {
            Id = Guid.NewGuid().ToString(),
            Name = request.Name,
            FolderId = request.FolderId,
            BlobUrl = blobUrl,
            ContentType = request.ContentType,
            Size = fileStream.Length,
            UploadedAt = DateTime.UtcNow,
            Metadata = request.Metadata,
            Tags = request.Tags
        };

        // Save to database
        var created = await _documentRepository.CreateAsync(document);

        // Invalidate folder cache
        await _cacheService.RemoveAsync($"folder:contents:{request.FolderId}");

        _logger.LogInformation(
            "Document {DocumentId} created in folder {FolderId}",
            created.Id,
            request.FolderId
        );

        return _mapper.Map<DocumentDto>(created);
    }

    public async Task<DocumentDto> UpdateDocumentAsync(
        string id,
        UpdateDocumentRequest request)
    {
        var document = await _documentRepository.GetByIdAsync(id);
        if (document == null)
        {
            throw new NotFoundException($"Document {id} not found");
        }

        // Update properties
        document.Name = request.Name ?? document.Name;
        document.Metadata = request.Metadata ?? document.Metadata;
        document.Tags = request.Tags ?? document.Tags;
        document.ModifiedAt = DateTime.UtcNow;

        var updated = await _documentRepository.UpdateAsync(id, document);

        // Invalidate cache
        await _cacheService.RemoveAsync($"document:{id}");
        await _cacheService.RemoveAsync($"folder:contents:{document.FolderId}");

        return _mapper.Map<DocumentDto>(updated);
    }

    public async Task DeleteDocumentAsync(string id)
    {
        var document = await _documentRepository.GetByIdAsync(id);
        if (document == null)
        {
            throw new NotFoundException($"Document {id} not found");
        }

        // Delete from blob storage
        await _blobStorageService.DeleteAsync(GetBlobNameFromUrl(document.BlobUrl));

        // Delete from database
        await _documentRepository.DeleteAsync(id);

        // Invalidate cache
        await _cacheService.RemoveAsync($"document:{id}");
        await _cacheService.RemoveAsync($"folder:contents:{document.FolderId}");

        _logger.LogInformation("Document {DocumentId} deleted", id);
    }

    public async Task<string> GetDownloadUrlAsync(string id)
    {
        var document = await _documentRepository.GetByIdAsync(id);
        if (document == null)
        {
            throw new NotFoundException($"Document {id} not found");
        }

        // Generate SAS token for temporary access
        var blobName = GetBlobNameFromUrl(document.BlobUrl);
        return await _blobStorageService.GetDownloadUrlAsync(blobName, TimeSpan.FromHours(1));
    }

    private string GetBlobNameFromUrl(string url)
    {
        var uri = new Uri(url);
        return uri.Segments[^1];
    }
}
```

### 3. Result Pattern for Error Handling

**Purpose**: Return success or failure without throwing exceptions

```csharp
// Result.cs
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }

    private Result(bool isSuccess, T? value, string? error)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
    }

    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(string error) => new(false, default, error);

    public TResult Match<TResult>(
        Func<T, TResult> onSuccess,
        Func<string, TResult> onFailure)
    {
        return IsSuccess ? onSuccess(Value!) : onFailure(Error!);
    }
}

// Usage in service
public async Task<Result<Document>> CreateDocumentSafeAsync(CreateDocumentRequest request)
{
    try
    {
        var document = await CreateDocumentAsync(request);
        return Result<Document>.Success(document);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Failed to create document");
        return Result<Document>.Failure(ex.Message);
    }
}
```

---

## Best Practices

### 1. Use Dependency Injection

**Do**:
```csharp
// Program.cs
builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<IRepository<Document>, DocumentRepository>();
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// Service constructor
public DocumentService(
    IRepository<Document> repository,
    ILogger<DocumentService> logger)
{
    _repository = repository;
    _logger = logger;
}
```

**Don't**:
```csharp
// Creating dependencies manually
var service = new DocumentService(
    new DocumentRepository(),
    new Logger()
);
```

### 2. Use Configuration System

**Do**:
```csharp
// appsettings.json
{
  "CosmosDb": {
    "Endpoint": "https://...",
    "DatabaseName": "DocumentManager"
  }
}

// Reading config
public class CosmosDbSettings
{
    public string Endpoint { get; set; } = string.Empty;
    public string DatabaseName { get; set; } = string.Empty;
}

// Program.cs
builder.Services.Configure<CosmosDbSettings>(
    builder.Configuration.GetSection("CosmosDb")
);

// Usage
public class MyService
{
    private readonly CosmosDbSettings _settings;

    public MyService(IOptions<CosmosDbSettings> settings)
    {
        _settings = settings.Value;
    }
}
```

### 3. Use Structured Logging

**Do**:
```csharp
_logger.LogInformation(
    "Document {DocumentId} created by user {UserId}",
    documentId,
    userId
);
```

**Don't**:
```csharp
_logger.LogInformation(
    $"Document {documentId} created by user {userId}"
);
```

### 4. Use Async/Await Properly

**Do**:
```csharp
public async Task<Document> GetDocumentAsync(string id)
{
    return await _repository.GetByIdAsync(id);
}
```

**Don't**:
```csharp
// Blocking async code
public Document GetDocument(string id)
{
    return _repository.GetByIdAsync(id).Result; // Deadlock risk
}
```

### 5. Use Nullable Reference Types

**Do**:
```csharp
// Enable in .csproj
<Nullable>enable</Nullable>

public async Task<Document?> GetDocumentAsync(string id)
{
    // Explicitly nullable return
    return await _repository.GetByIdAsync(id);
}
```

---

## Common Patterns for Document Manager

### 1. Health Check Implementation

```csharp
// HealthChecks/CosmosDbHealthCheck.cs
using Microsoft.Extensions.Diagnostics.HealthChecks;

public class CosmosDbHealthCheck : IHealthCheck
{
    private readonly CosmosClient _cosmosClient;
    private readonly string _databaseName;

    public CosmosDbHealthCheck(CosmosClient cosmosClient, IConfiguration configuration)
    {
        _cosmosClient = cosmosClient;
        _databaseName = configuration["CosmosDb:DatabaseName"] ?? "DocumentManager";
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var database = _cosmosClient.GetDatabase(_databaseName);
            await database.ReadAsync(cancellationToken: cancellationToken);

            return HealthCheckResult.Healthy("Cosmos DB is healthy");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                "Cosmos DB is unhealthy",
                ex
            );
        }
    }
}

// Program.cs
builder.Services
    .AddHealthChecks()
    .AddCheck<CosmosDbHealthCheck>("cosmosdb")
    .AddCheck<BlobStorageHealthCheck>("blobstorage")
    .AddCheck<RedisHealthCheck>("redis");

app.MapHealthChecks("/health");
```

### 2. Global Exception Handler

```csharp
// Middleware/GlobalExceptionHandler.cs
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        _logger.LogError(
            exception,
            "Exception occurred: {Message}",
            exception.Message
        );

        var (statusCode, title) = exception switch
        {
            NotFoundException => (StatusCodes.Status404NotFound, "Not Found"),
            ValidationException => (StatusCodes.Status400BadRequest, "Validation Error"),
            UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "Unauthorized"),
            _ => (StatusCodes.Status500InternalServerError, "Internal Server Error")
        };

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = exception.Message,
            Instance = httpContext.Request.Path
        };

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

        return true;
    }
}

// Program.cs
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
```

### 3. Request Validation

```csharp
// Validators/CreateDocumentRequestValidator.cs
using FluentValidation;

public class CreateDocumentRequestValidator : AbstractValidator<CreateDocumentRequest>
{
    public CreateDocumentRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Document name is required")
            .MaximumLength(100).WithMessage("Name cannot exceed 100 characters");

        RuleFor(x => x.FolderId)
            .NotEmpty().WithMessage("Folder ID is required");

        RuleFor(x => x.ContentType)
            .NotEmpty().WithMessage("Content type is required")
            .Must(BeValidContentType).WithMessage("Invalid content type");

        RuleFor(x => x.Tags)
            .Must(x => x == null || x.Count <= 10)
            .WithMessage("Maximum 10 tags allowed");
    }

    private bool BeValidContentType(string contentType)
    {
        var allowedTypes = new[]
        {
            "application/pdf",
            "image/jpeg",
            "image/png",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        };

        return allowedTypes.Contains(contentType);
    }
}

// Program.cs
builder.Services.AddValidatorsFromAssemblyContaining<CreateDocumentRequestValidator>();

// Usage in endpoint
app.MapPost("/api/documents", async (
    CreateDocumentRequest request,
    IValidator<CreateDocumentRequest> validator,
    IDocumentService documentService) =>
{
    var validationResult = await validator.ValidateAsync(request);
    if (!validationResult.IsValid)
    {
        return Results.ValidationProblem(validationResult.ToDictionary());
    }

    var document = await documentService.CreateDocumentAsync(request);
    return Results.Created($"/api/documents/{document.Id}", document);
});
```

---

## Minimal APIs

### 1. Basic Endpoint

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/api/documents", async (IDocumentService service) =>
{
    var documents = await service.GetAllDocumentsAsync();
    return Results.Ok(documents);
});

app.MapGet("/api/documents/{id}", async (string id, IDocumentService service) =>
{
    var document = await service.GetDocumentAsync(id);
    return document != null ? Results.Ok(document) : Results.NotFound();
});

app.MapPost("/api/documents", async (
    CreateDocumentRequest request,
    IDocumentService service) =>
{
    var document = await service.CreateDocumentAsync(request);
    return Results.Created($"/api/documents/{document.Id}", document);
});

app.MapPut("/api/documents/{id}", async (
    string id,
    UpdateDocumentRequest request,
    IDocumentService service) =>
{
    var document = await service.UpdateDocumentAsync(id, request);
    return Results.Ok(document);
});

app.MapDelete("/api/documents/{id}", async (
    string id,
    IDocumentService service) =>
{
    await service.DeleteDocumentAsync(id);
    return Results.NoContent();
});

app.Run();
```

### 2. Endpoint Filters

```csharp
// Filters/ApiKeyAuthFilter.cs
public class ApiKeyAuthFilter : IEndpointFilter
{
    private readonly string _apiKey;

    public ApiKeyAuthFilter(IConfiguration configuration)
    {
        _apiKey = configuration["ApiKey"] ?? throw new Exception("API key not configured");
    }

    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        if (!context.HttpContext.Request.Headers.TryGetValue("X-API-Key", out var providedKey) ||
            providedKey != _apiKey)
        {
            return Results.Unauthorized();
        }

        return await next(context);
    }
}

// Usage
app.MapGet("/api/documents", async (IDocumentService service) =>
{
    return Results.Ok(await service.GetAllDocumentsAsync());
})
.AddEndpointFilter<ApiKeyAuthFilter>();
```

---

## Performance Optimization

### 1. Use Span<T> for Memory Efficiency

```csharp
public void ProcessLargeFile(ReadOnlySpan<byte> fileData)
{
    // No heap allocation for slice
    var header = fileData[..100];
    var content = fileData[100..];

    // Process without copying
}
```

### 2. Use ValueTask for Hot Paths

```csharp
public async ValueTask<Document?> GetCachedDocumentAsync(string id)
{
    // Try cache (synchronous check)
    if (_cache.TryGetValue(id, out var cached))
    {
        return cached; // No async state machine allocation
    }

    // Fall back to async
    return await _repository.GetByIdAsync(id);
}
```

### 3. Use HttpClientFactory

```csharp
// Program.cs
builder.Services.AddHttpClient("ExternalApi", client =>
{
    client.BaseAddress = new Uri("https://api.example.com");
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Usage
public class MyService
{
    private readonly IHttpClientFactory _httpClientFactory;

    public MyService(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    public async Task<string> GetDataAsync()
    {
        var client = _httpClientFactory.CreateClient("ExternalApi");
        return await client.GetStringAsync("/data");
    }
}
```

---

## Testing

### Unit Test Example (xUnit)

```csharp
using Xunit;
using Moq;
using FluentAssertions;

public class DocumentServiceTests
{
    private readonly Mock<IRepository<Document>> _repositoryMock;
    private readonly Mock<IBlobStorageService> _blobStorageMock;
    private readonly Mock<ILogger<DocumentService>> _loggerMock;
    private readonly DocumentService _sut;

    public DocumentServiceTests()
    {
        _repositoryMock = new Mock<IRepository<Document>>();
        _blobStorageMock = new Mock<IBlobStorageService>();
        _loggerMock = new Mock<ILogger<DocumentService>>();

        _sut = new DocumentService(
            _repositoryMock.Object,
            _blobStorageMock.Object,
            _loggerMock.Object
        );
    }

    [Fact]
    public async Task GetDocumentAsync_WhenDocumentExists_ReturnsDocument()
    {
        // Arrange
        var documentId = "doc-123";
        var expectedDocument = new Document
        {
            Id = documentId,
            Name = "Test.pdf"
        };

        _repositoryMock
            .Setup(x => x.GetByIdAsync(documentId))
            .ReturnsAsync(expectedDocument);

        // Act
        var result = await _sut.GetDocumentAsync(documentId);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(documentId);
        result.Name.Should().Be("Test.pdf");
    }

    [Fact]
    public async Task DeleteDocumentAsync_WhenCalled_DeletesFromBothStorages()
    {
        // Arrange
        var documentId = "doc-123";
        var document = new Document
        {
            Id = documentId,
            BlobUrl = "https://storage.blob.core.windows.net/container/file.pdf"
        };

        _repositoryMock
            .Setup(x => x.GetByIdAsync(documentId))
            .ReturnsAsync(document);

        // Act
        await _sut.DeleteDocumentAsync(documentId);

        // Assert
        _blobStorageMock.Verify(
            x => x.DeleteAsync(It.IsAny<string>()),
            Times.Once
        );

        _repositoryMock.Verify(
            x => x.DeleteAsync(documentId),
            Times.Once
        );
    }
}
```

---

## Common Pitfalls

### 1. Not Disposing Resources

**Don't**:
```csharp
var stream = File.OpenRead("file.txt");
// Forgot to dispose
```

**Do**:
```csharp
using var stream = File.OpenRead("file.txt");
// Automatically disposed

// Or
await using var stream = File.OpenRead("file.txt");
```

### 2. Blocking Async Code

**Don't**:
```csharp
public void ProcessDocument(string id)
{
    var doc = GetDocumentAsync(id).Result; // Deadlock risk
}
```

**Do**:
```csharp
public async Task ProcessDocumentAsync(string id)
{
    var doc = await GetDocumentAsync(id);
}
```

### 3. Not Using ConfigureAwait in Libraries

**Do** (in library code):
```csharp
public async Task<Document> GetDocumentAsync(string id)
{
    return await _repository
        .GetByIdAsync(id)
        .ConfigureAwait(false); // Don't capture context
}
```

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://learn.microsoft.com/dotnet
- **API Reference**: https://learn.microsoft.com/dotnet/api
- **What's New**: https://learn.microsoft.com/dotnet/core/whats-new/dotnet-8

### Learning Resources
- **Microsoft Learn**: https://learn.microsoft.com/training/dotnet/
- **.NET Blog**: https://devblogs.microsoft.com/dotnet/
- **Patterns & Practices**: https://learn.microsoft.com/azure/architecture/

### Community
- **GitHub**: https://github.com/dotnet
- **Stack Overflow**: Tag `.net`
- **.NET Foundation**: https://dotnetfoundation.org

---

## Quick Reference

### Common CLI Commands

```bash
# Create new project
dotnet new webapi -n MyApi

# Add package
dotnet add package Microsoft.Azure.Cosmos

# Build
dotnet build

# Run
dotnet run

# Test
dotnet test

# Publish
dotnet publish -c Release
```

### Project File (.csproj)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Azure.Cosmos" Version="3.38.0" />
    <PackageReference Include="Azure.Storage.Blobs" Version="12.19.0" />
    <PackageReference Include="StackExchange.Redis" Version="2.7.10" />
  </ItemGroup>
</Project>
```

---

**For this project**: Use .NET 8 for all backend services. Follow async/await patterns, use dependency injection, implement proper logging, and leverage Azure SDKs for cloud integration.

**Last Updated**: 2025-09-30
