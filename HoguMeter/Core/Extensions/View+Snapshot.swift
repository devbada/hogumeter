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
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
