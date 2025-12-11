
---

## 4. Development Workflow

1. Select a top-priority task from `docs/todo/`.
2. Review `Requirements`, `Dependencies`, and `TODO` in its `.md` file.
3. Create a branch from `develop`.
4. Implement features following coding conventions.
5. Run Playwright tests:
   - UI rendering  
   - Component functionality  
   - Responsive layout  
   - Accessibility (ARIA, labels, focus order)  
   - Console errors  
6. Fix all issues found.
7. Move the completed `.md` to `docs/completed/`.
8. Update documentation:
   - `development-guide-for-ai.md` (if changed)
   - Architecture or PlantUML diagrams (if changed)

---

## 5. Code Quality Rules for AI

### General
- Remove unused imports and dead code.  
- Do not use `console.log` in production code.  
- Follow single responsibility principle (SRP).  
- Prefer async/await over promise chains.  
- Avoid magic numbers—use constants.

### Frontend (React)
- Prefer:
  - `React.memo`
  - `useCallback`
  - `useMemo`
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
- Test user interactions (click, input, keyboard).  
- Use React Testing Library.  
- Follow AAA pattern (Arrange → Act → Assert).  
- Test behavior, not DOM structure.

### Server
- Test all API endpoints with valid and invalid data.  
- Validate status codes and response schemas.  
- Use supertest or similar tools.  
- Use test containers or in-memory DB for database tests.

---

## 7. Deployment Checklist

### Environment
- [ ] Environment variables configured  
- [ ] Database connection verified  
- [ ] HTTPS active  
- [ ] CORS configured  
- [ ] Error logging enabled  
- [ ] Monitoring enabled  

### CI/CD
- [ ] Lint must pass  
- [ ] Type check must pass  
- [ ] Unit tests must pass  
- [ ] Playwright tests must pass  
- [ ] Build artifacts validated  

---

## 8. Optimization Rules

### Client
- Optimize images.  
- Use dynamic import for code splitting.  
- Reduce bundle size via tree shaking.

### Server
- Enable compression middleware.  
- Apply caching strategies.  
- Optimize DB queries (indexes, avoid N+1).  
- Reduce API payload sizes (DTO, projections).  

---

## 9. File Management Rules
- Every task must be documented in a `.md` file.  
- Completed files must be moved to `docs/completed/`.  
- Status fields should follow a standard format for AI parsing.  
- All diagrams must be written in PlantUML.

---

## 10. Version Info
- **Version:** 1.3.0  
- **Last Updated:** 2025-12-11  

