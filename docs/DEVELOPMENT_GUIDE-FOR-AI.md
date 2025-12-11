# Swift Development Guide (For AI Agents)
**Last Updated:** 2025-12-11  
**Version:** 1.0.0  

This guide defines clear coding rules, workflow processes, and validation rules to ensure consistent Swift code generation by AI agents.

---

## 1. Branch Strategy
- `main`: production-ready code
- `develop`: integration branch
- `feature/*`: new features
- `bugfix/*`: bug fixes
- `hotfix/*`: urgent fixes

---

## 2. Coding Conventions

### Naming
- Types (class, struct, enum): PascalCase  
- Methods, variables: camelCase  
- Constants: UPPER_CASE  
- Filenames: match the type name  

### Rules
- Avoid force unwrap (`!`). Always use `if let` or `guard let`.
- Use value types (`struct`) when possible.
- Keep functions small and pure when possible.
- Separate protocol definitions and conforming extensions.
- Avoid side effects unless explicitly required.

---

## 3. File Structure
AI should generate files following this structure:

/Sources
/Presentation -> SwiftUI / UI Layer
/Domain -> Business logic, UseCases, Entities
/Data -> Repositories, API clients
/Common -> Extensions, shared helpers
/Tests


---

## 4. Workflow for AI
1. Read the user requirements carefully  
2. Create appropriate files and folders  
3. Follow Swift API design guidelines  
4. Run logical self-check:  
   - Optional handling  
   - Thread safety  
   - Data flow consistency  
5. Generate unit tests (minimum 2 per module)  
6. Provide example usage when outputting new types  

---

## 5. Commit Message Rules
AI must generate messages in this format:

type(scope): subject

Types allowed:
- feat  
- fix  
- refactor  
- docs  
- style  
- test  
- chore  

---

## 6. Testing Rules
AI-generated code must include:
- Unit tests using XCTest  
- Mocking for network requests  
- Simple UI snapshot test (if UI exists)  

Minimum rules:
- Test valid & invalid inputs  
- Ensure correct error propagation  
- Always assert expected outputs  

---

## 7. Deployment Checks
AI must verify:
- Proper environment configuration  
- Correct bundle identifiers  
- No force unwrap  
- No unused variables  
- Logging statements removed in production builds  

---

## 8. Optimization Rules

### Client (Swift)
- Avoid unnecessary view recomputation  
- Use `@StateObject` for long-lived objects  
- Use lazy loading where beneficial  
- Reuse JSONDecoder / JSONEncoder  

---

## 9. Safety & Errors
AI must:
- Always generate safe optional handling  
- Provide descriptive error enums  
- Use `Result<T, Error>` for async logic  

---

## 10. Documentation Standards
- Every public type must include doc comments.  
- Non-trivial logic must include explanatory comments.  

---

