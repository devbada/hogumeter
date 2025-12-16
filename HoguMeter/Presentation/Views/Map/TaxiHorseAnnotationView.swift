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

    func updateHeading(_ heading: Double) {
        // 이모지가 heading 방향을 바라보도록 회전
        // 🚕 이모지는 기본적으로 왼쪽(서쪽, 270도)을 바라봄
        // heading 0도 = 북쪽이므로, 이모지가 북쪽을 바라보려면 +90도 보정 필요
        let adjustedHeading = heading + 90
        let radians = adjustedHeading * .pi / 180
        emojiLabel.transform = CGAffineTransform(rotationAngle: radians)
    }

    func updateSpeed(_ speed: Double) {
        // 속도에 따라 이모지 변경
        if speed > 80 {
            emojiLabel.text = "🏎️"  // 초고속
        } else if speed > 60 {
            emojiLabel.text = "🚗"  // 빠른 속도
        } else {
            emojiLabel.text = "🚕"  // 일반 속도
        }
    }
}
