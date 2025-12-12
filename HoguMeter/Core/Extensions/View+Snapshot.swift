//
//  View+Snapshot.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI
import UIKit

extension View {
    /// View를 UIImage로 캡처합니다.
    @MainActor
    func snapshot(size: CGSize = CGSize(width: 350, height: 600)) -> UIImage {
        let controller = UIHostingController(rootView: self)

        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .white

        // 윈도우에 추가하여 렌더링 강제
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(controller.view)
            controller.view.layoutIfNeeded()
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }

        controller.view.removeFromSuperview()
        return image
    }
}
