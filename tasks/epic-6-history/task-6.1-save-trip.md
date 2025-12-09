# Task 6.1: 주행 기록 저장

> **Epic**: Epic 6 - 주행 기록
> **Status**: 🟢 Done
> **Priority**: P2
> **PRD**: FR-6.1

---

## 📋 개요

완료된 주행 기록을 UserDefaults에 저장합니다. (Core Data 대신 Codable + UserDefaults 사용)

## ✅ Acceptance Criteria

- [x] Trip 저장 시스템 구현 (UserDefaults + Codable)
- [x] TripRepository 저장/조회/삭제 기능
- [x] 최대 100건 저장 (초과 시 오래된 것 삭제)
- [x] 주행 완료 시 자동 저장 가능

## 📝 저장 항목

- 주행 ID (UUID)
- 시작/종료 시간
- 총 요금
- 이동 거리
- 주행 시간
- 시작/종료 지역
- 지역 변경 횟수
- 야간 주행 여부
- 요금 상세 내역

---

## 📝 구현 노트

### 주요 구현 내용

1. **TripRepository 업데이트** (HoguMeter/Data/Repositories/TripRepository.swift:1-68)
   - Core Data 대신 UserDefaults + Codable 방식 사용
   - JSONEncoder/JSONDecoder로 Trip 배열 직렬화
   - 간단하고 가벼운 저장 방식 (100건 이하에 적합)

2. **저장 기능 (save)**
   - 새 Trip을 배열 맨 앞에 추가 (최신순)
   - 최대 100건 제한
   - 초과 시 오래된 기록 자동 삭제
   - UserDefaults에 JSON 형태로 저장

3. **조회 기능 (getAll)**
   - UserDefaults에서 데이터 읽기
   - JSONDecoder로 [Trip] 복원
   - 오류 처리 (디코딩 실패 시 빈 배열 반환)

4. **삭제 기능**
   - delete(_ trip): 특정 Trip 삭제
   - deleteAll(): 전체 기록 삭제
   - 삭제 후 UserDefaults 업데이트

5. **데이터 영속성**
   - UserDefaults: 앱 재시작 후에도 유지
   - JSON 직렬화: Trip은 Codable 프로토콜 준수
   - 자동 동기화: saveToDisk() 메서드

### Core Data 대신 UserDefaults를 선택한 이유

- ✅ 간단한 구현 (CRUD 로직 명확)
- ✅ 100건 이하 데이터셋에 충분
- ✅ 설정이 불필요 (Core Data stack 없음)
- ✅ 마이그레이션 불필요
- ✅ Trip이 이미 Codable 준수

### 기술 스택
- UserDefaults (영속성 저장소)
- Codable + JSONEncoder/JSONDecoder
- Swift Array operations

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
