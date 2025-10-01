# Component Diagram

**Purpose:** Shows the module organization and dependencies for frontend and backend

**Last Updated:** 2025-09-30

**Version:** 1.0.0

## Frontend Component Architecture

```mermaid
graph TB
    subgraph "Vue 3 Frontend Application"
        subgraph "Entry Point"
            MAIN[main.ts<br/>App Bootstrap]
            ROUTER[Vue Router<br/>Route Configuration]
        end

        subgraph "Views (Pages)"
            HOME[HomeView.vue<br/>Dashboard]
            BROWSE[BrowseView.vue<br/>Document Browser]
            SEARCH[SearchView.vue<br/>Search Results]
        end

        subgraph "Components - Documents"
            DOCLIST[DocumentList.vue<br/>List of documents]
            DOCCARD[DocumentCard.vue<br/>Single document display]
            DOCUPLOAD[DocumentUpload.vue<br/>File upload form]
            METAEDITOR[MetadataEditor.vue<br/>Edit metadata/tags]
        end

        subgraph "Components - Folders"
            FOLDERTREE[FolderTree.vue<br/>Recursive tree component]
            FOLDERNODE[FolderNode.vue<br/>Single tree node]
            FOLDERDIALOG[FolderDialog.vue<br/>Create/edit folder]
        end

        subgraph "Components - Search"
            SEARCHBAR[SearchBar.vue<br/>Search input + filters]
            TAGFILTER[TagFilter.vue<br/>Tag selection]
            SEARCHRESULTS[SearchResults.vue<br/>Results display]
        end

        subgraph "Components - Common"
            LAYOUT[AppLayout.vue<br/>Main layout]
            HEADER[AppHeader.vue<br/>Top navigation]
            SIDEBAR[AppSidebar.vue<br/>Side navigation]
            LOADING[LoadingSpinner.vue]
            ERROR[ErrorMessage.vue]
        end

        subgraph "State Management - Pinia"
            DOCSTORE[documentStore.ts<br/>Document state]
            FOLDSTORE[folderStore.ts<br/>Folder state]
            SEARCHSTORE[searchStore.ts<br/>Search state]
            UISTORE[uiStore.ts<br/>UI state]
        end

        subgraph "API Services"
            APICLIENT[apiClient.ts<br/>Axios config]
            DOCSERVICE[documentService.ts<br/>Document API calls]
            FOLDSERVICE[folderService.ts<br/>Folder API calls]
            SEARCHSERVICE[searchService.ts<br/>Search API calls]
        end

        subgraph "Composables (Hooks)"
            USEUPLOAD[useFileUpload.ts<br/>Upload logic]
            USETREE[useFolderTree.ts<br/>Tree navigation]
            USESEARCH[useSearch.ts<br/>Search logic]
        end

        subgraph "Types & Interfaces"
            TYPES[types/index.ts<br/>TypeScript interfaces]
        end

        subgraph "Utilities"
            UTILS[utils/<br/>Helper functions]
            VALIDATORS[validators.ts<br/>Input validation]
            FORMATTERS[formatters.ts<br/>Data formatting]
        end
    end

    MAIN --> ROUTER
    MAIN --> LAYOUT
    ROUTER --> HOME
    ROUTER --> BROWSE
    ROUTER --> SEARCH

    HOME --> DOCLIST
    HOME --> FOLDERTREE
    BROWSE --> FOLDERTREE
    BROWSE --> DOCLIST
    BROWSE --> DOCUPLOAD
    SEARCH --> SEARCHBAR
    SEARCH --> SEARCHRESULTS

    DOCLIST --> DOCCARD
    DOCCARD --> METAEDITOR
    DOCUPLOAD --> USEUPLOAD
    FOLDERTREE --> FOLDERNODE
    FOLDERNODE --> FOLDERDIALOG
    SEARCHBAR --> TAGFILTER

    LAYOUT --> HEADER
    LAYOUT --> SIDEBAR
    SIDEBAR --> FOLDERTREE

    DOCLIST --> DOCSTORE
    DOCCARD --> DOCSTORE
    DOCUPLOAD --> DOCSTORE
    METAEDITOR --> DOCSTORE

    FOLDERTREE --> FOLDSTORE
    FOLDERNODE --> FOLDSTORE
    FOLDERDIALOG --> FOLDSTORE

    SEARCHBAR --> SEARCHSTORE
    SEARCHRESULTS --> SEARCHSTORE

    DOCSTORE --> DOCSERVICE
    FOLDSTORE --> FOLDSERVICE
    SEARCHSTORE --> SEARCHSERVICE

    DOCSERVICE --> APICLIENT
    FOLDSERVICE --> APICLIENT
    SEARCHSERVICE --> APICLIENT

    USEUPLOAD --> DOCSERVICE
    USETREE --> FOLDSERVICE
    USESEARCH --> SEARCHSERVICE

    DOCSTORE --> TYPES
    FOLDSTORE --> TYPES
    SEARCHSTORE --> TYPES
    DOCSERVICE --> TYPES
    FOLDSERVICE --> TYPES

    DOCSTORE --> UTILS
    FOLDSTORE --> UTILS
    DOCSERVICE --> VALIDATORS
    FOLDSERVICE --> VALIDATORS
    FORMATTERS --> DOCCARD

    classDef entryStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef viewStyle fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef componentStyle fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    classDef storeStyle fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef serviceStyle fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef utilStyle fill:#e0f2f1,stroke:#00796b,stroke-width:2px

    class MAIN,ROUTER entryStyle
    class HOME,BROWSE,SEARCH viewStyle
    class DOCLIST,DOCCARD,DOCUPLOAD,METAEDITOR,FOLDERTREE,FOLDERNODE,FOLDERDIALOG,SEARCHBAR,TAGFILTER,SEARCHRESULTS,LAYOUT,HEADER,SIDEBAR,LOADING,ERROR componentStyle
    class DOCSTORE,FOLDSTORE,SEARCHSTORE,UISTORE storeStyle
    class APICLIENT,DOCSERVICE,FOLDSERVICE,SEARCHSERVICE serviceStyle
    class USEUPLOAD,USETREE,USESEARCH,TYPES,UTILS,VALIDATORS,FORMATTERS utilStyle
```

## Backend Component Architecture

```mermaid
graph TB
    subgraph "Azure Functions Backend (.NET 8)"
        subgraph "HTTP Triggered Functions"
            DOCFN[DocumentFunctions.cs<br/>7 endpoints]
            FOLDFN[FolderFunctions.cs<br/>7 endpoints]
            SEARCHFN[SearchFunctions.cs<br/>1 endpoint]
        end

        subgraph "Services - Interfaces"
            ICOSMOSDB[ICosmosDbService.cs<br/>Database operations]
            IBLOBSTORAGE[IBlobStorageService.cs<br/>File operations]
            ICACHE[ICacheService.cs<br/>Cache operations]
        end

        subgraph "Services - Implementations"
            COSMOSDB[CosmosDbService.cs<br/>Cosmos DB logic]
            BLOBSTORAGE[BlobStorageService.cs<br/>Blob Storage logic]
            CACHE[CacheService.cs<br/>Redis logic]
        end

        subgraph "Models (Entities)"
            DOCMODEL[Document.cs<br/>Document entity]
            FOLDMODEL[Folder.cs<br/>Folder entity]
            TAGMODEL[Tag.cs<br/>Tag entity]
        end

        subgraph "DTOs (Data Transfer Objects)"
            DOCDTO[DocumentDto.cs<br/>API request/response]
            FOLDDTO[FolderDto.cs<br/>API request/response]
            SEARCHDTO[SearchDto.cs<br/>Search parameters]
        end

        subgraph "Validators"
            DOCVAL[DocumentValidator.cs<br/>Document validation]
            FOLDVAL[FolderValidator.cs<br/>Folder validation]
        end

        subgraph "Middleware"
            AUTH[AuthMiddleware.cs<br/>API key validation]
            LOGGING[LoggingMiddleware.cs<br/>Request logging]
            ERRORHANDLER[ErrorHandler.cs<br/>Exception handling]
        end

        subgraph "Utilities"
            MAPPER[AutoMapper<br/>Entity <-> DTO]
            HELPERS[Helpers.cs<br/>Common utilities]
            CONSTANTS[Constants.cs<br/>Application constants]
        end

        subgraph "Configuration"
            PROGRAM[Program.cs<br/>DI Container setup]
            SETTINGS[appsettings.json<br/>Configuration]
        end

        subgraph "Azure SDK Integration"
            COSMOSSDK[Azure.Cosmos SDK]
            BLOBSDK[Azure.Storage.Blobs SDK]
            REDISSDK[StackExchange.Redis]
            KVAULTSDK[Azure.KeyVault SDK]
        end
    end

    PROGRAM --> SETTINGS
    PROGRAM --> AUTH
    PROGRAM --> LOGGING
    PROGRAM --> ERRORHANDLER
    PROGRAM --> MAPPER

    PROGRAM -.->|Register Services| ICOSMOSDB
    PROGRAM -.->|Register Services| IBLOBSTORAGE
    PROGRAM -.->|Register Services| ICACHE

    ICOSMOSDB -.->|Implement| COSMOSDB
    IBLOBSTORAGE -.->|Implement| BLOBSTORAGE
    ICACHE -.->|Implement| CACHE

    DOCFN --> AUTH
    FOLDFN --> AUTH
    SEARCHFN --> AUTH

    DOCFN --> DOCVAL
    FOLDFN --> FOLDVAL

    DOCFN --> ICOSMOSDB
    DOCFN --> IBLOBSTORAGE
    DOCFN --> ICACHE

    FOLDFN --> ICOSMOSDB
    FOLDFN --> ICACHE

    SEARCHFN --> ICOSMOSDB
    SEARCHFN --> ICACHE

    DOCFN --> DOCDTO
    FOLDFN --> FOLDDTO
    SEARCHFN --> SEARCHDTO

    DOCFN --> MAPPER
    FOLDFN --> MAPPER

    MAPPER --> DOCMODEL
    MAPPER --> FOLDMODEL
    MAPPER --> TAGMODEL

    COSMOSDB --> DOCMODEL
    COSMOSDB --> FOLDMODEL
    COSMOSDB --> TAGMODEL

    COSMOSDB --> COSMOSSDK
    BLOBSTORAGE --> BLOBSDK
    CACHE --> REDISSDK

    PROGRAM --> KVAULTSDK
    COSMOSDB --> KVAULTSDK
    BLOBSTORAGE --> KVAULTSDK
    CACHE --> KVAULTSDK

    DOCFN --> ERRORHANDLER
    FOLDFN --> ERRORHANDLER
    SEARCHFN --> ERRORHANDLER

    DOCFN --> LOGGING
    FOLDFN --> LOGGING
    SEARCHFN --> LOGGING

    DOCVAL --> HELPERS
    FOLDVAL --> HELPERS
    COSMOSDB --> HELPERS
    BLOBSTORAGE --> HELPERS

    COSMOSDB --> CONSTANTS
    BLOBSTORAGE --> CONSTANTS
    CACHE --> CONSTANTS

    classDef functionStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef interfaceStyle fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef serviceStyle fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    classDef modelStyle fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef middlewareStyle fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef utilStyle fill:#e0f2f1,stroke:#00796b,stroke-width:2px
    classDef sdkStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px

    class DOCFN,FOLDFN,SEARCHFN functionStyle
    class ICOSMOSDB,IBLOBSTORAGE,ICACHE interfaceStyle
    class COSMOSDB,BLOBSTORAGE,CACHE serviceStyle
    class DOCMODEL,FOLDMODEL,TAGMODEL,DOCDTO,FOLDDTO,SEARCHDTO modelStyle
    class AUTH,LOGGING,ERRORHANDLER middlewareStyle
    class DOCVAL,FOLDVAL,MAPPER,HELPERS,CONSTANTS,PROGRAM,SETTINGS utilStyle
    class COSMOSSDK,BLOBSDK,REDISSDK,KVAULTSDK sdkStyle
```

## Component Responsibilities

### Frontend Components

#### Entry Point
- **main.ts**: Bootstrap Vue 3 app, register plugins (Vuetify, Pinia, Router)
- **Vue Router**: Define routes and navigation guards

#### Views (Pages)
- **HomeView**: Dashboard with recent documents and quick actions
- **BrowseView**: Main document browser with folder tree and document list
- **SearchView**: Search interface with filters and results

#### Document Components
- **DocumentList**: Display paginated list of documents
- **DocumentCard**: Show individual document with metadata and actions
- **DocumentUpload**: Handle file selection, validation, and upload
- **MetadataEditor**: Form for editing document metadata and tags

#### Folder Components
- **FolderTree**: Recursive tree component for folder hierarchy
- **FolderNode**: Single tree node with expand/collapse and actions
- **FolderDialog**: Modal for creating or editing folders

#### Search Components
- **SearchBar**: Search input with autocomplete and filters
- **TagFilter**: Tag selection component with popular tags
- **SearchResults**: Display search results with relevance scores

#### Common Components
- **AppLayout**: Main application layout with header, sidebar, and content
- **AppHeader**: Top navigation with search and user menu
- **AppSidebar**: Side navigation with folder tree
- **LoadingSpinner**: Loading indicator
- **ErrorMessage**: Error display component

#### State Management (Pinia)
- **documentStore**: Manage document state, CRUD operations
- **folderStore**: Manage folder tree state and operations
- **searchStore**: Handle search queries and results
- **uiStore**: UI state (loading, errors, dialogs)

#### API Services
- **apiClient**: Axios instance with interceptors and error handling
- **documentService**: Document API calls (upload, download, CRUD)
- **folderService**: Folder API calls (tree, CRUD, move)
- **searchService**: Search API calls with query building

#### Composables
- **useFileUpload**: Reusable file upload logic with progress tracking
- **useFolderTree**: Tree navigation and state management
- **useSearch**: Search debouncing and filter management

#### Types & Utilities
- **types**: TypeScript interfaces for Document, Folder, Tag
- **validators**: Client-side input validation
- **formatters**: Date, file size, and text formatting
- **utils**: General helper functions

### Backend Components

#### HTTP Functions
- **DocumentFunctions**: 7 endpoints for document management
- **FolderFunctions**: 7 endpoints for folder management
- **SearchFunctions**: 1 endpoint for document search

#### Service Layer (Interfaces)
- **ICosmosDbService**: Database operations interface
- **IBlobStorageService**: File storage operations interface
- **ICacheService**: Cache operations interface

#### Service Layer (Implementations)
- **CosmosDbService**: Cosmos DB queries, transactions, and error handling
- **BlobStorageService**: Blob upload, download, SAS token generation
- **CacheService**: Redis get/set/delete with serialization

#### Models
- **Document**: Entity model with JSON attributes
- **Folder**: Entity model with validation
- **Tag**: Entity model with usage tracking

#### DTOs
- **DocumentDto**: API request/response objects
- **FolderDto**: API request/response objects
- **SearchDto**: Search parameters and results

#### Validators
- **DocumentValidator**: Validate document input (size, type, metadata)
- **FolderValidator**: Validate folder operations (depth, name uniqueness)

#### Middleware
- **AuthMiddleware**: Validate API keys from headers
- **LoggingMiddleware**: Log requests/responses to Application Insights
- **ErrorHandler**: Global exception handling and error responses

#### Utilities
- **AutoMapper**: Map between entities and DTOs
- **Helpers**: Common functions (GUID generation, path calculation)
- **Constants**: Application constants (max file size, depth limit)

#### Configuration
- **Program.cs**: Dependency injection container setup
- **appsettings.json**: Configuration for Azure services

#### Azure SDK Integration
- **Azure.Cosmos**: Cosmos DB client
- **Azure.Storage.Blobs**: Blob Storage client
- **StackExchange.Redis**: Redis client
- **Azure.KeyVault**: Key Vault for secrets

## Dependency Flow

### Frontend Dependency Flow
1. User interacts with **Component**
2. Component calls **Composable** (if complex logic)
3. Composable/Component dispatches action to **Pinia Store**
4. Store calls **Service** to make API request
5. Service uses **apiClient** to send HTTP request
6. Response validated against **Types**
7. Data formatted using **Formatters**
8. Store updates state
9. Component reactively updates UI

### Backend Dependency Flow
1. HTTP request hits **Azure Function**
2. **Middleware** (Auth, Logging) processes request
3. Function validates input using **Validator**
4. Function calls **Service Interface**
5. Service implementation uses **Azure SDK**
6. Data mapped between **Entity** and **DTO**
7. Response returned through **ErrorHandler**
8. Telemetry sent to Application Insights

## Design Patterns

### Frontend Patterns
- **Component Composition**: Reusable components with props and events
- **Composition API**: Logic reuse with composables
- **State Management**: Centralized state with Pinia stores
- **Service Layer**: Separation of API logic from components
- **Repository Pattern**: Services abstract API calls

### Backend Patterns
- **Dependency Injection**: Services injected via constructor
- **Repository Pattern**: Service layer abstracts data access
- **DTO Pattern**: Separate API contracts from domain models
- **Middleware Pipeline**: Request/response processing
- **Factory Pattern**: Client creation for Azure services
- **Singleton Pattern**: Shared Azure SDK clients

## Notes

- Frontend uses TypeScript for type safety
- Backend uses C# 12 with nullable reference types
- Async/await throughout for non-blocking operations
- Interface-based design for testability
- Clear separation of concerns (UI, state, services, data)
- All dependencies injected, not created in classes
