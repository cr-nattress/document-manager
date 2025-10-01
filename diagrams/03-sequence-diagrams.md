# Sequence Diagrams

**Purpose:** Shows time-based interactions for key workflows

**Last Updated:** 2025-09-30

**Version:** 1.0.0

## 1. Document Upload Workflow

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Blob as Blob Storage
    participant Cosmos as Cosmos DB
    participant Cache as Redis Cache

    User->>Frontend: Select file & folder
    User->>Frontend: Click Upload
    Frontend->>Frontend: Validate file (size, type)

    alt Validation fails
        Frontend-->>User: Show error message
    else Validation passes
        Frontend->>API: POST /api/documents<br/>(multipart/form-data)

        Note over API: Generate doc-{guid}

        API->>Blob: Upload file
        Blob-->>API: Return blob URL

        API->>Cosmos: Create document metadata
        Cosmos-->>API: Confirm created

        API->>Cosmos: Update folder.documentCount++
        Cosmos-->>API: Confirm updated

        API->>Cache: Invalidate folder:contents:{folderId}
        Cache-->>API: Cache cleared

        API->>Cache: Invalidate folder:tree:root
        Cache-->>API: Cache cleared

        API-->>Frontend: 201 Created (document metadata)
        Frontend->>Frontend: Update document list
        Frontend-->>User: Show success message
    end
```

## 2. Document Download Workflow

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cache as Redis Cache
    participant Cosmos as Cosmos DB
    participant Blob as Blob Storage

    User->>Frontend: Click download icon
    Frontend->>API: GET /api/documents/{id}/download

    API->>Cache: Get document:{id}

    alt Document in cache
        Cache-->>API: Return metadata
    else Not in cache
        API->>Cosmos: Query document by id
        Cosmos-->>API: Return metadata
        API->>Cache: Store document:{id} (TTL 600s)
    end

    Note over API: Generate SAS token<br/>(60 second expiry)

    API-->>Frontend: 200 OK (blob URL + SAS)
    Frontend->>Blob: Download from blob URL
    Blob-->>Frontend: File stream
    Frontend-->>User: Browser downloads file

    Note over User: File saved to device
```

## 3. Folder Tree Navigation

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cache as Redis Cache
    participant Cosmos as Cosmos DB

    User->>Frontend: Open application
    Frontend->>API: GET /api/folders/tree

    API->>Cache: Get folder:tree:root

    alt Tree in cache
        Cache-->>API: Return cached tree
        Note over API: Cache hit (fast)
    else Tree not in cache
        API->>Cosmos: Query all folders
        Cosmos-->>API: Return all folders
        Note over API: Build tree structure
        API->>Cache: Store folder:tree:root (TTL 300s)
        Note over API: Cache miss (slower)
    end

    API-->>Frontend: 200 OK (tree structure)
    Frontend->>Frontend: Render FolderTree component
    Frontend-->>User: Display folder tree

    User->>Frontend: Click to expand folder
    Frontend->>Frontend: Check if children loaded

    alt Children already loaded
        Frontend->>Frontend: Toggle expand state
        Frontend-->>User: Show subfolders
    else Children not loaded
        Frontend->>API: GET /api/folders/{id}/contents
        API->>Cache: Get folder:contents:{id}

        alt Contents in cache
            Cache-->>API: Return cached contents
        else Not in cache
            API->>Cosmos: Query folders where parentId = {id}
            API->>Cosmos: Query documents where folderId = {id}
            Cosmos-->>API: Return contents
            API->>Cache: Store folder:contents:{id} (TTL 180s)
        end

        API-->>Frontend: 200 OK (folders + documents)
        Frontend->>Frontend: Update tree state
        Frontend-->>User: Show subfolders & documents
    end
```

## 4. Search Documents Workflow

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cache as Redis Cache
    participant Cosmos as Cosmos DB

    User->>Frontend: Enter search term
    User->>Frontend: Select filters (tags, folder)
    User->>Frontend: Click Search

    Frontend->>Frontend: Debounce input (300ms)
    Frontend->>API: GET /api/search?q=term&tags=finance&folderId=xyz

    Note over API: Generate query hash

    API->>Cache: Get search:{query-hash}

    alt Results in cache
        Cache-->>API: Return cached results
        Note over API: Cache hit (fast <50ms)
    else Not in cache
        Note over API: Build Cosmos DB query

        alt Search in specific folder
            API->>Cosmos: Query documents<br/>WHERE folderId = xyz<br/>AND name CONTAINS term
        else Global search
            API->>Cosmos: Query documents<br/>WHERE name CONTAINS term
        end

        alt Filter by tags
            Note over API: Add tag filter to query
        end

        Cosmos-->>API: Return matching documents

        Note over API: Rank by relevance

        API->>Cache: Store search:{query-hash}<br/>(TTL 120s)
        Note over API: Cache miss (slower 200-500ms)
    end

    API-->>Frontend: 200 OK (search results)
    Frontend->>Frontend: Update DocumentList component
    Frontend-->>User: Display results (with relevance score)

    User->>Frontend: Click on document
    Frontend->>Frontend: Show document details panel
    Frontend-->>User: Display metadata, tags, actions
```

## 5. Move Document Between Folders

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cosmos as Cosmos DB
    participant Cache as Redis Cache

    User->>Frontend: Select document
    User->>Frontend: Click Move action
    Frontend->>Frontend: Show folder selection dialog

    User->>Frontend: Select target folder
    User->>Frontend: Confirm move

    Frontend->>API: PATCH /api/documents/{id}/move<br/>{targetFolderId: "folder-xyz"}

    Note over API: Validate target folder exists

    API->>Cosmos: Get target folder

    alt Target folder not found
        Cosmos-->>API: Not found
        API-->>Frontend: 404 Not Found
        Frontend-->>User: Show error message
    else Target folder exists
        Cosmos-->>API: Return folder

        Note over API: Get current document

        API->>Cosmos: Get document by id
        Cosmos-->>API: Return document

        Note over API: Calculate new folderPath

        API->>Cosmos: Begin transaction

        API->>Cosmos: Update document<br/>SET folderId = target<br/>SET folderPath = newPath

        API->>Cosmos: Update old folder<br/>SET documentCount--

        API->>Cosmos: Update target folder<br/>SET documentCount++

        API->>Cosmos: Commit transaction
        Cosmos-->>API: Success

        Note over API: Invalidate caches

        API->>Cache: DELETE folder:contents:{oldFolderId}
        API->>Cache: DELETE folder:contents:{targetFolderId}
        API->>Cache: DELETE folder:tree:root
        API->>Cache: DELETE document:{id}

        API-->>Frontend: 200 OK (updated document)
        Frontend->>Frontend: Remove from old location
        Frontend->>Frontend: Add to new location
        Frontend-->>User: Show success message
    end
```

## 6. Create Folder Workflow

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cosmos as Cosmos DB
    participant Cache as Redis Cache

    User->>Frontend: Click New Folder
    Frontend->>Frontend: Show folder creation dialog

    User->>Frontend: Select parent folder
    User->>Frontend: Enter folder name
    User->>Frontend: Enter description (optional)
    User->>Frontend: Click Create

    Frontend->>Frontend: Validate input

    alt Validation fails
        Frontend-->>User: Show validation errors
    else Validation passes
        Frontend->>API: POST /api/folders<br/>{name, parentId, description}

        Note over API: Generate folder-{guid}

        API->>Cosmos: Get parent folder

        alt Parent not found
            Cosmos-->>API: Not found
            API-->>Frontend: 404 Not Found
            Frontend-->>User: Show error message
        else Parent exists
            Cosmos-->>API: Return parent

            Note over API: Validate folder depth<br/>(max 10 levels)

            alt Depth exceeds limit
                API-->>Frontend: 400 Bad Request<br/>(Max depth exceeded)
                Frontend-->>User: Show error message
            else Depth OK
                Note over API: Check name uniqueness<br/>in parent

                API->>Cosmos: Query folders<br/>WHERE parentId = parent<br/>AND name = newName

                alt Name already exists
                    Cosmos-->>API: Folder found
                    API-->>Frontend: 409 Conflict<br/>(Folder name exists)
                    Frontend-->>User: Show error message
                else Name is unique
                    Cosmos-->>API: No conflict

                    Note over API: Calculate path and level
                    Note over API: path = parent.path + "/" + name
                    Note over API: level = parent.level + 1

                    API->>Cosmos: Create folder document
                    Cosmos-->>API: Folder created

                    API->>Cosmos: Update parent.subfolderCount++
                    Cosmos-->>API: Parent updated

                    API->>Cache: DELETE folder:tree:root
                    API->>Cache: DELETE folder:contents:{parentId}

                    API-->>Frontend: 201 Created (folder)
                    Frontend->>Frontend: Add to folder tree
                    Frontend-->>User: Show success message
                end
            end
        end
    end
```

## 7. Edit Document Metadata

```mermaid
sequenceDiagram
    actor User
    participant Frontend as Vue 3 Frontend
    participant API as Azure Functions
    participant Cosmos as Cosmos DB
    participant Cache as Redis Cache

    User->>Frontend: Click Edit on document
    Frontend->>API: GET /api/documents/{id}

    API->>Cache: Get document:{id}

    alt Document in cache
        Cache-->>API: Return metadata
    else Not in cache
        API->>Cosmos: Query document
        Cosmos-->>API: Return metadata
        API->>Cache: Store document:{id}
    end

    API-->>Frontend: 200 OK (document metadata)
    Frontend->>Frontend: Show metadata editor dialog
    Frontend-->>User: Display current metadata

    User->>Frontend: Update name
    User->>Frontend: Edit metadata fields
    User->>Frontend: Add/remove tags
    User->>Frontend: Click Save

    Frontend->>Frontend: Validate changes

    Frontend->>API: PUT /api/documents/{id}<br/>{name, metadata, tags}

    Note over API: Validate input

    alt Validation fails
        API-->>Frontend: 400 Bad Request
        Frontend-->>User: Show validation errors
    else Validation OK
        API->>Cosmos: Get current document
        Cosmos-->>API: Return document

        Note over API: Calculate tag changes
        Note over API: addedTags = new - old
        Note over API: removedTags = old - new

        API->>Cosmos: Update document<br/>SET name, metadata, tags<br/>SET modifiedAt = now
        Cosmos-->>API: Document updated

        loop For each added tag
            API->>Cosmos: Get or create tag
            API->>Cosmos: Increment tag.usageCount
            API->>Cosmos: Update tag.lastUsedAt
        end

        loop For each removed tag
            API->>Cosmos: Get tag
            API->>Cosmos: Decrement tag.usageCount
        end

        API->>Cache: DELETE document:{id}
        API->>Cache: DELETE folder:contents:{folderId}
        API->>Cache: Invalidate search results

        API-->>Frontend: 200 OK (updated document)
        Frontend->>Frontend: Update document in list
        Frontend-->>User: Show success message
    end
```

## Key Observations

### Performance Optimizations
- Redis cache used for frequently accessed data (folder trees, search results)
- Cache-aside pattern with configurable TTL
- SAS tokens generated on-demand for secure blob access
- Debouncing on search input to reduce API calls

### Error Handling
- Validation at both frontend and backend
- Proper HTTP status codes (400, 404, 409, 500)
- User-friendly error messages
- Retry logic for transient failures (not shown)

### Consistency
- Transactional updates for multi-document changes
- Denormalized counts updated atomically
- Cache invalidation on data changes
- Optimistic concurrency using ETags (not shown)

### Security
- API authentication at gateway (not shown in diagrams)
- Time-limited SAS tokens for blob access
- Input validation on all endpoints
- HTTPS for all communications

## Notes

- All sequences assume successful authentication
- Monitoring and telemetry calls omitted for clarity
- Retry logic and circuit breakers not shown
- Frontend optimistic updates can be added for better UX
