# Task 8.2: 커스텀 마커 (택시+말)

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.2 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P0 |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1 |

---

## 🎯 목표

현재 위치를 "택시+말" 커스텀 아이콘으로 표시한다. 마커가 GPS 위치에 실시간으로 업데이트되고, 이동 방향에 따라 회전한다.

---

## 📝 구현 내용

### 1. TaxiHorseAnnotation 정의

```swift
// Domain/Entities/TaxiHorseAnnotation.swift

import MapKit

class TaxiHorseAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var heading: Double // 진행 방향 (0-360도)
    var speed: Double   // 속도 (km/h)

    init(coordinate: CLLocationCoordinate2D, heading: Double = 0, speed: Double = 0) {
        self.coordinate = coordinate
        self.heading = heading
        self.speed = speed
        super.init()
    }

    func update(coordinate: CLLocationCoordinate2D, heading: Double, speed: Double) {
        self.coordinate = coordinate
        self.heading = heading
        self.speed = speed
    }
}
```

### 2. TaxiHorseAnnotationView 구현

```swift
// Presentation/Views/Map/TaxiHorseAnnotationView.swift

import MapKit

class TaxiHorseAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "TaxiHorseAnnotation"

    private let containerView = UIView()
    private let horseLabel = UILabel()
    private let taxiLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        frame = CGRect(x: 0, y: 0, width: 60, height: 70)
        centerOffset = CGPoint(x: 0, y: -35)
        backgroundColor = .clear

        // 말 이모지
        horseLabel.text = "🐴"
        horseLabel.font = .systemFont(ofSize: 30)
        horseLabel.textAlignment = .center
        horseLabel.frame = CGRect(x: 10, y: 0, width: 40, height: 35)

        // 택시 이모지
        taxiLabel.text = "🚕"
        taxiLabel.font = .systemFont(ofSize: 30)
        taxiLabel.textAlignment = .center
        taxiLabel.frame = CGRect(x: 10, y: 25, width: 40, height: 35)

        containerView.frame = bounds
        containerView.addSubview(horseLabel)
        containerView.addSubview(taxiLabel)
        addSubview(containerView)
    }

    func updateHeading(_ heading: Double) {
        // 진행 방향으로 회전 (북쪽 = 0도)
        let radians = heading * .pi / 180
        containerView.transform = CGAffineTransform(rotationAngle: radians)
    }

    func updateSpeed(_ speed: Double) {
        // 속도에 따라 말 이모지 변경
        if speed > 60 {
            horseLabel.text = "🏇" // 빠른 속도
        } else if speed > 30 {
            horseLabel.text = "🐎" // 중간 속도
        } else {
            horseLabel.text = "🐴" // 느린 속도/정지
        }
    }
}
```

### 3. MapViewRepresentable에 마커 연동

```swift
// MapViewRepresentable.swift 업데이트

func updateUIView(_ mapView: MKMapView, context: Context) {
    // 기존 코드...

    // 마커 업데이트
    updateAnnotation(mapView)
}

private func updateAnnotation(_ mapView: MKMapView) {
    guard let location = viewModel.currentLocation else { return }

    if let existingAnnotation = mapView.annotations.first(where: { $0 is TaxiHorseAnnotation }) as? TaxiHorseAnnotation {
        // 기존 마커 업데이트
        UIView.animate(withDuration: 0.3) {
            existingAnnotation.update(
                coordinate: location,
                heading: self.viewModel.currentHeading,
                speed: self.viewModel.currentSpeed
            )
        }
    } else {
        // 새 마커 추가
        let annotation = TaxiHorseAnnotation(
            coordinate: location,
            heading: viewModel.currentHeading,
            speed: viewModel.currentSpeed
        )
        mapView.addAnnotation(annotation)
    }
}

// Coordinator 델리게이트 메서드
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is TaxiHorseAnnotation else { return nil }

    let view = mapView.dequeueReusableAnnotationView(
        withIdentifier: TaxiHorseAnnotationView.reuseIdentifier
    ) as? TaxiHorseAnnotationView ?? TaxiHorseAnnotationView(
        annotation: annotation,
        reuseIdentifier: TaxiHorseAnnotationView.reuseIdentifier
    )

    view.annotation = annotation
    return view
}
```

### 4. MapViewModel에 속도 추가

```swift
// MapViewModel.swift 추가

@Published var currentSpeed: Double = 0

private func updateLocation(_ location: CLLocation) {
    currentLocation = location.coordinate
    currentHeading = location.course >= 0 ? location.course : currentHeading
    currentSpeed = max(0, location.speed * 3.6) // m/s -> km/h
}
```

---

## ✅ 수락 기준

- [ ] 🚕🐴 형태의 커스텀 마커가 지도에 표시됨
- [ ] 마커가 현재 GPS 위치에 실시간 업데이트됨
- [ ] 이동 방향에 따라 마커가 회전함
- [ ] 마커 이동이 부드럽게 애니메이션됨
- [ ] 속도에 따라 말 이모지가 변경됨 (🐴 → 🐎 → 🏇)

---

## 📁 생성할 파일

```
HoguMeter/
├── Domain/
│   └── Entities/
│       └── TaxiHorseAnnotation.swift
├── Presentation/
│   └── Views/
│       └── Map/
│           └── TaxiHorseAnnotationView.swift
```

---

## 🧪 테스트

1. 지도 화면 진입 시 마커가 현재 위치에 표시되는지 확인
2. 시뮬레이터에서 위치 시뮬레이션으로 이동 테스트
3. 마커가 이동 방향으로 회전하는지 확인
4. 속도에 따라 말 이모지가 변경되는지 확인

---

## 📎 참고

- [MKAnnotationView](https://developer.apple.com/documentation/mapkit/mkannotationview)
- [Custom Annotations](https://developer.apple.com/documentation/mapkit/mkannotation)
