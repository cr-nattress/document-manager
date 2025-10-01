# Azure Functions - Comprehensive Guide

**Technology**: Azure Functions
**Category**: Serverless Compute
**Official Docs**: https://learn.microsoft.com/azure/azure-functions

---

## Overview

Azure Functions is a serverless compute service that lets you run event-triggered code without explicitly provisioning or managing infrastructure. Perfect for building HTTP APIs, processing data, and integrating systems.

### Key Features
- **Serverless** - No infrastructure management
- **Event-Driven** - Triggered by HTTP, timers, queues, and more
- **Auto-Scaling** - Scales automatically based on load
- **Pay-Per-Use** - Only pay for execution time
- **Multiple Languages** - C#, JavaScript, Python, Java, PowerShell
- **Integrated Security** - Built-in authentication and authorization
- **Local Development** - Test locally with Azure Functions Core Tools

---

## Design Patterns

### 1. HTTP Triggered Function (Minimal API Style)

**Purpose**: Create REST API endpoints

```csharp
// GetDocuments.cs
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

public class GetDocuments
{
    private readonly IDocumentService _documentService;
    private readonly ILogger<GetDocuments> _logger;

    public GetDocuments(
        IDocumentService documentService,
        ILogger<GetDocuments> logger)
    {
        _documentService = documentService;
        _logger = logger;
    }

    [Function("GetDocuments")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "documents")]
        HttpRequestData req)
    {
        _logger.LogInformation("Fetching all documents");

        try
        {
            var documents = await _documentService.GetAllDocumentsAsync();

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(documents);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching documents");

            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Failed to fetch documents" });

            return response;
        }
    }
}

// GetDocumentById.cs
public class GetDocumentById
{
    private readonly IDocumentService _documentService;
    private readonly ILogger<GetDocumentById> _logger;

    public GetDocumentById(
        IDocumentService documentService,
        ILogger<GetDocumentById> logger)
    {
        _documentService = documentService;
        _logger = logger;
    }

    [Function("GetDocumentById")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "documents/{id}")]
        HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Fetching document {DocumentId}", id);

        try
        {
            var document = await _documentService.GetDocumentAsync(id);

            if (document == null)
            {
                var notFoundResponse = req.CreateResponse(HttpStatusCode.NotFound);
                await notFoundResponse.WriteAsJsonAsync(new { error = "Document not found" });
                return notFoundResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(document);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching document {DocumentId}", id);

            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Failed to fetch document" });

            return response;
        }
    }
}

// CreateDocument.cs
public class CreateDocument
{
    private readonly IDocumentService _documentService;
    private readonly ILogger<CreateDocument> _logger;

    public CreateDocument(
        IDocumentService documentService,
        ILogger<CreateDocument> logger)
    {
        _documentService = documentService;
        _logger = logger;
    }

    [Function("CreateDocument")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "documents")]
        HttpRequestData req)
    {
        _logger.LogInformation("Creating new document");

        try
        {
            var request = await req.ReadFromJsonAsync<CreateDocumentRequest>();

            if (request == null)
            {
                var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequest.WriteAsJsonAsync(new { error = "Invalid request body" });
                return badRequest;
            }

            var document = await _documentService.CreateDocumentAsync(request);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Location", $"/api/documents/{document.Id}");
            await response.WriteAsJsonAsync(document);

            return response;
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation failed");

            var response = req.CreateResponse(HttpStatusCode.BadRequest);
            await response.WriteAsJsonAsync(new { error = ex.Message });

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating document");

            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Failed to create document" });

            return response;
        }
    }
}
```

### 2. File Upload Function with Multipart Form Data

**Purpose**: Handle file uploads

```csharp
// UploadDocument.cs
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Net;

public class UploadDocument
{
    private readonly IDocumentService _documentService;
    private readonly ILogger<UploadDocument> _logger;

    public UploadDocument(
        IDocumentService documentService,
        ILogger<UploadDocument> logger)
    {
        _documentService = documentService;
        _logger = logger;
    }

    [Function("UploadDocument")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "documents/upload")]
        HttpRequestData req)
    {
        _logger.LogInformation("Processing document upload");

        try
        {
            if (!req.Headers.TryGetValues("Content-Type", out var contentTypeValues) ||
                !contentTypeValues.First().Contains("multipart/form-data"))
            {
                var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequest.WriteAsJsonAsync(new { error = "Content-Type must be multipart/form-data" });
                return badRequest;
            }

            // Parse multipart form data
            var formData = await req.ParseMultipartFormDataAsync();

            if (!formData.Files.TryGetValue("file", out var file))
            {
                var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequest.WriteAsJsonAsync(new { error = "File is required" });
                return badRequest;
            }

            // Create request from form fields
            var request = new CreateDocumentRequest
            {
                Name = formData.Fields.GetValueOrDefault("name", file.FileName),
                FolderId = formData.Fields["folderId"],
                ContentType = file.ContentType,
                Metadata = ParseMetadata(formData.Fields.GetValueOrDefault("metadata")),
                Tags = ParseTags(formData.Fields.GetValueOrDefault("tags"))
            };

            // Upload document
            var document = await _documentService.CreateDocumentAsync(request, file.Stream);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Location", $"/api/documents/{document.Id}");
            await response.WriteAsJsonAsync(document);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading document");

            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Failed to upload document" });

            return response;
        }
    }

    private Dictionary<string, string>? ParseMetadata(string? json)
    {
        if (string.IsNullOrEmpty(json)) return null;
        return JsonSerializer.Deserialize<Dictionary<string, string>>(json);
    }

    private List<string>? ParseTags(string? json)
    {
        if (string.IsNullOrEmpty(json)) return null;
        return JsonSerializer.Deserialize<List<string>>(json);
    }
}
```

### 3. Timer Triggered Function

**Purpose**: Run scheduled tasks

```csharp
// CleanupOldDocuments.cs
public class CleanupOldDocuments
{
    private readonly IDocumentService _documentService;
    private readonly ILogger<CleanupOldDocuments> _logger;

    public CleanupOldDocuments(
        IDocumentService documentService,
        ILogger<CleanupOldDocuments> logger)
    {
        _documentService = documentService;
        _logger = logger;
    }

    [Function("CleanupOldDocuments")]
    public async Task Run(
        [TimerTrigger("0 0 2 * * *")] TimerInfo timer) // Daily at 2 AM
    {
        _logger.LogInformation("Starting cleanup of old documents at {Time}", DateTime.UtcNow);

        try
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-90); // 90 days old
            var deletedCount = await _documentService.DeleteOldDocumentsAsync(cutoffDate);

            _logger.LogInformation("Cleaned up {Count} old documents", deletedCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during cleanup");
        }

        _logger.LogInformation("Next cleanup scheduled for {NextRun}", timer.ScheduleStatus?.Next);
    }
}
```

---

## Best Practices

### 1. Use Dependency Injection

**Program.cs**:
```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Register services
        services.AddScoped<IDocumentService, DocumentService>();
        services.AddScoped<IRepository<Document>, DocumentRepository>();
        services.AddSingleton<IBlobStorageService, BlobStorageService>();
        services.AddSingleton<ICacheService, RedisCacheService>();

        // Configure Cosmos DB
        services.AddSingleton<CosmosClient>(sp =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            return new CosmosClient(
                config["CosmosDb:Endpoint"],
                config["CosmosDb:Key"]
            );
        });

        // Configure Blob Storage
        services.AddSingleton<BlobServiceClient>(sp =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            return new BlobServiceClient(config["AzureStorage:ConnectionString"]);
        });
    })
    .Build();

host.Run();
```

### 2. Use Application Insights for Monitoring

**host.json**:
```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20
      }
    },
    "logLevel": {
      "default": "Information",
      "Microsoft": "Warning"
    }
  },
  "functionTimeout": "00:05:00"
}
```

### 3. Implement API Key Authentication

```csharp
// Middleware/ApiKeyAuthMiddleware.cs
public class ApiKeyAuthMiddleware : IFunctionsWorkerMiddleware
{
    private readonly string _apiKey;

    public ApiKeyAuthMiddleware(IConfiguration configuration)
    {
        _apiKey = configuration["ApiKey"] ?? throw new Exception("API key not configured");
    }

    public async Task Invoke(FunctionContext context, FunctionExecutionDelegate next)
    {
        var requestData = await context.GetHttpRequestDataAsync();

        if (requestData != null)
        {
            if (!requestData.Headers.TryGetValues("X-API-Key", out var providedKey) ||
                !providedKey.Contains(_apiKey))
            {
                var response = requestData.CreateResponse(HttpStatusCode.Unauthorized);
                await response.WriteAsJsonAsync(new { error = "Invalid API key" });

                context.GetInvocationResult().Value = response;
                return;
            }
        }

        await next(context);
    }
}

// Program.cs
var host = new HostBuilder()
    .ConfigureFunctionsWebApplication(builder =>
    {
        builder.UseMiddleware<ApiKeyAuthMiddleware>();
    })
    .Build();
```

### 4. Use Structured Configuration

**local.settings.json** (development):
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "CosmosDb__Endpoint": "https://localhost:8081",
    "CosmosDb__Key": "...",
    "CosmosDb__DatabaseName": "DocumentManager",
    "AzureStorage__ConnectionString": "...",
    "Redis__ConnectionString": "localhost:6379",
    "ApiKey": "dev-api-key-12345"
  }
}
```

### 5. Handle Errors Gracefully

```csharp
public static class ResponseHelper
{
    public static async Task<HttpResponseData> CreateErrorResponse(
        HttpRequestData req,
        HttpStatusCode statusCode,
        string message)
    {
        var response = req.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(new
        {
            error = message,
            timestamp = DateTime.UtcNow,
            path = req.Url.AbsolutePath
        });
        return response;
    }

    public static async Task<HttpResponseData> CreateSuccessResponse<T>(
        HttpRequestData req,
        T data,
        HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        var response = req.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(data);
        return response;
    }
}

// Usage
try
{
    var document = await _documentService.GetDocumentAsync(id);
    return await ResponseHelper.CreateSuccessResponse(req, document);
}
catch (NotFoundException ex)
{
    return await ResponseHelper.CreateErrorResponse(
        req,
        HttpStatusCode.NotFound,
        ex.Message
    );
}
```

---

## Common Patterns for Document Manager

### 1. CORS Configuration

```csharp
// Program.cs
var host = new HostBuilder()
    .ConfigureFunctionsWebApplication(builder =>
    {
        builder.UseCors(options =>
        {
            options
                .WithOrigins("http://localhost:5173", "https://yourdomain.com")
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials();
        });
    })
    .Build();
```

### 2. Response Caching

```csharp
public class CachedDocumentQuery
{
    private readonly IDocumentService _documentService;
    private readonly ICacheService _cacheService;

    [Function("GetDocumentsCached")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "documents/cached")]
        HttpRequestData req)
    {
        var cacheKey = "documents:all";

        // Try cache first
        var cached = await _cacheService.GetAsync<List<DocumentDto>>(cacheKey);
        if (cached != null)
        {
            var cachedResponse = req.CreateResponse(HttpStatusCode.OK);
            cachedResponse.Headers.Add("X-Cache", "HIT");
            await cachedResponse.WriteAsJsonAsync(cached);
            return cachedResponse;
        }

        // Fetch from service
        var documents = await _documentService.GetAllDocumentsAsync();

        // Cache for 5 minutes
        await _cacheService.SetAsync(cacheKey, documents, TimeSpan.FromMinutes(5));

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("X-Cache", "MISS");
        await response.WriteAsJsonAsync(documents);

        return response;
    }
}
```

### 3. Request Validation

```csharp
public class ValidatedCreateDocument
{
    private readonly IDocumentService _documentService;
    private readonly IValidator<CreateDocumentRequest> _validator;

    [Function("CreateDocumentValidated")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "documents")]
        HttpRequestData req)
    {
        var request = await req.ReadFromJsonAsync<CreateDocumentRequest>();

        if (request == null)
        {
            return await ResponseHelper.CreateErrorResponse(
                req,
                HttpStatusCode.BadRequest,
                "Invalid request body"
            );
        }

        // Validate request
        var validationResult = await _validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            var errors = validationResult.Errors
                .Select(e => new { field = e.PropertyName, error = e.ErrorMessage });

            var response = req.CreateResponse(HttpStatusCode.BadRequest);
            await response.WriteAsJsonAsync(new { errors });
            return response;
        }

        // Process valid request
        var document = await _documentService.CreateDocumentAsync(request);
        return await ResponseHelper.CreateSuccessResponse(req, document, HttpStatusCode.Created);
    }
}
```

---

## Local Development

### 1. Install Azure Functions Core Tools

```bash
# Windows (via npm)
npm install -g azure-functions-core-tools@4

# macOS (via Homebrew)
brew tap azure/functions
brew install azure-functions-core-tools@4

# Ubuntu/Debian
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4
```

### 2. Run Locally

```bash
# Start functions locally
func start

# With specific port
func start --port 7072

# With debug
func start --debug
```

### 3. Test with curl

```bash
# GET request
curl http://localhost:7071/api/documents

# POST request
curl -X POST http://localhost:7071/api/documents \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"name":"test.pdf","folderId":"folder-1"}'
```

---

## Deployment

### 1. Deploy via Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name myResourceGroup --location eastus

# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS

# Create function app
az functionapp create \
  --resource-group myResourceGroup \
  --consumption-plan-location eastus \
  --runtime dotnet-isolated \
  --runtime-version 8 \
  --functions-version 4 \
  --name myFunctionApp \
  --storage-account mystorageaccount

# Deploy
func azure functionapp publish myFunctionApp
```

### 2. Configure Application Settings

```bash
# Set app settings
az functionapp config appsettings set \
  --name myFunctionApp \
  --resource-group myResourceGroup \
  --settings \
    "CosmosDb__Endpoint=https://..." \
    "CosmosDb__Key=..." \
    "ApiKey=prod-key-xyz"
```

---

## Testing

### Unit Test Example (xUnit)

```csharp
using Xunit;
using Moq;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

public class GetDocumentsTests
{
    private readonly Mock<IDocumentService> _serviceMock;
    private readonly Mock<ILogger<GetDocuments>> _loggerMock;
    private readonly GetDocuments _function;

    public GetDocumentsTests()
    {
        _serviceMock = new Mock<IDocumentService>();
        _loggerMock = new Mock<ILogger<GetDocuments>>();
        _function = new GetDocuments(_serviceMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task Run_ReturnsOkWithDocuments()
    {
        // Arrange
        var mockDocuments = new List<DocumentDto>
        {
            new() { Id = "1", Name = "Doc1.pdf" },
            new() { Id = "2", Name = "Doc2.pdf" }
        };

        _serviceMock
            .Setup(x => x.GetAllDocumentsAsync())
            .ReturnsAsync(mockDocuments);

        var context = new Mock<FunctionContext>();
        var req = MockHttpRequestData.Create();

        // Act
        var response = await _function.Run(req);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        _serviceMock.Verify(x => x.GetAllDocumentsAsync(), Times.Once);
    }
}
```

---

## Common Pitfalls

### 1. Not Using Isolated Worker Process

**Do**: Use .NET isolated worker (recommended)
```xml
<TargetFramework>net8.0</TargetFramework>
<AzureFunctionsVersion>v4</AzureFunctionsVersion>
<OutputType>Exe</OutputType>
```

### 2. Forgetting Function Timeout

**host.json**:
```json
{
  "version": "2.0",
  "functionTimeout": "00:05:00"
}
```

### 3. Not Handling Cold Starts

**Strategy**: Use Premium plan or keep functions warm
```csharp
[Function("KeepWarm")]
public HttpResponseData KeepWarm(
    [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")]
    HttpRequestData req)
{
    return req.CreateResponse(HttpStatusCode.OK);
}
```

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://learn.microsoft.com/azure/azure-functions
- **C# Developer Guide**: https://learn.microsoft.com/azure/azure-functions/dotnet-isolated-process-guide
- **Triggers & Bindings**: https://learn.microsoft.com/azure/azure-functions/functions-triggers-bindings

### Learning Resources
- **Microsoft Learn**: https://learn.microsoft.com/training/paths/create-serverless-applications/
- **Azure Samples**: https://github.com/Azure-Samples/azure-functions-samples

### Community
- **GitHub**: https://github.com/Azure/azure-functions
- **Stack Overflow**: Tag `azure-functions`

---

## Quick Reference

### Timer Trigger CRON Expressions

| Expression | Description |
|------------|-------------|
| `0 */5 * * * *` | Every 5 minutes |
| `0 0 * * * *` | Every hour |
| `0 0 0 * * *` | Every day at midnight |
| `0 0 9 * * MON-FRI` | 9 AM weekdays |

### HTTP Response Helper

```csharp
// Extension method
public static class HttpResponseExtensions
{
    public static async Task<HttpResponseData> WriteJsonAsync<T>(
        this HttpResponseData response,
        T data,
        HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        response.StatusCode = statusCode;
        await response.WriteAsJsonAsync(data);
        return response;
    }
}
```

---

**For this project**: Use Azure Functions v4 with .NET 8 isolated worker process. Implement HTTP-triggered functions for all API endpoints, use dependency injection, implement API key authentication, and integrate with Application Insights for monitoring.

**Last Updated**: 2025-09-30
