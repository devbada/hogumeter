# Task 4.4: 영수증 지도 캡처 기능

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-4.4 |
| Epic | Epic 4 - 영수증/공유 |
| 우선순위 | P1 (Should) |
| 상태 | ✅ 구현됨 |
| 의존성 | TASK-4.1, TASK-8.3 |

---

## 🎯 목표

주행 종료 시 전체 경로가 포함된 지도 스냅샷을 캡처하여 영수증에 표시한다.
지도 타일과 폴리라인(경로)이 함께 포함된 이미지를 생성한다.

---

## 🚀 구현 스펙

### 지도 스냅샷 생성

| 항목 | 값 | 설명 |
|------|-----|------|
| 스냅샷 크기 | 600x300 pt | 2x 스케일로 고해상도 |
| 여백 비율 | 20% | 경로 주변 여백 |
| 폴리라인 두께 | 4pt | 경로선 굵기 |
| 폴리라인 색상 | systemBlue | 파란색 경로 |
| 출발 마커 | 녹색 원 (12pt) | 시작점 표시 |
| 도착 마커 | 빨간색 원 (12pt) | 종료점 표시 |

### 데이터 저장

| 항목 | 타입 | 설명 |
|------|------|------|
| mapImageData | Data? | JPEG 압축 이미지 (80% 품질) |
| 저장 위치 | Trip 엔티티 | Codable로 저장 |

---

## 📝 상세 구현

### 1. MapSnapshotGenerator 서비스

```swift
// Domain/Services/MapSnapshotGenerator.swift

class MapSnapshotGenerator {
    /// 경로가 포함된 지도 스냅샷 생성
    static func generateSnapshot(
        routePoints: [RoutePoint],
        size: CGSize = CGSize(width: 600, height: 300)
    ) async -> UIImage?

    /// 스냅샷 이미지 위에 폴리라인 그리기
    private static func drawPolyline(
        on image: UIImage,
        routePoints: [RoutePoint],
        snapshot: MKMapSnapshotter.Snapshot
    ) -> UIImage
}
```

### 2. Trip 엔티티 확장

```swift
struct Trip: Identifiable, Codable {
    // 기존 필드...
    let mapImageData: Data?  // 지도 스냅샷 이미지
}
```

### 3. 주행 종료 시 캡처 흐름

```
stopMeter()
  → saveTrip()
    → MapSnapshotGenerator.generateSnapshot()
    → Trip(mapImageData: imageData)
    → tripRepository.save(trip)
    → completedTrip = trip
```

### 4. 영수증 표시

```swift
// ReceiptView.swift
if let imageData = trip.mapImageData,
   let image = UIImage(data: imageData) {
    Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

---

## ✅ 수락 기준

- [x] 주행 종료 시 지도 스냅샷 자동 캡처
- [x] 스냅샷에 폴리라인(경로) 포함
- [x] 출발/도착 마커 표시
- [x] Trip 엔티티에 이미지 데이터 저장
- [x] 영수증에서 저장된 지도 이미지 표시
- [x] 이미지가 없는 경우 폴백 처리

---

## 📁 수정/생성 파일

```
HoguMeter/
├── Domain/
│   ├── Entities/
│   │   └── Trip.swift  # mapImageData 필드 추가
│   └── Services/
│       └── MapSnapshotGenerator.swift  # 신규 생성
├── Presentation/
│   ├── ViewModels/
│   │   └── MeterViewModel.swift  # 종료 시 캡처 로직
│   └── Views/
│       └── Receipt/
│           └── ReceiptView.swift  # 저장된 이미지 표시
```

---

## 🧪 테스트

1. 주행 시작 → 이동 → 종료
2. 영수증에서 지도 이미지 확인
3. 지도에 경로(파란선), 출발(녹색), 도착(빨간색) 마커 확인
4. 사진첩 저장 시 지도 포함 확인
5. routePoints가 없는 경우 폴백 확인

---

## 📎 참고

- MKMapSnapshotter: 비동기 지도 스냅샷 생성
- UIGraphicsImageRenderer: 이미지 위에 그래픽 그리기
- JPEG 압축으로 저장 용량 최적화
