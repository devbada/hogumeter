//
//  View+Snapshot.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI
import UIKit

extension View {
    /// View를 UIImage로 캡처합니다. (iOS 16+ ImageRenderer 사용)
    @MainActor
    func snapshot(size: CGSize = CGSize(width: 375, height: 600)) -> UIImage {
        // iOS 16+ ImageRenderer 사용 (훨씬 빠름)
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = 2.0  // @2x Retina

        if let image = renderer.uiImage {
            return image
        }

        // Fallback: 빈 이미지 반환
        return UIImage()
    }
}
