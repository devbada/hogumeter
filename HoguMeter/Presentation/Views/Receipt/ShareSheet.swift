//
//  ShareSheet.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI
import UIKit

/// iOS Share Sheet (UIActivityViewController) 래퍼
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
