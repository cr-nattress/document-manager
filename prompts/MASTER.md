# Master Prompt - Vue 3 TypeScript Development Guidelines

**Repository**: Document Management System
**Stack**: Vue 3 + TypeScript + Vuetify 3 + Pinia + Azure Functions
**Last Updated**: 2025-10-01

---

## Overview

This master prompt coordinates specialized development guidelines for building secure, maintainable Vue 3 applications. Each sub-prompt focuses on a specific area of development and should be referenced based on the task at hand.

---

## Core Principles

**Security First**: All code must implement defense-in-depth security practices
**Type Safety**: Strict TypeScript with no `any` types unless absolutely necessary
**Component Size**: Keep files small and focused (see [Architecture Guidelines](./01-ARCHITECTURE.md))
**Testing**: Security and functionality testing required for all features

---

## Prompt Reference Map

### 1. [Architecture & Project Structure](./01-ARCHITECTURE.md)
**When to use**: Project setup, folder organization, file size management
**Key topics**:
- Project folder structure
- File size limits (200 lines for components, 100 for composables)
- Module organization patterns
- Separation of concerns

### 2. [Security Best Practices](./02-SECURITY.md)
**When to use**: All feature development (always reference this)
**Key topics**:
- Input validation & sanitization
- XSS prevention
- Authentication & authorization
- CSRF protection
- Content Security Policy

### 3. [Vue 3 Component Patterns](./03-COMPONENTS.md)
**When to use**: Creating or modifying Vue components
**Key topics**:
- Composition API with `<script setup>`
- Props & emits with TypeScript
- Component lifecycle
- Computed properties & watchers
- Template security patterns

### 4. [State Management with Pinia](./04-STATE.md)
**When to use**: Working with stores and application state
**Key topics**:
- Store setup patterns
- Secure state management
- Data encryption for sensitive information
- State persistence strategies
- Auto-logout on inactivity

### 5. [API & Network Security](./05-API.md)
**When to use**: API integration, HTTP requests
**Key topics**:
- Secure API client setup
- Request/response interceptors
- CSRF token handling
- Rate limiting
- Error handling without exposing sensitive data

### 6. [Form Validation & Input Handling](./06-VALIDATION.md)
**When to use**: Forms, user input, file uploads
**Key topics**:
- Zod schema validation
- Input sanitization
- File upload security
- Client-side validation patterns
- Error message handling

### 7. [TypeScript Patterns](./07-TYPESCRIPT.md)
**When to use**: Type definitions, interfaces, type safety
**Key topics**:
- Security-focused types
- Branded types for sensitive data
- Type guards and narrowing
- Generic patterns
- Utility types

### 8. [Testing & Security Validation](./08-TESTING.md)
**When to use**: Writing tests, security validation
**Key topics**:
- Security testing checklist
- Unit test patterns
- E2E test security considerations
- Vulnerability scanning
- Security monitoring

### 9. [Build & Deployment](./09-DEPLOYMENT.md)
**When to use**: Configuration, environment setup, CI/CD
**Key topics**:
- Environment variable security
- Build configuration
- Security headers
- CI/CD security checks
- Production hardening

### 10. [UI/UX with Vuetify](./10-UI-UX.md)
**When to use**: Building user interfaces, Material Design components
**Key topics**:
- UI state management (theme, modals, loading)
- Vuetify theme configuration
- Notification system
- Responsive design patterns
- Accessibility patterns
- Animation and transitions

---

## Quick Decision Guide

### "I'm working on..."

**→ A new component**
- Start with: [Components](./03-COMPONENTS.md)
- Must read: [Security](./02-SECURITY.md)
- Consider: [Architecture](./01-ARCHITECTURE.md), [UI/UX](./10-UI-UX.md)

**→ User input/forms**
- Start with: [Validation](./06-VALIDATION.md)
- Must read: [Security](./02-SECURITY.md)
- Consider: [Components](./03-COMPONENTS.md), [UI/UX](./10-UI-UX.md)

**→ Vuetify UI components**
- Start with: [UI/UX](./10-UI-UX.md)
- Must read: [Components](./03-COMPONENTS.md)
- Consider: [State](./04-STATE.md)

**→ API integration**
- Start with: [API](./05-API.md)
- Must read: [Security](./02-SECURITY.md)
- Consider: [State](./04-STATE.md)

**→ State management**
- Start with: [State](./04-STATE.md)
- Must read: [Security](./02-SECURITY.md)
- Consider: [TypeScript](./07-TYPESCRIPT.md)

**→ File uploads**
- Start with: [Validation](./06-VALIDATION.md)
- Must read: [Security](./02-SECURITY.md)
- Consider: [API](./05-API.md)

**→ Type definitions**
- Start with: [TypeScript](./07-TYPESCRIPT.md)
- Must read: [Security](./02-SECURITY.md)

**→ Project setup**
- Start with: [Architecture](./01-ARCHITECTURE.md)
- Must read: [Deployment](./09-DEPLOYMENT.md)
- Consider: [Security](./02-SECURITY.md)

**→ Writing tests**
- Start with: [Testing](./08-TESTING.md)
- Must read: [Security](./02-SECURITY.md)

---

## Universal Rules (Always Apply)

### Security Imperatives
1. **Never trust user input** - Always validate and sanitize
2. **No `v-html` with user content** - XSS prevention
3. **CSRF tokens on all mutations** - State-changing operations
4. **Rate limit all endpoints** - DDoS prevention
5. **Encrypt sensitive data** - PII and credentials
6. **No secrets in client code** - Use environment variables
7. **HTTPS only** - Enforce secure connections
8. **Validate file uploads** - Type, size, content checks

### Code Quality Rules
1. **TypeScript strict mode** - No implicit any
2. **File size limits** - Refactor when exceeded
3. **No console.log in production** - Use proper logging
4. **Error messages generic in prod** - Don't expose internals
5. **Component reusability** - DRY principle
6. **Props validation** - TypeScript interfaces
7. **Meaningful names** - Self-documenting code

### Development Workflow
1. **Security review every feature** - Use checklist
2. **Test before commit** - Unit and integration tests
3. **Dependency audit** - Check for vulnerabilities
4. **Code review required** - Peer review for security
5. **Document security decisions** - Why and how

---

## Implementation Template

When starting any new feature, follow this workflow:

```markdown
## Feature: [Feature Name]

### 1. Security Assessment
- [ ] What user input is involved?
- [ ] What sensitive data is handled?
- [ ] What authentication/authorization is needed?
- [ ] What are the security risks?
- [ ] What mitigations are required?

### 2. Architecture Design
- [ ] Which prompts apply? (list from reference map)
- [ ] File structure and organization
- [ ] Component breakdown (file size limits)
- [ ] State management approach

### 3. Implementation
- [ ] Follow relevant prompt guidelines
- [ ] Implement security measures first
- [ ] Add validation and sanitization
- [ ] Error handling with safe messages

### 4. Testing
- [ ] Security tests written
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual security review

### 5. Review
- [ ] Code review completed
- [ ] Security checklist verified
- [ ] Documentation updated
```

---

## Emergency Security Response

If a security issue is discovered:

1. **Stop development** - Don't commit vulnerable code
2. **Assess impact** - What data/users are affected?
3. **Review [Security](./02-SECURITY.md)** - Find the relevant protection
4. **Implement fix** - Follow security best practices
5. **Test thoroughly** - Verify the vulnerability is closed
6. **Document** - Record the issue and fix for future reference

---

## Prompt Update Protocol

When updating these prompts:

1. **Maintain consistency** - Cross-reference between prompts
2. **Version control** - Update "Last Updated" dates
3. **Security first** - Never remove security guidance
4. **Real examples** - Include working code samples
5. **Clear references** - Link between related prompts

---

## Getting Started

### For New Developers
1. Read [Architecture](./01-ARCHITECTURE.md) - Understand structure
2. Read [Security](./02-SECURITY.md) - Security fundamentals
3. Read [Components](./03-COMPONENTS.md) - Vue 3 patterns
4. Read [TypeScript](./07-TYPESCRIPT.md) - Type safety patterns

### For Code Review
1. Verify [Security](./02-SECURITY.md) checklist
2. Check file sizes per [Architecture](./01-ARCHITECTURE.md)
3. Validate TypeScript patterns from [TypeScript](./07-TYPESCRIPT.md)
4. Confirm test coverage per [Testing](./08-TESTING.md)

---

## Support & Questions

- **Security questions**: Always consult [Security](./02-SECURITY.md) first
- **Pattern questions**: Check relevant specialized prompt
- **Architecture questions**: Review [Architecture](./01-ARCHITECTURE.md)
- **Unclear guidelines**: Open an issue for clarification

---

## Acknowledgment Statement

Before implementing any feature, acknowledge:

> "I will follow the Document Manager security guidelines by referencing the Master Prompt and relevant specialized prompts. I will implement defense-in-depth security, maintain file size limits, use TypeScript strictly, and validate all user input."

---

**Remember**: Security is not optional. Every feature must pass security review before merging.
