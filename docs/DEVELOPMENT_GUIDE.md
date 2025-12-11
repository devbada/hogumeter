# Development Guide for AI  
**Version:** 1.3.0  
**Last Updated:** 2025-12-11  

This document defines coding conventions, workflows, automation rules, and quality standards for AI-assisted development.

---

## 1. Core Principles
- Code must be consistent, reusable, and predictable.
- Rules are designed so AI can generate and modify code safely.
- Documentation must always reflect actual code logic.

---

## 2. Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production |
| `develop` | Integration / next release |
| `feature/*` | New feature |
| `bugfix/*` | Bug fix |
| `hotfix/*` | Urgent production fix |

### Naming Examples
feature/ai-login-enhancement  
feature/optimize-query-user-list  
bugfix/fix-null-response-error  
hotfix/payment-callback-crash

---

## 3. Commit Message Convention

### Format
type(scope): subject

body

footer

### Types
- feat
- fix
- docs
- style
- refactor
- test
- chore

### Example
feat(auth): implement JWT refresh token handling

Added refresh token rotation logic and updated middleware.  
Improved token expiration compliance.

Refs: #123

---

## 4. Development Workflow

1. Select a top-priority task from docs/todo/.
2. Review Requirements, Dependencies, and TODO in its .md file.
3. Create a branch from develop.
4. Implement features following coding conventions.
5. Run Playwright tests:
   - UI rendering
   - Component functionality
   - Responsive layout
   - Accessibility (ARIA, labels, focus order)
   - Console errors
6. Fix all issues found.
7. Move the completed .md to docs/completed/.
8. Update documentation:
   - development-guide-for-ai.md (if changed)
   - Architecture or PlantUML diagrams (if changed)

---

## 5. Code Quality Rules for AI

### General
- Remove unused imports and dead code.
- Do not use console.log in production code.
- Follow single responsibility principle (SRP).
- Prefer async/await over promise chains.
- Avoid magic numbers—use constants.

### Frontend (React)
- Prefer React.memo, useCallback, useMemo.
- Separate presentational and container components.
- Avoid duplicated state.

### Backend (Server)
- API responses must follow a consistent schema.
- Validate all inputs server-side.
- Handle exceptions through centralized logic.
- Use structured logging (debug/info/error).

---

## 6. Testing Guide

### Client
- Test form validation.
- Test component rendering.
- Test user interactions.
- Use React Testing Library.
- Follow AAA pattern.
- Test behavior, not DOM structure.

### Server
- Test API endpoints with valid/invalid data.
- Validate status codes and response schemas.
- Use supertest or similar tools.
- Use test containers or in-memory DB.

---

## 7. Deployment Checklist

### Environment
- Environment variables configured
- Database connection verified
- HTTPS active
- CORS configured
- Error logging enabled
- Monitoring enabled

### CI/CD
- Lint must pass
- Type check must pass
- Unit tests must pass
- Playwright tests must pass
- Build artifacts validated

---

## 8. Optimization Rules

### Client
- Optimize images.
- Use dynamic import for code splitting.
- Reduce bundle size via tree shaking.

### Server
- Enable compression middleware.
- Apply caching strategies.
- Optimize DB queries.
- Reduce API payload sizes.

---

## 9. File Management Rules
- Every task must be documented in a .md file.
- Completed files must be moved to docs/completed/.
- Status fields should follow a standard format.
- All diagrams must be written in PlantUML.

---

## 10. Version Info
Version: 1.3.0  
Last Updated: 2025-12-11

