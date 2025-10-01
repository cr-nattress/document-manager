# Document Management System - Diagrams

**Project**: Azure Document Management System
**Last Updated**: 2025-09-30
**Version**: 1.0.0

This directory contains comprehensive visual documentation for the Document Management System, including architecture, data models, workflows, and deployment diagrams.

---

## 📚 Diagram Index

### 1. [System Architecture Diagram](./01-system-architecture.md)
**Purpose**: High-level system architecture showing all layers and components

**Includes**:
- Client layer (desktop/mobile browsers)
- Presentation layer (Vue 3 SPA with Vuetify)
- API layer (Azure Functions)
- Service layer (Cosmos DB, Blob Storage, Redis services)
- Data layer (Azure services)
- Security & monitoring components

**Key Concepts**: Serverless architecture, Azure-native, three-tier design

---

### 2. [Entity Relationship Diagram (ERD)](./02-database-erd.md)
**Purpose**: Cosmos DB database structure and relationships

**Includes**:
- Three containers: documents, folders, tags
- Partition key strategies
- Entity relationships (1:1, 1:N, N:M)
- Indexing policies
- Data constraints and validation rules
- Sample data examples

**Key Concepts**: NoSQL schema, denormalization, partitioning for scale

---

### 3. [Sequence Diagrams](./03-sequence-diagrams.md)
**Purpose**: Time-based interactions for key workflows

**Includes**:
- Document upload workflow
- Document download workflow
- Folder tree navigation
- Search documents workflow
- Move document between folders
- Create folder workflow
- Edit document metadata

**Key Concepts**: API interactions, caching strategies, error handling

---

### 4. [Component Diagram](./04-component-diagram.md)
**Purpose**: Module organization and dependencies

**Includes**:
- Frontend architecture (Vue 3 components, Pinia stores, services)
- Backend architecture (Azure Functions, services, models)
- Dependency flow patterns
- Design patterns used

**Key Concepts**: Separation of concerns, dependency injection, component composition

---

### 5. [Data Flow Diagrams](./05-data-flow-diagram.md)
**Purpose**: How data moves through the system

**Includes**:
- Document upload data flow
- Document download data flow
- Search data flow
- Folder tree loading data flow
- Data transformation flow

**Key Concepts**: Cache-first strategy, data transformations, performance optimization

---

### 6. [State Diagrams](./06-state-diagrams.md)
**Purpose**: Object lifecycle and state transitions

**Includes**:
- Document lifecycle states
- Folder states (empty, with contents, deleting)
- Search request states
- File upload progress states
- Cache entry states
- API request states

**Key Concepts**: State management, transitions, error recovery

---

### 7. [User Flow Diagrams](./07-user-flow-diagrams.md)
**Purpose**: User journey through the application

**Includes**:
- Upload document user flow
- Search and find document flow
- Create folder structure flow
- Edit document metadata flow
- Mobile document access flow
- First-time user onboarding flow

**Key Concepts**: User experience, decision points, error handling, progressive disclosure

---

### 8. [Deployment Diagram](./08-deployment-diagram.md)
**Purpose**: Azure infrastructure layout and deployment topology

**Includes**:
- Azure resource architecture (production)
- Network architecture with security boundaries
- CI/CD pipeline architecture
- Three environments (Dev, Staging, Production)
- Resource specifications for each environment
- Cost estimations
- Deployment checklist

**Key Concepts**: Infrastructure as Code (Bicep), auto-scaling, monitoring

---

### 9. [API Endpoint Map](./09-api-map.md)
**Purpose**: Complete REST API structure and documentation

**Includes**:
- All 15 API endpoints organized by category
- Request/response examples
- HTTP status codes
- Authentication methods
- Rate limiting
- Error response formats
- Pagination, sorting, and filtering

**Key Concepts**: RESTful API design, API versioning, consistent error handling

---

## 🎯 Quick Navigation by Use Case

### Planning & Design
- Start with: [System Architecture](./01-system-architecture.md)
- Then review: [Component Diagram](./04-component-diagram.md)
- Understand data: [ERD](./02-database-erd.md)

### Development - Frontend
- Components: [Component Diagram](./04-component-diagram.md)
- User flows: [User Flow Diagrams](./07-user-flow-diagrams.md)
- API integration: [API Endpoint Map](./09-api-map.md)

### Development - Backend
- API structure: [API Endpoint Map](./09-api-map.md)
- Data model: [ERD](./02-database-erd.md)
- Workflows: [Sequence Diagrams](./03-sequence-diagrams.md)

### DevOps & Deployment
- Infrastructure: [Deployment Diagram](./08-deployment-diagram.md)
- System overview: [System Architecture](./01-system-architecture.md)

### Testing
- Test scenarios: [Sequence Diagrams](./03-sequence-diagrams.md)
- User flows: [User Flow Diagrams](./07-user-flow-diagrams.md)
- State testing: [State Diagrams](./06-state-diagrams.md)

### Documentation
- All diagrams provide comprehensive documentation
- Each diagram includes detailed notes and observations
- Examples and sample data provided throughout

---

## 📊 Diagram Format

All diagrams use **Mermaid syntax** for:
- Easy version control (text-based)
- Rendering in GitHub, VS Code, and documentation tools
- Maintainability and updates
- Collaboration-friendly format

Some diagrams also include **ASCII art** for network and deployment topology.

---

## 🔄 Diagram Maintenance

### When to Update
- **Architecture changes**: Update system, component, and deployment diagrams
- **API changes**: Update API map and sequence diagrams
- **Database changes**: Update ERD and data flow diagrams
- **User flow changes**: Update user flow diagrams
- **New features**: Add relevant diagrams to document the feature

### Version Control
- All diagrams are versioned with the project
- Include "Last Updated" date in each diagram
- Document major changes in commit messages

### Review Schedule
- **Monthly**: Quick review for accuracy
- **Quarterly**: Comprehensive review and updates
- **Before major releases**: Full diagram audit

---

## 🛠️ Tools for Viewing Diagrams

### Mermaid Renderers
1. **VS Code**: Install "Markdown Preview Mermaid Support" extension
2. **GitHub**: Renders Mermaid automatically in markdown files
3. **Online**: https://mermaid.live for quick viewing/editing
4. **Documentation sites**: GitBook, Docusaurus, MkDocs all support Mermaid

### Exporting Diagrams to Images

**⚡ Quick Start**: [QUICK-START.md](./QUICK-START.md) - Get images in 3 steps!

**📖 Detailed Guide**: [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md) - Complete instructions and troubleshooting

**🔧 Recent Fixes**: [FIXES-AND-UPDATES.md](./FIXES-AND-UPDATES.md) - Improvements and change log

**Simple Instructions**:
1. Install prerequisites: Node.js + `npm install -g @mermaid-js/mermaid-cli`
2. Run script:
   - Windows: Double-click `generate-images.bat`
   - Mac/Linux: `./generate-images.sh`
   - Any platform: `node generate-images.js`
3. Get ~33 PNG images (2048x2048, transparent background)

**Keep source (.md) files as source of truth** - regenerate images when diagrams change.

---

## 📝 Diagram Creation Guidelines

Based on the [Application Diagrams & Visuals Creation Guide](../planning/app-visuals.md), all diagrams follow these principles:

### Structure & Organization
- Start with high-level overview
- Add details progressively
- Group related components
- Use consistent naming conventions
- Add clear labels and descriptions

### Visual Clarity
- Limit nodes per diagram (max 15-20)
- Use subgraphs/groups for organization
- Apply consistent styling
- Choose appropriate layout direction
- Add legends for complex diagrams

### Technical Accuracy
- Verify all connections
- Check relationship cardinality
- Validate state transitions
- Confirm API endpoints
- Review security boundaries

---

## 📖 Related Documentation

- **Planning Documents**: `../planning/` - Requirements, architecture, technical specs
- **API Specification**: `../planning/api-spec.md` - Detailed API documentation
- **Data Model**: `../planning/data-model.md` - Complete data model documentation
- **User Stories**: `../planning/user-stories.md` - User personas and use cases
- **Deployment Guide**: `../planning/deployment.md` - Infrastructure details

---

## 🤝 Contributing

When adding or updating diagrams:

1. Follow the existing format and naming convention
2. Include "Purpose", "Last Updated", and "Version" at the top
3. Add detailed notes and observations sections
4. Use consistent color schemes (follow existing diagrams)
5. Update this README index when adding new diagrams
6. Test Mermaid rendering before committing

---

## 📄 Diagram Summary

| # | Diagram | Type | Complexity | Primary Audience |
|---|---------|------|------------|------------------|
| 1 | System Architecture | Architecture | Medium | All |
| 2 | Database ERD | Data | High | Backend Devs, DBAs |
| 3 | Sequence Diagrams | Behavioral | High | All Developers |
| 4 | Component Diagram | Structural | High | Architects, Developers |
| 5 | Data Flow | Behavioral | Medium | Developers, Architects |
| 6 | State Diagrams | Behavioral | Medium | Developers, QA |
| 7 | User Flow | UX | Medium | Frontend, UX, Product |
| 8 | Deployment | Infrastructure | High | DevOps, Architects |
| 9 | API Map | Integration | Medium | All Developers |

**Total Diagrams**: 9 (with multiple sub-diagrams in each)

---

**For questions or suggestions regarding these diagrams, please refer to the project documentation or contact the technical lead.**
