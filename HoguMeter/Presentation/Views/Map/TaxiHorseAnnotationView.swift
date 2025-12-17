//
//  TaxiHorseAnnotationView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import MapKit

class TaxiHorseAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "TaxiHorseAnnotation"

    private let emojiLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let size: CGFloat = 44
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = .zero  // 정확히 좌표 위치에 표시
        backgroundColor = .clear

        // 택시 이모지 (heading 방향으로 회전)
        emojiLabel.text = "🚕"
        emojiLabel.font = .systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        emojiLabel.frame = bounds
        addSubview(emojiLabel)
    }

    func updateHeading(_ heading: Double, animated: Bool = true) {
        // 이모지가 heading 방향을 바라보도록 회전
        // 🚕 이모지는 기본적으로 왼쪽(서쪽, 270도)을 바라봄
        // heading 0도 = 북쪽이므로, 이모지가 북쪽을 바라보려면 +90도 보정 필요
        let adjustedHeading = heading + 90
        let radians = adjustedHeading * .pi / 180
        let newTransform = CGAffineTransform(rotationAngle: radians)

        if animated {
            UIView.animate(withDuration: Constants.Map.headingAnimationDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.emojiLabel.transform = newTransform
            }
        } else {
            emojiLabel.transform = newTransform
        }
    }

    func updateSpeed(_ speed: Double) {
        // HorseSpeed 기준에 맞춰 이모지 변경
        switch speed {
        case 0:
            emojiLabel.text = "💤"   // 숨 돌리기 (정지)
        case 0..<5:
            emojiLabel.text = "🐴"   // 걷기
        case 5..<10:
            emojiLabel.text = "🐎"   // 빠른 걸음
        case 10..<30:
            emojiLabel.text = "🏇"   // 달리기
        case 30..<100:
            emojiLabel.text = "🔥"   // 질주본능 발휘
        default:
            emojiLabel.text = "🚀"   // 로켓포 발사 (100km/h+)
        }
    }
}
