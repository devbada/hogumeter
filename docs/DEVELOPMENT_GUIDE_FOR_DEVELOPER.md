# Swift 개발 가이드
**Last Updated:** 2025-12-11  
**Version:** 1.0.0  

Swift 기반 프로젝트 개발을 위한 코딩 규칙, 브랜치 전략, 테스트 가이드, 배포 체크리스트를 다룹니다.

---

## 1. 브랜치 전략
- `main` : 배포용 브랜치  
- `develop` : 통합 개발 브랜치  
- `feature/*` : 기능 개발  
- `bugfix/*` : 버그 수정  
- `hotfix/*` : 긴급 대응  

---

## 2. 코드 스타일 가이드

### **네이밍 컨벤션**
| 대상 | 스타일 |
|------|--------|
| 클래스, Struct, Enum | PascalCase |
| 변수, 함수 | camelCase |
| 상수 | UPPER_CASE |
| 파일명 | 타입명과 동일 |

### **기본 규칙**
- 하나의 파일에는 하나의 타입 정의를 권장
- Force unwrap(`!`) 지양 → optional binding 사용
- protocol extension 과 class extension을 구분하여 역할 명확히 하기
- 가능한 Immutable data(값 타입) 사용

---

## 3. 폴더 구조 제안
/Sources
/Presentation
/Domain
/Data
/Common
/Tests


---

## 4. 개발 Workflow
1. 작업할 이슈 선택  
2. `develop` 브랜치에서 새로운 `feature/*` 브랜치 생성  
3. 기능 개발  
4. 단위 테스트 + UI 테스트 실행  
5. 리뷰 요청(PR)  
6. 승인 후 `develop` → `main` 순으로 merge  

---

## 5. 커밋 메시지 규칙

type(scope): subject
body (optional)
footer (optional)

### Types
- **feat**: 새로운 기능  
- **fix**: 버그 수정  
- **refactor**: 구조 개선  
- **style**: 코드 스타일 변경  
- **test**: 테스트 코드 추가  
- **docs**: 문서 수정  
- **chore**: 기타  

---

## 6. 테스트 가이드

### Unit Test
- 비즈니스 로직 중심으로 작성  
- Mock / Stub 적극 사용  
- XCTest 기본 구조 준수  

### UI Test
- 주요 플로우 기준  
- 접근성 identifier 명확히 부여  

---

## 7. 배포 체크리스트
- [ ] 빌드 버전 / 마케팅 버전 업데이트  
- [ ] Release 환경 설정 확인  
- [ ] API Key 및 환경변수 점검  
- [ ] Crashlytics / 로그 수집 정상 작동 여부 확인  
- [ ] App Store 스크린샷 변경 여부 확인  

---

## 8. 성능 및 최적화 규칙

### 클라이언트(Swift)
- 불필요한 재렌더 방지 (SwiftUI → `@State`, `@ObservedObject` 적절 사용)
- 이미지 캐싱
- 네트워크 요청 최소화
- Codable 사용 시 DateFormatter 공통화

---

## 9. 보안 규칙
- Keychain 사용해 민감 정보 저장
- HTTPS / SSL pinning 고려  
- API 응답 검증 필수  

---

## 10. 문서화
- 주요 로직은 Docstring(`///`) 주석으로 설명  
- README 정기 업데이트  

---

