//
//  TaxiHorseAnnotationView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

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
