# 호구게이션 설계 문서

문서 버전: 0.1.0  
작성일: 2026-06-23  
상태: Draft  
대상 기능: 호구미터 유료 기능 후보 `호구게이션`

---

## 1. 기능 정의

호구게이션은 호구미터 안에서 목적지를 설정하고, 예상 거리·예상 시간·예상 호구비를 보여주는 목적지 기반 요금 예측 기능입니다.

기능명은 `호구게이션`으로 고정합니다.

앱의 역할:

- 출발지 설정
- 목적지 검색
- 앱 안 지도 표시
- 경로선 표시
- 예상 거리 표시
- 예상 시간 표시
- 예상 호구비 계산
- 네비게이션 시작 후 진행 방향 기준 지도 회전
- 네비게이션 시작 후 3D 기울기 지도 표시
- 네비게이션 우측 상단 호구비용 표시
- 네비게이션 좌측 상단 현재 호구비용 표시
- 주행 속도에 따른 지도 카메라 거리 조절
- 네비게이션 중지
- 호구미터 주행 측정과 연결

직접 만들지 않는 범위:

- 음성 턴바이턴 안내
- 차선 안내
- 교차로 확대 안내
- 완전한 상용 내비게이션 엔진
- 독자 도로망 기반 최단 경로 탐색

제품 포지션:

- 내비게이션 대체 앱이 아닙니다.
- `호구비 예측 + 주행 중 호구비 비교`에 집중한 드라이브 장난 기능입니다.

---

## 2. MVP 범위

MVP 목표는 앱 안에서 목적지 기반 예상 호구비를 바로 확인하고, 미터기 측정을 시작할 수 있게 만드는 것입니다.

MVP 포함:

- `호구게이션` 탭
- 현재 위치를 출발지로 설정
- 출발지 직접 검색
- 목적지 검색
- `MapKit` 지도 표시
- `MKDirections` 기반 자동차 경로 계산
- 경로선 표시
- 출발/도착 마커 표시
- 예상 거리 표시
- 예상 시간 표시
- 예상 호구비 표시
- `네비게이션 시작` 버튼
- 네비게이션 진행 중 지도 heading/pitch 적용
- 네비게이션 진행 중 우측 상단 호구비용 배지
- 네비게이션 진행 중 좌측 상단 현재 호구비용 배지
- 네비게이션 진행 중 속도별 카메라 거리 변경
- 네비게이션 중지 버튼
- 호구게이션 화면 유지 및 내부 미터 측정 시작

MVP 예상 요금 계산:

- `MapKit` 경로 거리 사용
- `MapKit` 예상 소요시간 사용
- 현재 선택된 지역 요금제 사용
- 기준 속도 이하로 추정되는 지연 시간을 저속 시간요금으로 반영
- 지역 할증은 MVP에서 제외
- 실시간 교통 API 보정은 MVP에서 제외

MVP 제외:

- 복수 경로 후보 선택
- 실시간 교통 API 직접 보정
- 서버 연동
- 경로 이탈 감지
- 자동 재탐색
- 목적지 도착 판정
- 주행 중 예상 호구비 재계산
- 유료 구매/구독 잠금

TODO-minam: 유료 상품 정책이 확정되면 StoreKit product id, 무료 체험 여부, 기능 잠금 위치를 결정해야 합니다.

---

## 3. 현재 구현 기준

현재 MVP 구현 파일:

- `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift`
- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Domain/Services/FareCalculator.swift`
- `HoguMeter/Presentation/Views/ContentView.swift`
- `HoguMeter/Presentation/Views/Main/MainMeterView.swift`
- `HoguMeter/Core/Extensions/Notification+Extensions.swift`

현재 흐름:

1. 사용자가 `호구게이션` 탭 진입
2. 앱이 현재 위치 권한 확인
3. 현재 위치를 출발지로 설정
4. 사용자가 목적지 검색
5. `MKLocalSearchCompleter`로 자동완성 표시
6. 선택한 목적지를 `MKLocalSearch`로 `MKMapItem` 변환
7. `MKDirections`로 자동차 경로 계산
8. 지도에 경로선 표시
9. 예상 거리, 예상 시간, 예상 호구비 표시
10. `네비게이션 시작` 탭
11. 호구게이션 화면을 네비게이션 진행 상태로 전환
12. 지도 카메라를 현재 진행 방향으로 회전하고 3D 기울기 적용
13. 속도에 따라 지도 카메라 거리를 조절
14. 우측 상단에 예상 호구비용 표시
15. 좌측 상단에 현재 호구비용 표시
16. `NotificationCenter`로 내부 미터 측정 연동 이벤트 전달
17. `네비게이션 중지` 탭 시 내부 미터 측정도 중지

현재 제한:

- 목적지 경로와 실제 주행 경로는 아직 연결되어 있지 않습니다.
- `네비게이션 시작` 후 경로 이탈·도착·재계산은 없습니다.
- `네비게이션 중지`는 현재 MVP에서 미터 측정 정지까지 함께 수행합니다.
- `MKDirections.expectedTravelTime`에 포함된 교통 반영 수준은 Apple 제공값에 의존합니다.

---

## 4. 제대로 만들기 로드맵

### Phase 1. MVP 안정화

목표:

- 현재 구현을 제품 품질로 다듬습니다.

작업:

- 검색 결과 선택 UX 개선
- 출발지/목적지 입력 초기화 버튼
- 경로 계산 실패 메시지 세분화
- 위치 권한 거부 상태 안내
- 빈 목적지 저장 방지
- iPad 레이아웃 점검
- 다크모드 지도 패널 가독성 점검
- 예상 요금 테스트 보강

완료 기준:

- 검색부터 네비게이션 시작까지 막힘 없음
- 위치 권한 거부 상태에서도 앱이 깨지지 않음
- 지도와 하단 요약 패널이 겹치지 않음

### Phase 2. 경로 후보와 요금 비교

목표:

- 사용자가 여러 경로 중 호구비가 덜 나오는 경로를 고를 수 있게 합니다.

작업:

- `MKDirections.Request.requestsAlternateRoutes = true`
- 복수 경로 카드 표시
- 추천 기준 추가
  - 최단 시간
  - 최단 거리
  - 최저 예상 호구비
- 선택한 경로 지도 강조
- 경로별 예상 요금 비교

완료 기준:

- 2개 이상 경로가 있으면 후보 표시
- 선택 경로에 따라 예상 호구비 즉시 변경

### Phase 3. 주행 중 예측 연동

목표:

- 호구게이션 예상치와 실제 미터 요금을 비교합니다.

작업:

- 선택 경로를 `MeterViewModel`에 전달
- 예상 총 호구비 저장
- 주행 중 현재 요금 대비 예상 잔여 요금 표시
- `현재 / 예상 / 차이` 표시
- 도착지까지 남은 거리 계산
- 도착 반경 설정

완료 기준:

- 주행 중 예상 호구비 대비 현재 상태를 볼 수 있음
- 도착 근처에서 주행 종료 안내 가능

### Phase 4. 경로 이탈 감지와 재계산

목표:

- 사용자가 경로를 벗어나면 예상 호구비를 다시 계산합니다.

작업:

- 현재 위치와 선택 경로 polyline 간 거리 계산
- 이탈 기준 정의
  - 예: 경로에서 80m 이상 벗어남
  - 예: 15초 이상 경로 외부 유지
- 경로 이탈 이벤트 생성
- 현재 위치에서 목적지까지 재계산
- 재계산 전후 예상 호구비 비교 표시

완료 기준:

- 경로 이탈 시 예상 호구비가 갱신됨
- 순간 GPS 튐으로 재계산이 반복되지 않음

### Phase 5. 실시간 교통 보정 서버

목표:

- 공공 교통 데이터를 서버에서 수집하고, 호구게이션 예상 요금 보정에 사용합니다.

서버가 필요한 이유:

- API 키 보호
- 쿼터 관리
- 지역별 API 포맷 흡수
- 캐싱
- 장애 fallback
- 도로 링크 매칭

후보 API:

- ITS 국가교통정보센터 Open API
  - 교통소통정보
  - 돌발상황정보
  - 교통예측정보
  - 차량검지정보
  - 표준노드링크
- 서울 TOPIS / 서울 열린데이터광장
  - 서울시 실시간 도로 소통 정보
  - 서울시 실시간 돌발 정보
  - 서울시 교통소통 표준링크 매핑정보
- 한국도로공사/공공데이터포털
  - 고속도로 소통
  - 사고·공사
  - CCTV·VMS 계열

참고:

- ITS 국가교통정보센터: https://www.its.go.kr/opendata/opendataList
- 서울시 실시간 도로 소통 정보: https://data.seoul.go.kr/dataList/OA-13291/A/1/datasetView.do
- 공공데이터포털 전국무인교통단속카메라표준데이터: https://api.data.go.kr/openapi/tn_pubr_public_unmanned_traffic_camera_api

TODO-minam: 실시간 교통 보정까지 갈 경우 백엔드 운영 위치를 정해야 합니다. 후보는 Spring Boot 서버, Supabase Edge Function, Cloudflare Workers입니다.

### Phase 5-1. 과속카메라 안내

목표:

- 공공데이터포털 `전국무인교통단속카메라표준데이터`를 사용해 네비게이션 중 전방 단속 카메라를 안내합니다.

MVP 구현:

- 앱에서 `https://api.data.go.kr/openapi/tn_pubr_public_unmanned_traffic_camera_api` 직접 호출
- `Info.plist`의 `PublicSpeedCameraServiceKey`는 `$(PUBLIC_SPEED_CAMERA_SERVICE_KEY)` 빌드 변수만 참조
- 실제 서비스키는 gitignore된 `Config/Secrets.xcconfig`에서 주입
- 네비게이션 시작 시 카메라 목록 1회 로드
- 현재 진행 방향 기준 약 600m 전방 카메라 필터
- 현재 진행 방향과 카메라 방향 차이 45도 이내 필터
- 경로 polyline 좌표와 카메라 거리 160m 이내 필터
- 가장 가까운 카메라 1개 안내
- 지도 마커, 상단 카드, 햅틱 표시
- 제한속도 초과 시 경고 카드 깜빡임 표시
- 공공데이터 응답 `header.resultCode`가 `00`이 아니면 API 오류로 처리

운영 전환:

- 앱 직접 호출은 API 키 노출과 대용량 페이지 로드 문제가 있습니다.
- 운영 버전은 Route7처럼 서버에서 공공데이터를 주기적으로 적재하고, 앱은 전방 카메라만 조회하는 구조가 맞습니다.

TODO-minam: `Config/Secrets.xcconfig.example`을 `Config/Secrets.xcconfig`로 복사한 뒤 공공데이터포털 서비스키를 입력해야 합니다.

### Phase 6. 유료 기능 제품화

목표:

- 호구게이션을 유료 기능으로 안정적으로 출시합니다.

작업:

- StoreKit 2 연동
- 구매 상태 캐싱
- 오프라인 entitlement 처리
- 무료 사용 제한 정책
- 구매 복원
- 유료 기능 안내 화면
- App Store 심사 문구 정리

완료 기준:

- 미구매자는 기능을 이해하고 구매할 수 있음
- 구매자는 네트워크 불안정 상태에서도 기능 접근 가능

TODO-minam: 유료 기능명, 가격, 무료 체험, 일회성 구매/구독 여부를 확정해야 합니다.

---

## 5. 권장 아키텍처

iOS 앱 구조:

```text
Presentation
  Views
    HoguNavigation
      HoguNavigationView
      HoguNavigationMapView
  ViewModels
    HoguNavigationViewModel

Domain
  Entities
    HoguRoute
    HoguRouteCandidate
    HoguNavigationSession
    HoguTrafficAdjustment
  Services
    FareCalculator
    MapKitRoutePlanningService
    HoguRouteDeviationDetector
    HoguNavigationSessionManager

Data
  Repositories
    HoguNavigationRepository
  Remote
    HoguTrafficAPIClient
```

서버 구조:

```text
Spring Boot API
  TrafficController
  TrafficAdjustmentService
  ItsTrafficService
  TopisTrafficService
  RoadLinkMatchingService
  TrafficCacheRepository
```

권장 원칙:

- 앱은 UI와 기기 위치 상태에 집중합니다.
- 서버는 교통 API 수집, 키 보호, 캐싱, 보정 계산을 담당합니다.
- 서버 장애 시 앱은 `MapKit` 예상 시간 기반으로 fallback 합니다.
- 공공 API 원본값을 앱에 그대로 노출하지 않고 `호구비 보정값` 형태로 변환합니다.

---

## 6. 도메인 모델 초안

```swift
struct HoguRouteCandidate: Identifiable {
    let id: UUID
    let title: String
    let distance: Double
    let expectedTravelTime: TimeInterval
    let expectedFare: Int
    let trafficAdjustedFare: Int?
    let polyline: MKPolyline
}

struct HoguNavigationSession {
    let id: UUID
    let originName: String
    let destinationName: String
    let destinationCoordinate: CLLocationCoordinate2D
    let selectedRoute: HoguRouteCandidate
    let startedAt: Date
}

struct HoguTrafficAdjustment {
    let routeId: UUID
    let delaySeconds: TimeInterval
    let confidence: Double
    let source: String
}
```

---

## 7. 요금 보정 방향

기본 예상 요금:

```text
예상 호구비 = 기본요금
          + 거리요금
          + 추정 저속 시간요금
          + 선택 정책 기반 할증
```

MVP 추정 저속 시간:

```text
기준속도 통과 시간 = 경로거리 / 지역 요금제 기준 저속속도
추정 저속 시간 = max(0, MapKit 예상시간 - 기준속도 통과 시간)
```

고도화 후:

```text
추정 저속 시간 = MapKit 예상시간 기반 지연
             + 공공 교통 API 정체 보정
             + 주행 중 실제 속도 기반 보정
```

주의:

- 공공 교통 API의 소통정보는 도로 링크 단위인 경우가 많습니다.
- `MKRoute`와 국가 표준노드링크를 정확히 매칭하려면 별도 지도 매칭 로직이 필요합니다.
- 그래서 실시간 교통 보정은 서버 단계에서 처리하는 편이 맞습니다.

---

## 8. 리스크

기술 리스크:

- `MapKit` 경로와 공공 도로 링크 매칭 난이도 높음
- 공공 API 응답 지연 또는 장애 가능
- 지역별 API 포맷과 갱신주기 차이
- 실시간 재계산이 잦으면 배터리 소모 증가

제품 리스크:

- 사용자가 “진짜 내비게이션”으로 오해할 수 있음
- 예측 요금과 실제 요금 차이가 클 수 있음
- 유료 기능 가치가 단순 예상 요금만으로는 약할 수 있음

완화:

- 기능 문구는 `예상`을 명확히 사용
- 운전 중 조작을 줄이는 UI
- 실시간 비교, 재계산, 재미 문구로 유료 가치 강화
- 서버 장애 시 fallback 명확화

---

## 9. 다음 작업 후보

바로 이어갈 작업:

- MVP UI 빌드 오류 수정
- 목적지 검색 UX 다듬기
- 복수 경로 후보 표시
- 예상 호구비 계산 테스트 확대
- `HoguNavigationSession` 모델 추가

중장기 작업:

- 서버 후보 결정
- ITS/TOPIS API 키 발급
- 교통 API 응답 샘플 수집
- 표준노드링크 매칭 가능성 검증
- StoreKit 유료 잠금 설계
