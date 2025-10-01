# Deployment

## Infrastructure

### Azure Resources

#### Compute
- **Azure Functions**
  - Plan: Premium Plan (for VNET integration, no cold starts) or Consumption Plan (cost-effective)
  - Runtime: .NET 8
  - OS: Windows or Linux
  - Region: Primary region (e.g., East US, West Europe)
  - Auto-scale: Enabled with min/max instances

#### Storage
- **Azure Blob Storage**
  - Account Type: StorageV2 (General Purpose v2)
  - Performance: Standard (Hot tier for active documents)
  - Replication: LRS (Local) or GRS (Geo-redundant) based on requirements
  - Features: Soft delete enabled, versioning enabled
  - Containers:
    - `documents` - Primary document storage
    - `thumbnails` - Document previews (future)

- **Azure Cosmos DB**
  - API: Core (SQL)
  - Consistency Level: Session (balance of performance and consistency)
  - Throughput: Autoscale (min 400 RU/s, max based on load)
  - Databases:
    - `DocumentManager`
      - Containers: `documents`, `folders`, `tags`
  - Backup: Continuous backup mode
  - Multi-region: Optional for high availability

- **Azure Cache for Redis**
  - Tier: Standard or Premium (persistence + clustering)
  - Size: C1 or higher based on cache requirements
  - Version: Latest Redis 6.x
  - Features: Data persistence enabled, SSL required

#### Security & Monitoring
- **Azure Key Vault**
  - Store: Connection strings, API keys, secrets
  - Access: Managed Identity from Azure Functions
  - Soft delete: Enabled

- **Azure Application Insights**
  - Linked to Azure Functions
  - Log Analytics workspace
  - Custom metrics and traces

- **Azure Monitor**
  - Alerts for performance and errors
  - Dashboards for system health

#### Networking
- **Azure CDN** (Optional)
  - For frontend static assets
  - Global distribution for UI

- **Azure Front Door** (Optional)
  - Load balancing and WAF
  - Multi-region routing

### Infrastructure as Code (IaC)

#### Option 1: Bicep (Recommended)
```
/infrastructure
  ├── main.bicep              # Main deployment file
  ├── modules/
  │   ├── functions.bicep     # Azure Functions
  │   ├── cosmosdb.bicep      # Cosmos DB
  │   ├── storage.bicep       # Blob Storage
  │   ├── redis.bicep         # Redis Cache
  │   ├── keyvault.bicep      # Key Vault
  │   └── monitoring.bicep    # App Insights & Monitor
  ├── parameters/
  │   ├── dev.json            # Dev environment params
  │   ├── staging.json        # Staging environment params
  │   └── prod.json           # Production environment params
  └── README.md
```

#### Option 2: ARM Templates
- Similar structure to Bicep
- JSON-based templates

#### Option 3: Terraform
- Cross-cloud option if needed
- State file in Azure Storage

### Resource Naming Convention
```
{project}-{resource}-{environment}-{region}

Examples:
- docmgr-func-prod-eastus      (Azure Function)
- docmgr-cosmos-prod-eastus    (Cosmos DB)
- docmgr-storage-prod-eastus   (Blob Storage)
- docmgr-redis-prod-eastus     (Redis Cache)
- docmgr-kv-prod-eastus        (Key Vault)
```

## Deployment Strategy

### Frontend Deployment (Vue 3 SPA)

#### Build Process
```bash
# Install dependencies
npm install

# Run tests
npm run test

# Build for production
npm run build
# Output: dist/ folder with static assets
```

#### Hosting Options

**Option 1: Azure Static Web Apps (Recommended)**
- Built-in CI/CD from GitHub
- Global CDN distribution
- Custom domains and SSL
- API integration with Azure Functions
- Free tier available

**Option 2: Azure Blob Storage + CDN**
- Upload `dist/` to Blob Storage `$web` container
- Enable static website hosting
- Configure Azure CDN for caching
- More manual but cost-effective

**Option 3: Azure App Service**
- Host as static site on App Service
- More expensive but more control

#### Deployment Steps (Static Web Apps)
1. Connect GitHub repository
2. Configure build settings:
   - App location: `/frontend`
   - Output location: `dist`
3. Automatic deployment on push to main
4. Environment variables in Azure portal

### Backend Deployment (Azure Functions)

#### Build Process
```bash
# Restore dependencies
dotnet restore

# Run tests
dotnet test

# Publish
dotnet publish -c Release -o ./publish
```

#### Deployment Methods

**Option 1: GitHub Actions (Recommended)**
```yaml
# .github/workflows/backend-deploy.yml
- Build .NET project
- Run tests
- Publish to Azure Functions via deployment credentials
```

**Option 2: Azure DevOps Pipeline**
```yaml
- Build and test
- Publish artifacts
- Deploy to Azure Functions
```

**Option 3: VS Code / Visual Studio**
- Right-click publish (dev only)

**Option 4: Azure Functions Core Tools**
```bash
func azure functionapp publish <function-app-name>
```

#### Configuration
- **Application Settings**: Environment variables in Azure Portal
  - `CosmosDbConnectionString`
  - `BlobStorageConnectionString`
  - `RedisConnectionString`
  - `ApiKey` (for authentication)
- **Key Vault References**: `@Microsoft.KeyVault(SecretUri=...)`

### Database Deployment

#### Cosmos DB
- Initial setup via Bicep/ARM
- Container creation via Azure Portal or scripts
- Indexing policy configuration
- No schema migrations needed (NoSQL)

#### Seed Data (Optional)
```csharp
// Seed script for initial folders/tags
- Run once after deployment
- Creates default folder structure
```

### Cache Deployment

#### Redis
- Provisioned via IaC
- No schema/data to deploy
- Configuration via connection string

### CI/CD Pipeline

#### GitHub Actions Workflow

**Frontend Pipeline**
```yaml
name: Frontend CI/CD

on:
  push:
    branches: [main]
    paths: ['frontend/**']

jobs:
  build-and-deploy:
    - Checkout code
    - Setup Node.js
    - Install dependencies
    - Run unit tests
    - Build production
    - Deploy to Azure Static Web Apps
```

**Backend Pipeline**
```yaml
name: Backend CI/CD

on:
  push:
    branches: [main]
    paths: ['backend/**']

jobs:
  build-and-deploy:
    - Checkout code
    - Setup .NET 8
    - Restore dependencies
    - Run unit tests
    - Run integration tests
    - Publish
    - Deploy to Azure Functions
```

#### Azure DevOps (Alternative)
- Similar pipeline structure
- YAML or Classic pipelines
- Azure service connection for deployment

### Deployment Workflow

```
Developer Push → GitHub
     ↓
CI Pipeline Triggered
     ↓
Build & Test
     ↓
├─ Unit Tests Pass?
├─ Integration Tests Pass?
└─ Code Quality Checks?
     ↓ (Yes)
Deploy to Dev Environment
     ↓
Automated E2E Tests
     ↓ (Pass)
Deploy to Staging (manual approval)
     ↓
Load Testing & QA
     ↓ (Approved)
Deploy to Production (manual approval)
     ↓
Smoke Tests
     ↓
Monitor & Alerts
```

## Environments

### Development (Dev)
**Purpose**: Active development and testing

**Resources**:
- Azure Functions: Consumption Plan
- Cosmos DB: 400 RU/s autoscale
- Blob Storage: LRS, Standard
- Redis: Basic C0 tier
- Static Web App: Free tier

**Configuration**:
- Debug logging enabled
- CORS: `*` (allow all)
- Auto-deploy on commit to `develop` branch
- Shared by all developers

**URL**: `https://docmgr-dev.azurestaticapps.net`

### Staging (Pre-Production)
**Purpose**: Final testing before production

**Resources**:
- Azure Functions: Premium Plan (EP1)
- Cosmos DB: 1000 RU/s autoscale
- Blob Storage: GRS, Standard
- Redis: Standard C1 tier
- Static Web App: Standard tier

**Configuration**:
- Production-like settings
- CORS: Specific origins only
- Deploy on release branch
- E2E and load testing environment
- Production data sanitized copies (optional)

**URL**: `https://docmgr-staging.azurestaticapps.net`

### Production (Prod)
**Purpose**: Live application

**Resources**:
- Azure Functions: Premium Plan (EP2 or higher)
- Cosmos DB: Autoscale (max 10,000+ RU/s)
- Blob Storage: GRS, Standard with CDN
- Redis: Premium P1 (persistence + replication)
- Static Web App: Standard tier
- Multi-region deployment (optional)

**Configuration**:
- Minimal logging (info/error only)
- CORS: Specific production domain only
- Manual deployment approval required
- Blue/Green deployment slots
- Auto-scaling enabled
- Monitoring and alerts active

**URL**: `https://docmanager.company.com`

### Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Auto-deploy | Yes | No | No |
| Approval Required | No | Yes | Yes |
| Scale | Small | Medium | Large |
| Cost | Low | Medium | High |
| Data | Test/Mock | Sanitized | Real |
| Monitoring | Basic | Full | Full + Alerts |
| Uptime SLA | None | 99% | 99.9% |

### Environment Variables

#### Shared Across Environments
```
AZURE_FUNCTIONS_RUNTIME=dotnet
API_VERSION=v1
```

#### Environment-Specific
```
# Dev
ENVIRONMENT=Development
LOG_LEVEL=Debug
COSMOS_DB_NAME=DocumentManager-Dev
BLOB_CONTAINER_NAME=documents-dev

# Staging
ENVIRONMENT=Staging
LOG_LEVEL=Information
COSMOS_DB_NAME=DocumentManager-Staging
BLOB_CONTAINER_NAME=documents-staging

# Production
ENVIRONMENT=Production
LOG_LEVEL=Warning
COSMOS_DB_NAME=DocumentManager-Prod
BLOB_CONTAINER_NAME=documents-prod
```

### Rollback Strategy

**Azure Functions**
- Use deployment slots (swap slots)
- Keep previous version for quick rollback
- Automated rollback on health check failure

**Static Web Apps**
- Deployment history in portal
- Rollback to previous deployment with one click

**Database (Cosmos DB)**
- Continuous backup enabled
- Point-in-time restore available
- No schema changes to rollback (NoSQL)

**Process**:
1. Detect issue (monitoring/alerts)
2. Stop new deployments
3. Swap to previous Function App slot
4. Revert Static Web App deployment
5. Investigate issue in dev/staging
6. Deploy fix when ready

### Monitoring & Health Checks

**Application Insights**
- Real-time metrics dashboard
- Exception tracking
- Performance monitoring
- Custom events and traces

**Health Check Endpoints**
```
GET /api/health
- Returns 200 OK if all services healthy
- Checks: Cosmos DB, Blob Storage, Redis

GET /api/health/detailed
- Detailed status of each dependency
```

**Alerts**
- Error rate > 5%
- Response time p95 > 1s
- Function execution failures
- Cosmos DB RU/s throttling
- Redis connection failures
