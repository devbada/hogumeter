# Task 8.7: 마커 애니메이션 (선택)

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.7 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P2 (선택) |
| 상태 | ✅ 구현됨 |
| 의존성 | TASK-8.2 |

---

## 🎯 목표

속도에 따라 말이 달리는 애니메이션을 구현한다. 정지 시 가만히 있고, 이동 시 달리는 모션을 보여준다.
또한 마커의 위치 이동과 방향(heading) 회전이 부드럽게 애니메이션되어야 한다.

---

## 🚀 현재 구현 스펙

### 마커 위치 이동 애니메이션

| 항목 | 값 | 설명 |
|------|-----|------|
| 애니메이션 시간 | 0.3초 | `Constants.Map.markerAnimationDuration` |
| 애니메이션 커브 | easeOut | 자연스러운 감속 |
| GPS 업데이트 간격 | 5m | `Constants.Location.distanceFilter` |

```swift
// MapViewRepresentable.swift
UIView.animate(withDuration: Constants.Map.markerAnimationDuration,
               delay: 0,
               options: [.curveEaseOut, .allowUserInteraction]) {
    existingAnnotation.coordinate = location
}
```

### 마커 회전(Heading) 애니메이션

| 항목 | 값 | 설명 |
|------|-----|------|
| 애니메이션 시간 | 0.3초 | `Constants.Map.headingAnimationDuration` |
| 애니메이션 커브 | easeOut | 자연스러운 감속 |
| 최소 회전 변화량 | 1도 | `Constants.Map.minHeadingChangeForUpdate` |

```swift
// TaxiHorseAnnotationView.swift
func updateHeading(_ heading: Double, animated: Bool = true) {
    let adjustedHeading = heading + 90  // 이모지 방향 보정
    let radians = adjustedHeading * .pi / 180
    let newTransform = CGAffineTransform(rotationAngle: radians)

    if animated {
        UIView.animate(withDuration: Constants.Map.headingAnimationDuration,
                       delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction]) {
            self.emojiLabel.transform = newTransform
        }
    } else {
        emojiLabel.transform = newTransform
    }
}
```

### 속도별 이모지 변경

| 속도 구간 | 이모지 | 설명 |
|----------|--------|------|
| 0 km/h | 💤 | 숨 돌리기 (정지) |
| 0~5 km/h | 🐴 | 걷기 |
| 5~10 km/h | 🐎 | 빠른 걸음 |
| 10~30 km/h | 🏇 | 달리기 |
| 30~100 km/h | 🔥 | 질주본능 발휘 |
| 100+ km/h | 🚀 | 로켓포 발사 |

---

## 📝 구현 내용

### 옵션 A: 이모지 스프라이트 애니메이션

```swift
// Presentation/Views/Map/TaxiHorseAnnotationView.swift 수정

class TaxiHorseAnnotationView: MKAnnotationView {
    // ...

    private var animationTimer: Timer?
    private var currentHorseIndex = 0
    private let horseFrames = ["🐴", "🐎", "🏇"]

    // 속도에 따른 애니메이션
    func updateAnimation(for speed: Double) {
        stopAnimation()

        if speed < 5 {
            // 정지/저속: 애니메이션 없음
            horseLabel.text = "🐴"
        } else if speed < 30 {
            // 중속: 느린 애니메이션
            startAnimation(interval: 0.5)
        } else if speed < 60 {
            // 고속: 빠른 애니메이션
            startAnimation(interval: 0.3)
        } else {
            // 초고속: 매우 빠른 애니메이션
            startAnimation(interval: 0.15)
        }
    }

    private func startAnimation(interval: TimeInterval) {
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentHorseIndex = (self.currentHorseIndex + 1) % self.horseFrames.count
            self.horseLabel.text = self.horseFrames[self.currentHorseIndex]
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    deinit {
        stopAnimation()
    }
}
```

### 옵션 B: UIView 애니메이션 (말 흔들림)

```swift
// TaxiHorseAnnotationView.swift - 흔들림 효과

func updateAnimation(for speed: Double) {
    layer.removeAllAnimations()

    guard speed >= 5 else { return }

    // 속도에 따른 흔들림 강도
    let amplitude: CGFloat = min(speed / 30, 1.0) * 3

    let animation = CABasicAnimation(keyPath: "transform.translation.y")
    animation.fromValue = -amplitude
    animation.toValue = amplitude
    animation.duration = 0.15
    animation.autoreverses = true
    animation.repeatCount = .infinity

    horseLabel.layer.add(animation, forKey: "bounce")
}
```

### 옵션 C: Lottie 애니메이션 (고급)

```swift
// Lottie 사용 시 (SPM으로 추가 필요)
import Lottie

class TaxiHorseAnnotationView: MKAnnotationView {
    private var animationView: LottieAnimationView?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupLottieAnimation()
    }

    private func setupLottieAnimation() {
        let animation = LottieAnimationView(name: "horse_running")
        animation.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        addSubview(animation)
        self.animationView = animation
    }

    func updateAnimation(for speed: Double) {
        if speed < 5 {
            animationView?.stop()
        } else {
            animationView?.animationSpeed = CGFloat(speed / 30)
            animationView?.play()
        }
    }
}
```

### 추가: 먼지 효과 (선택)

```swift
// 고속 주행 시 먼지 파티클 효과

class DustParticleView: UIView {
    private let emitter = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }

    private func setupEmitter() {
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY)
        emitter.emitterSize = CGSize(width: 20, height: 1)

        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "circle.fill")?.cgImage
        cell.birthRate = 5
        cell.lifetime = 0.5
        cell.velocity = 30
        cell.velocityRange = 10
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.scale = 0.1
        cell.scaleRange = 0.05
        cell.alphaSpeed = -2
        cell.color = UIColor.brown.withAlphaComponent(0.5).cgColor

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
    }

    func updateEmission(for speed: Double) {
        emitter.birthRate = speed > 40 ? Float(speed / 10) : 0
    }
}
```

---

## ✅ 수락 기준

- [x] 정지 시 말이 가만히 있음 (💤 이모지)
- [x] 저속 이동 시 천천히 움직이는 애니메이션
- [x] 고속 이동 시 빠르게 달리는 애니메이션
- [x] 애니메이션이 부드럽고 자연스러움 (0.3초 easeOut)
- [x] 배터리 소모 최소화 (5m 간격 업데이트)
- [x] 마커 위치 이동 애니메이션 (UIView.animate)
- [x] 마커 회전(heading) 애니메이션

---

## 📁 수정된 파일

```
HoguMeter/
├── Core/
│   └── Utils/
│       └── Constants.swift  # Map 상수 추가 (markerAnimationDuration 등)
├── Domain/
│   └── Services/
│       └── LocationService.swift  # distanceFilter 5m로 조정
├── Presentation/
│   └── Views/
│       └── Map/
│           ├── MapViewRepresentable.swift  # 마커 위치 애니메이션 적용
│           └── TaxiHorseAnnotationView.swift  # heading 애니메이션 추가
```

---

## 🧪 테스트

1. 정지 상태에서 마커가 고정되어 있는지 확인
2. 저속 이동 시 느린 애니메이션 확인
3. 고속 이동 시 빠른 애니메이션 확인
4. 애니메이션 전환이 자연스러운지 확인
5. 배터리 소모 측정 (Instruments)

---

## 📎 참고

- [Lottie iOS](https://github.com/airbnb/lottie-ios)
- CABasicAnimation
- Timer-based animation
