# State Diagrams

**Purpose:** Shows object lifecycle and state transitions

**Last Updated:** 2025-09-30

**Version:** 1.0.0

## Document Lifecycle State Diagram

```mermaid
stateDiagram-v2
    [*] --> Uploading: User selects file

    Uploading --> Validating: File selected
    Validating --> UploadFailed: Validation failed
    Validating --> Transferring: Validation passed

    Transferring --> TransferFailed: Network error
    Transferring --> Processing: Upload complete

    Processing --> Stored: Metadata saved
    Stored --> Active: Ready for use

    Active --> Downloading: User downloads
    Downloading --> Active: Download complete

    Active --> Editing: User edits metadata
    Editing --> Active: Save successful
    Editing --> EditFailed: Save failed
    EditFailed --> Active: Retry

    Active --> Moving: User moves to folder
    Moving --> MoveFailed: Move failed
    Moving --> Active: Move successful
    MoveFailed --> Active: Retry

    Active --> Deleting: User deletes
    Deleting --> Deleted: Soft delete
    Deleted --> [*]: Permanent delete (30 days)

    UploadFailed --> [*]: User cancels
    TransferFailed --> Uploading: User retries

    note right of Uploading
        Client-side state
        Progress tracking
    end note

    note right of Validating
        Check:
        - File size < 5GB
        - Valid content type
        - Metadata format
    end note

    note right of Processing
        Server-side processing:
        1. Upload to Blob Storage
        2. Create Cosmos DB record
        3. Update folder counts
        4. Invalidate caches
    end note

    note right of Active
        Document is available:
        - Can be viewed
        - Can be downloaded
        - Can be edited
        - Can be moved
        - Can be deleted
    end note

    note right of Deleted
        Soft delete state:
        - Blob soft-deleted (30 days)
        - Metadata marked deleted
        - Can be recovered
    end note
```

## Folder State Diagram

```mermaid
stateDiagram-v2
    [*] --> Creating: User clicks New Folder

    Creating --> Validating: Name entered
    Validating --> CreateFailed: Validation failed
    Validating --> Saving: Validation passed

    CreateFailed --> Creating: User corrects

    Saving --> Empty: Folder created
    Empty --> Active: Folder ready

    Active --> ContainsDocuments: Document added
    ContainsDocuments --> Active: Document removed

    Active --> ContainsFolders: Subfolder created
    ContainsFolders --> Active: Subfolder removed

    ContainsDocuments --> ContainsBoth: Subfolder added
    ContainsFolders --> ContainsBoth: Document added
    ContainsBoth --> ContainsDocuments: All subfolders removed
    ContainsBoth --> ContainsFolders: All documents removed

    Active --> Editing: User edits folder
    ContainsDocuments --> Editing: User edits folder
    ContainsFolders --> Editing: User edits folder
    ContainsBoth --> Editing: User edits folder

    Editing --> EditFailed: Save failed
    EditFailed --> Active: Retry/Cancel

    Editing --> Active: Save successful (no contents)
    Editing --> ContainsDocuments: Save successful (has docs)
    Editing --> ContainsFolders: Save successful (has folders)
    Editing --> ContainsBoth: Save successful (has both)

    Active --> Moving: User moves folder
    ContainsDocuments --> Moving: User moves folder
    ContainsFolders --> Moving: User moves folder
    ContainsBoth --> Moving: User moves folder

    Moving --> MoveFailed: Move failed
    MoveFailed --> Active: Retry/Cancel
    MoveFailed --> ContainsDocuments: Retry/Cancel
    MoveFailed --> ContainsFolders: Retry/Cancel
    MoveFailed --> ContainsBoth: Retry/Cancel

    Moving --> Active: Move successful (empty)
    Moving --> ContainsDocuments: Move successful (has docs)
    Moving --> ContainsFolders: Move successful (has folders)
    Moving --> ContainsBoth: Move successful (has both)

    Active --> Deleting: User deletes empty folder
    Deleting --> Deleted: Delete confirmed
    Deleted --> [*]

    ContainsDocuments --> DeletingWithContents: User force deletes
    ContainsFolders --> DeletingWithContents: User force deletes
    ContainsBoth --> DeletingWithContents: User force deletes

    DeletingWithContents --> DeleteFailed: Delete failed
    DeleteFailed --> ContainsDocuments: Retry/Cancel
    DeleteFailed --> ContainsFolders: Retry/Cancel
    DeleteFailed --> ContainsBoth: Retry/Cancel

    DeletingWithContents --> Deleted: Cascade delete complete

    note right of Validating
        Validation checks:
        - Name not empty
        - Name unique in parent
        - Parent exists
        - Depth <= 10 levels
    end note

    note right of Active
        Empty folder:
        - documentCount = 0
        - subfolderCount = 0
        Can be deleted directly
    end note

    note right of ContainsBoth
        Folder with contents:
        - Has documents AND subfolders
        Requires force flag to delete
    end note

    note right of DeletingWithContents
        Cascade delete:
        1. Delete all documents
        2. Delete all subfolders (recursive)
        3. Update parent counts
        4. Invalidate caches
    end note
```

## Search Request State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle: Page loaded

    Idle --> Typing: User types query
    Typing --> Debouncing: Input changed
    Debouncing --> Typing: More input
    Debouncing --> Validating: 300ms elapsed

    Validating --> ValidationFailed: Query too short
    ValidationFailed --> Idle: Show error
    Validating --> Searching: Query valid

    Searching --> CheckingCache: API called
    CheckingCache --> CacheHit: Results in cache
    CheckingCache --> CacheMiss: Not in cache

    CacheHit --> DisplayingResults: Fast path (<50ms)
    CacheMiss --> QueryingDatabase: Slow path
    QueryingDatabase --> RankingResults: Query complete
    RankingResults --> CachingResults: Ranking done
    CachingResults --> DisplayingResults: Results cached

    DisplayingResults --> ResultsDisplayed: UI updated

    ResultsDisplayed --> Idle: User clears search
    ResultsDisplayed --> ApplyingFilters: User adds filter
    ApplyingFilters --> Searching: Filter applied

    ResultsDisplayed --> SelectingDocument: User clicks result
    SelectingDocument --> DocumentSelected: Navigate to doc
    DocumentSelected --> ResultsDisplayed: User returns

    Searching --> SearchFailed: Network error
    QueryingDatabase --> SearchFailed: Database error
    SearchFailed --> Idle: Show error

    note right of Debouncing
        300ms delay to prevent
        excessive API calls
        while user is typing
    end note

    note right of CheckingCache
        Cache key format:
        search:{hash-of-query}
        TTL: 120 seconds
    end note

    note right of CacheHit
        Fast response:
        - No database query
        - Sub-50ms response
        - Cached results
    end note

    note right of CacheMiss
        Slower response:
        - Query Cosmos DB
        - Rank by relevance
        - Cache for next request
        - 200-500ms response
    end note
```

## File Upload Progress State Diagram

```mermaid
stateDiagram-v2
    [*] --> NotStarted: Component mounted

    NotStarted --> FileSelected: User selects file
    FileSelected --> ValidatingSize: Check file size
    ValidatingSize --> SizeTooLarge: Size > 5GB
    SizeTooLarge --> NotStarted: Show error

    ValidatingSize --> ValidatingType: Size OK
    ValidatingType --> InvalidType: Type not allowed
    InvalidType --> NotStarted: Show error

    ValidatingType --> ReadyToUpload: Type OK

    ReadyToUpload --> MetadataEntry: User enters metadata
    MetadataEntry --> ReadyToUpload: Metadata added

    ReadyToUpload --> Uploading: User clicks Upload

    Uploading --> Progress0: Starting upload
    Progress0 --> Progress25: 25% uploaded
    Progress25 --> Progress50: 50% uploaded
    Progress50 --> Progress75: 75% uploaded
    Progress75 --> Progress100: 100% uploaded

    Progress100 --> ProcessingServer: Upload complete

    ProcessingServer --> Finalizing: Server processing
    Finalizing --> UploadComplete: Success

    UploadComplete --> NotStarted: Reset form

    Uploading --> UploadPaused: Connection slow
    Progress25 --> UploadPaused: Connection slow
    Progress50 --> UploadPaused: Connection slow
    Progress75 --> UploadPaused: Connection slow

    UploadPaused --> Uploading: Connection restored

    Uploading --> UploadFailed: Error occurred
    Progress25 --> UploadFailed: Error occurred
    Progress50 --> UploadFailed: Error occurred
    Progress75 --> UploadFailed: Error occurred
    Progress100 --> UploadFailed: Error occurred
    ProcessingServer --> UploadFailed: Server error

    UploadFailed --> Retrying: Auto-retry (attempt 1-3)
    Retrying --> Uploading: Retry upload
    Retrying --> UploadAbandoned: Max retries reached

    UploadAbandoned --> NotStarted: User acknowledged

    note right of Uploading
        UI shows:
        - Progress bar
        - Percentage
        - Upload speed
        - Time remaining
    end note

    note right of ProcessingServer
        Backend processing:
        1. Save to Blob Storage
        2. Create metadata record
        3. Update folder counts
        4. Invalidate caches
    end note

    note right of UploadFailed
        Retry strategy:
        - Exponential backoff
        - Max 3 attempts
        - Show error details
    end note
```

## Cache Entry State Diagram

```mermaid
stateDiagram-v2
    [*] --> NotCached: Data not in cache

    NotCached --> Fetching: Request for data
    Fetching --> Storing: Data retrieved
    Storing --> Cached: Stored with TTL

    Cached --> Accessed: Cache hit
    Accessed --> Cached: Data returned

    Cached --> Expired: TTL elapsed
    Expired --> NotCached: Entry removed

    Cached --> Invalidated: Data changed
    Invalidated --> NotCached: Entry deleted

    Cached --> Evicted: Memory pressure
    Evicted --> NotCached: LRU eviction

    note right of Storing
        Cache keys by type:
        - document:{id} - TTL 600s
        - folder:tree:root - TTL 300s
        - folder:contents:{id} - TTL 180s
        - search:{hash} - TTL 120s
    end note

    note right of Accessed
        Cache hit benefits:
        - Fast response (<10ms)
        - Reduced DB load
        - Better user experience
    end note

    note right of Invalidated
        Invalidation triggers:
        - Document created/updated/deleted
        - Folder created/updated/deleted/moved
        - Tag usage count changed
    end note

    note right of Evicted
        Redis eviction policy:
        - allkeys-lru
        - Evict least recently used
        - When memory limit reached
    end note
```

## API Request State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle: Frontend ready

    Idle --> Authenticating: API call initiated
    Authenticating --> AuthFailed: Invalid API key
    AuthFailed --> [*]: Return 401

    Authenticating --> RateLimiting: Auth successful
    RateLimiting --> RateLimited: Quota exceeded
    RateLimited --> [*]: Return 429

    RateLimiting --> Routing: Within quota
    Routing --> ExecutingFunction: Route to handler

    ExecutingFunction --> ValidatingInput: Parse request
    ValidatingInput --> ValidationError: Invalid input
    ValidationError --> [*]: Return 400

    ValidatingInput --> ProcessingRequest: Input valid
    ProcessingRequest --> BusinessLogicError: Business rule violated
    BusinessLogicError --> [*]: Return 409

    ProcessingRequest --> AccessingDatabase: Business logic OK
    AccessingDatabase --> DatabaseError: DB error
    DatabaseError --> [*]: Return 500

    AccessingDatabase --> BuildingResponse: Data retrieved
    BuildingResponse --> ReturningSuccess: Response ready
    ReturningSuccess --> [*]: Return 200/201

    ProcessingRequest --> NetworkTimeout: Timeout (>30s)
    NetworkTimeout --> [*]: Return 504

    note right of Authenticating
        Check API key:
        - X-API-Key header
        - Authorization: Bearer token
    end note

    note right of ProcessingRequest
        Business logic:
        1. Check cache
        2. Query database if needed
        3. Process data
        4. Update cache
        5. Return response
    end note

    note right of BuildingResponse
        Response includes:
        - Status code
        - Data payload
        - Error details (if any)
        - Request ID for tracking
    end note
```

## Key State Management Observations

### Document Lifecycle
- Documents go through validation before upload
- Active state is the primary operational state
- Soft delete with 30-day recovery period
- Failed operations allow retry without data loss

### Folder Management
- Folders track content state (empty, has docs, has folders, has both)
- Cascade delete requires force flag for safety
- Moving folders updates all descendant paths
- Empty folders can be deleted immediately

### Search Request Flow
- Debouncing prevents excessive API calls
- Cache-first strategy for performance
- Results ranked by relevance before display
- Filters trigger new search requests

### Upload Progress
- Multi-stage validation before upload
- Progress tracking at 25% intervals
- Automatic retry with exponential backoff
- Server processing after upload complete

### Cache Management
- Time-based expiration (TTL)
- Explicit invalidation on data changes
- LRU eviction under memory pressure
- Different TTLs based on data volatility

### API Request Processing
- Multi-stage security checks (auth, rate limiting)
- Input validation before processing
- Comprehensive error handling with appropriate status codes
- Timeout protection (30s maximum)

## Notes

- All state transitions logged for debugging
- Failed states include retry mechanisms where appropriate
- User-facing states provide clear feedback
- Backend states optimize for performance and consistency
- Cache states balance freshness vs. performance
