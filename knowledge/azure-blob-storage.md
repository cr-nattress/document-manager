# Azure Blob Storage - Comprehensive Guide

**Technology**: Azure Blob Storage
**Category**: Object Storage
**Official Docs**: https://learn.microsoft.com/azure/storage/blobs

---

## Overview

Azure Blob Storage is Microsoft's object storage solution for the cloud, optimized for storing massive amounts of unstructured data such as documents, images, videos, and backups.

### Key Features
- **Massive Scale** - Store exabytes of data
- **Tiered Storage** - Hot, Cool, and Archive tiers for cost optimization
- **High Availability** - 99.9% availability SLA
- **Security** - Encryption at rest and in transit
- **SAS Tokens** - Secure, time-limited access
- **Versioning** - Track changes to blobs
- **Soft Delete** - Recover accidentally deleted blobs
- **Immutability** - WORM (Write Once, Read Many) support

---

## Design Patterns

### 1. Blob Storage Service

**Purpose**: Centralize blob operations

```csharp
// Services/BlobStorageService.cs
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;

public interface IBlobStorageService
{
    Task<string> UploadAsync(string blobName, Stream content, string contentType);
    Task<Stream> DownloadAsync(string blobName);
    Task<string> GetDownloadUrlAsync(string blobName, TimeSpan expiration);
    Task DeleteAsync(string blobName);
    Task<bool> ExistsAsync(string blobName);
    Task<BlobProperties> GetPropertiesAsync(string blobName);
}

public class BlobStorageService : IBlobStorageService
{
    private readonly BlobContainerClient _containerClient;
    private readonly ILogger<BlobStorageService> _logger;

    public BlobStorageService(
        BlobServiceClient blobServiceClient,
        IConfiguration configuration,
        ILogger<BlobStorageService> logger)
    {
        var containerName = configuration["AzureStorage:ContainerName"] ?? "documents";
        _containerClient = blobServiceClient.GetBlobContainerClient(containerName);
        _logger = logger;
    }

    public async Task<string> UploadAsync(string blobName, Stream content, string contentType)
    {
        try
        {
            var blobClient = _containerClient.GetBlobClient(blobName);

            var uploadOptions = new BlobUploadOptions
            {
                HttpHeaders = new BlobHttpHeaders
                {
                    ContentType = contentType
                },
                Metadata = new Dictionary<string, string>
                {
                    ["UploadedAt"] = DateTime.UtcNow.ToString("O")
                }
            };

            await blobClient.UploadAsync(content, uploadOptions);

            _logger.LogInformation(
                "Uploaded blob {BlobName} ({ContentType})",
                blobName,
                contentType
            );

            return blobClient.Uri.ToString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading blob {BlobName}", blobName);
            throw;
        }
    }

    public async Task<Stream> DownloadAsync(string blobName)
    {
        try
        {
            var blobClient = _containerClient.GetBlobClient(blobName);
            var response = await blobClient.DownloadStreamingAsync();

            _logger.LogInformation("Downloaded blob {BlobName}", blobName);

            return response.Value.Content;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error downloading blob {BlobName}", blobName);
            throw;
        }
    }

    public async Task<string> GetDownloadUrlAsync(string blobName, TimeSpan expiration)
    {
        try
        {
            var blobClient = _containerClient.GetBlobClient(blobName);

            // Check if blob exists
            if (!await blobClient.ExistsAsync())
            {
                throw new FileNotFoundException($"Blob {blobName} not found");
            }

            // Generate SAS token
            var sasBuilder = new BlobSasBuilder
            {
                BlobContainerName = _containerClient.Name,
                BlobName = blobName,
                Resource = "b", // Blob
                StartsOn = DateTimeOffset.UtcNow.AddMinutes(-5), // Grace period
                ExpiresOn = DateTimeOffset.UtcNow.Add(expiration)
            };

            sasBuilder.SetPermissions(BlobSasPermissions.Read);

            var sasToken = blobClient.GenerateSasUri(sasBuilder).ToString();

            _logger.LogInformation(
                "Generated SAS token for {BlobName}, expires at {Expiration}",
                blobName,
                sasBuilder.ExpiresOn
            );

            return sasToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating SAS token for {BlobName}", blobName);
            throw;
        }
    }

    public async Task DeleteAsync(string blobName)
    {
        try
        {
            var blobClient = _containerClient.GetBlobClient(blobName);
            await blobClient.DeleteIfExistsAsync();

            _logger.LogInformation("Deleted blob {BlobName}", blobName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting blob {BlobName}", blobName);
            throw;
        }
    }

    public async Task<bool> ExistsAsync(string blobName)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);
        return await blobClient.ExistsAsync();
    }

    public async Task<BlobProperties> GetPropertiesAsync(string blobName)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);
        var response = await blobClient.GetPropertiesAsync();
        return response.Value;
    }
}
```

### 2. Chunked Upload for Large Files

**Purpose**: Upload large files in chunks with progress tracking

```csharp
public class ChunkedBlobUploadService
{
    private readonly BlobContainerClient _containerClient;
    private readonly ILogger<ChunkedBlobUploadService> _logger;
    private const int ChunkSize = 4 * 1024 * 1024; // 4 MB

    public async Task<string> UploadLargeFileAsync(
        string blobName,
        Stream content,
        string contentType,
        IProgress<double>? progress = null)
    {
        var blobClient = _containerClient.GetBlockBlobClient(blobName);

        var blockIds = new List<string>();
        var buffer = new byte[ChunkSize];
        var totalBytes = content.Length;
        var uploadedBytes = 0L;

        try
        {
            while (true)
            {
                var bytesRead = await content.ReadAsync(buffer, 0, ChunkSize);
                if (bytesRead == 0) break;

                // Generate unique block ID
                var blockId = Convert.ToBase64String(Guid.NewGuid().ToByteArray());
                blockIds.Add(blockId);

                // Upload block
                using var blockStream = new MemoryStream(buffer, 0, bytesRead);
                await blobClient.StageBlockAsync(blockId, blockStream);

                uploadedBytes += bytesRead;

                // Report progress
                if (progress != null && totalBytes > 0)
                {
                    var progressPercentage = (double)uploadedBytes / totalBytes * 100;
                    progress.Report(progressPercentage);
                }

                _logger.LogDebug(
                    "Uploaded chunk {ChunkNumber}, {UploadedBytes}/{TotalBytes}",
                    blockIds.Count,
                    uploadedBytes,
                    totalBytes
                );
            }

            // Commit blocks
            await blobClient.CommitBlockListAsync(
                blockIds,
                new BlobHttpHeaders { ContentType = contentType }
            );

            _logger.LogInformation(
                "Completed upload of {BlobName} in {ChunkCount} chunks",
                blobName,
                blockIds.Count
            );

            return blobClient.Uri.ToString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during chunked upload of {BlobName}", blobName);
            throw;
        }
    }
}
```

### 3. Blob Lifecycle Management

**Purpose**: Automatically transition blobs to different tiers or delete them

```json
{
  "rules": [
    {
      "enabled": true,
      "name": "MoveOldDocumentsToCool",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["documents/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        }
      }
    }
  ]
}
```

---

## Best Practices

### 1. Use Hierarchical Namespace

**Structure**:
```
documents/
  ├── 2025/
  │   ├── 01/
  │   │   ├── doc-uuid-1.pdf
  │   │   └── doc-uuid-2.pdf
  │   └── 02/
  └── thumbnails/
      └── doc-uuid-1-thumb.jpg
```

**Implementation**:
```csharp
public string GenerateBlobPath(Document document)
{
    var uploadDate = document.UploadedAt;
    return $"documents/{uploadDate.Year}/{uploadDate.Month:D2}/{document.Id}{Path.GetExtension(document.Name)}";
}
```

### 2. Use Appropriate Access Tiers

```csharp
public class BlobTierService
{
    public async Task SetAccessTierAsync(string blobName, AccessTier tier)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);

        await blobClient.SetAccessTierAsync(tier);

        _logger.LogInformation(
            "Set access tier for {BlobName} to {Tier}",
            blobName,
            tier
        );
    }

    public async Task ArchiveOldDocumentsAsync(DateTime cutoffDate)
    {
        await foreach (var blobItem in _containerClient.GetBlobsAsync())
        {
            if (blobItem.Properties.LastModified < cutoffDate &&
                blobItem.Properties.AccessTier == AccessTier.Hot)
            {
                await SetAccessTierAsync(blobItem.Name, AccessTier.Archive);
            }
        }
    }
}
```

### 3. Implement Retry Policies

```csharp
var options = new BlobClientOptions
{
    Retry =
    {
        MaxRetries = 3,
        Delay = TimeSpan.FromSeconds(2),
        MaxDelay = TimeSpan.FromSeconds(10),
        Mode = RetryMode.Exponential
    }
};

var blobServiceClient = new BlobServiceClient(connectionString, options);
```

### 4. Enable Soft Delete

```csharp
public async Task EnableSoftDeleteAsync(BlobServiceClient serviceClient, int retentionDays = 7)
{
    var properties = await serviceClient.GetPropertiesAsync();

    properties.Value.DeleteRetentionPolicy = new BlobRetentionPolicy
    {
        Enabled = true,
        Days = retentionDays
    };

    await serviceClient.SetPropertiesAsync(properties);

    _logger.LogInformation("Enabled soft delete with {Days} day retention", retentionDays);
}

public async Task<List<BlobItem>> ListDeletedBlobsAsync()
{
    var deletedBlobs = new List<BlobItem>();

    await foreach (var blobItem in _containerClient.GetBlobsAsync(
        BlobTraits.None,
        BlobStates.Deleted))
    {
        deletedBlobs.Add(blobItem);
    }

    return deletedBlobs;
}

public async Task RestoreBlobAsync(string blobName)
{
    var blobClient = _containerClient.GetBlobClient(blobName);
    await blobClient.UndeleteAsync();

    _logger.LogInformation("Restored deleted blob {BlobName}", blobName);
}
```

### 5. Use Metadata for Search and Organization

```csharp
public async Task SetBlobMetadataAsync(string blobName, Dictionary<string, string> metadata)
{
    var blobClient = _containerClient.GetBlobClient(blobName);

    await blobClient.SetMetadataAsync(metadata);

    _logger.LogInformation("Set metadata for {BlobName}", blobName);
}

public async Task<Dictionary<string, string>> GetBlobMetadataAsync(string blobName)
{
    var blobClient = _containerClient.GetBlobClient(blobName);
    var properties = await blobClient.GetPropertiesAsync();

    return properties.Value.Metadata.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);
}
```

---

## Common Patterns for Document Manager

### 1. Document Upload with Validation

```csharp
public class SecureBlobUploadService
{
    private readonly IBlobStorageService _blobService;
    private readonly ILogger<SecureBlobUploadService> _logger;

    private readonly HashSet<string> _allowedContentTypes = new()
    {
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/gif",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    };

    private const long MaxFileSize = 100 * 1024 * 1024; // 100 MB

    public async Task<string> UploadDocumentAsync(
        Stream fileStream,
        string fileName,
        string contentType)
    {
        // Validate content type
        if (!_allowedContentTypes.Contains(contentType))
        {
            throw new ValidationException($"Content type {contentType} is not allowed");
        }

        // Validate file size
        if (fileStream.Length > MaxFileSize)
        {
            throw new ValidationException($"File size exceeds maximum of {MaxFileSize / 1024 / 1024} MB");
        }

        // Scan for malware (placeholder for actual implementation)
        if (!await ScanForMalwareAsync(fileStream))
        {
            throw new SecurityException("File failed malware scan");
        }

        // Generate unique blob name
        var blobName = $"{Guid.NewGuid()}{Path.GetExtension(fileName)}";

        // Upload
        var blobUrl = await _blobService.UploadAsync(blobName, fileStream, contentType);

        _logger.LogInformation(
            "Uploaded document {FileName} as {BlobName}",
            fileName,
            blobName
        );

        return blobUrl;
    }

    private async Task<bool> ScanForMalwareAsync(Stream stream)
    {
        // Implement malware scanning logic
        // Could integrate with Azure Defender or third-party services
        await Task.Delay(100); // Simulate scan
        return true;
    }
}
```

### 2. Thumbnail Generation

```csharp
public class ThumbnailService
{
    private readonly BlobContainerClient _containerClient;
    private readonly ILogger<ThumbnailService> _logger;

    public async Task<string> GenerateThumbnailAsync(string sourceBlobName)
    {
        var sourceBlobClient = _containerClient.GetBlobClient(sourceBlobName);

        // Download original
        using var sourceStream = new MemoryStream();
        await sourceBlobClient.DownloadToAsync(sourceStream);
        sourceStream.Position = 0;

        // Generate thumbnail
        using var thumbnailStream = await CreateThumbnailAsync(sourceStream);

        // Upload thumbnail
        var thumbnailName = $"thumbnails/{Path.GetFileNameWithoutExtension(sourceBlobName)}-thumb.jpg";
        var thumbnailClient = _containerClient.GetBlobClient(thumbnailName);

        await thumbnailClient.UploadAsync(thumbnailStream, new BlobHttpHeaders
        {
            ContentType = "image/jpeg"
        });

        _logger.LogInformation(
            "Generated thumbnail {ThumbnailName} from {SourceBlob}",
            thumbnailName,
            sourceBlobName
        );

        return thumbnailClient.Uri.ToString();
    }

    private async Task<Stream> CreateThumbnailAsync(Stream sourceStream)
    {
        // Implement image resizing logic
        // Could use ImageSharp or similar library
        var thumbnailStream = new MemoryStream();

        // Example: resize to 200x200
        // image.Mutate(x => x.Resize(200, 200));
        // await image.SaveAsync(thumbnailStream, new JpegEncoder());

        thumbnailStream.Position = 0;
        return thumbnailStream;
    }
}
```

### 3. Blob Copying and Moving

```csharp
public class BlobCopyService
{
    private readonly BlobContainerClient _containerClient;
    private readonly ILogger<BlobCopyService> _logger;

    public async Task<string> CopyBlobAsync(string sourceBlobName, string destinationBlobName)
    {
        var sourceBlob = _containerClient.GetBlobClient(sourceBlobName);
        var destBlob = _containerClient.GetBlobClient(destinationBlobName);

        // Start copy operation
        var copyOperation = await destBlob.StartCopyFromUriAsync(sourceBlob.Uri);

        // Wait for copy to complete
        await copyOperation.WaitForCompletionAsync();

        _logger.LogInformation(
            "Copied {SourceBlob} to {DestBlob}",
            sourceBlobName,
            destinationBlobName
        );

        return destBlob.Uri.ToString();
    }

    public async Task MoveBlobAsync(string sourceBlobName, string destinationBlobName)
    {
        // Copy to new location
        await CopyBlobAsync(sourceBlobName, destinationBlobName);

        // Delete original
        var sourceBlob = _containerClient.GetBlobClient(sourceBlobName);
        await sourceBlob.DeleteIfExistsAsync();

        _logger.LogInformation(
            "Moved {SourceBlob} to {DestBlob}",
            sourceBlobName,
            destinationBlobName
        );
    }
}
```

---

## Security

### 1. Container Access Levels

```csharp
public async Task ConfigureContainerAccessAsync(PublicAccessType accessType)
{
    await _containerClient.SetAccessPolicyAsync(accessType);

    _logger.LogInformation("Set container access to {AccessType}", accessType);
}

// PublicAccessType.None - Private (recommended for documents)
// PublicAccessType.Blob - Blob-level read access
// PublicAccessType.Container - Container and blob read access
```

### 2. SAS Token Best Practices

```csharp
public string GenerateUserSasToken(
    string blobName,
    string userId,
    TimeSpan expiration)
{
    var blobClient = _containerClient.GetBlobClient(blobName);

    var sasBuilder = new BlobSasBuilder
    {
        BlobContainerName = _containerClient.Name,
        BlobName = blobName,
        Resource = "b",
        StartsOn = DateTimeOffset.UtcNow.AddMinutes(-5),
        ExpiresOn = DateTimeOffset.UtcNow.Add(expiration),
        Protocol = SasProtocol.Https, // Enforce HTTPS
        IPRange = new SasIPRange(IPAddress.Parse("0.0.0.0"), IPAddress.Parse("255.255.255.255"))
    };

    sasBuilder.SetPermissions(BlobSasPermissions.Read);

    // Generate SAS token
    var sasToken = blobClient.GenerateSasUri(sasBuilder);

    _logger.LogInformation(
        "Generated SAS token for user {UserId} to access {BlobName}",
        userId,
        blobName
    );

    return sasToken.ToString();
}
```

### 3. Encryption

```csharp
// Server-side encryption is enabled by default
// Client-side encryption example
public class EncryptedBlobService
{
    public async Task UploadEncryptedAsync(
        string blobName,
        Stream content,
        byte[] encryptionKey)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);

        var encryptionOptions = new BlobUploadOptions
        {
            EncryptionKey = encryptionKey,
            EncryptionAlgorithm = "AES256"
        };

        await blobClient.UploadAsync(content, encryptionOptions);
    }
}
```

---

## Performance Optimization

### 1. Parallel Downloads

```csharp
public async Task DownloadBlobsConcurrentlyAsync(List<string> blobNames)
{
    var downloadTasks = blobNames.Select(async blobName =>
    {
        var blobClient = _containerClient.GetBlobClient(blobName);
        var localPath = Path.Combine("downloads", blobName);

        await blobClient.DownloadToAsync(localPath);

        _logger.LogInformation("Downloaded {BlobName}", blobName);
    });

    await Task.WhenAll(downloadTasks);
}
```

### 2. Blob Indexing for Search

```csharp
public class BlobIndexService
{
    public async Task SetBlobTagsAsync(string blobName, Dictionary<string, string> tags)
    {
        var blobClient = _containerClient.GetBlobClient(blobName);

        await blobClient.SetTagsAsync(tags);

        _logger.LogInformation("Set tags for {BlobName}", blobName);
    }

    public async Task<List<BlobItem>> FindBlobsByTagAsync(string tagKey, string tagValue)
    {
        var query = $"\"{tagKey}\" = '{tagValue}'";

        var results = new List<BlobItem>();

        await foreach (var blobItem in _containerClient.GetBlobsAsync(
            traits: BlobTraits.Tags))
        {
            if (blobItem.Tags != null &&
                blobItem.Tags.TryGetValue(tagKey, out var value) &&
                value == tagValue)
            {
                results.Add(blobItem);
            }
        }

        return results;
    }
}
```

---

## Testing

### Unit Test Example (xUnit with Azurite Emulator)

```csharp
public class BlobStorageServiceTests : IAsyncLifetime
{
    private BlobServiceClient _serviceClient = null!;
    private BlobContainerClient _containerClient = null!;
    private BlobStorageService _sut = null!;

    public async Task InitializeAsync()
    {
        // Use Azurite emulator connection string
        var connectionString = "UseDevelopmentStorage=true";

        _serviceClient = new BlobServiceClient(connectionString);
        _containerClient = _serviceClient.GetBlobContainerClient("test-container");

        await _containerClient.CreateIfNotExistsAsync();

        _sut = new BlobStorageService(
            _serviceClient,
            Mock.Of<IConfiguration>(),
            Mock.Of<ILogger<BlobStorageService>>()
        );
    }

    [Fact]
    public async Task UploadAsync_UploadsBlob()
    {
        // Arrange
        var blobName = "test.txt";
        var content = "Hello, world!";
        using var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));

        // Act
        var blobUrl = await _sut.UploadAsync(blobName, stream, "text/plain");

        // Assert
        Assert.NotNull(blobUrl);

        var blobClient = _containerClient.GetBlobClient(blobName);
        var exists = await blobClient.ExistsAsync();
        Assert.True(exists);
    }

    public async Task DisposeAsync()
    {
        await _containerClient.DeleteIfExistsAsync();
    }
}
```

---

## Common Pitfalls

### 1. Not Handling Large Files

**Problem**: Loading entire file in memory

**Solution**: Use streaming uploads/downloads

### 2. Forgetting to Dispose Streams

**Do**:
```csharp
await using var stream = await blobClient.OpenReadAsync();
```

### 3. Not Using SAS Tokens

**Problem**: Exposing account keys

**Solution**: Use SAS tokens for client access

---

## Documentation & Resources

### Official Documentation
- **Main Docs**: https://learn.microsoft.com/azure/storage/blobs
- **SDK Reference**: https://learn.microsoft.com/dotnet/api/azure.storage.blobs
- **Best Practices**: https://learn.microsoft.com/azure/storage/blobs/storage-performance-checklist

### Tools
- **Azure Storage Explorer**: https://azure.microsoft.com/features/storage-explorer/
- **Azurite Emulator**: https://learn.microsoft.com/azure/storage/common/storage-use-azurite

---

## Quick Reference

### CLI Commands

```bash
# Upload blob
az storage blob upload \
  --account-name mystorageaccount \
  --container-name documents \
  --name test.pdf \
  --file ./test.pdf

# Download blob
az storage blob download \
  --account-name mystorageaccount \
  --container-name documents \
  --name test.pdf \
  --file ./downloaded.pdf

# Generate SAS token
az storage blob generate-sas \
  --account-name mystorageaccount \
  --container-name documents \
  --name test.pdf \
  --permissions r \
  --expiry 2025-12-31
```

---

**For this project**: Use Azure Blob Storage for all document file storage. Store metadata in Cosmos DB, files in Blob Storage. Use SAS tokens for secure downloads. Implement lifecycle policies for cost optimization. Enable soft delete for data protection.

**Last Updated**: 2025-09-30
