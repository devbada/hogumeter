//
//  PaginationConfig.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation

/// Configuration for trip history pagination
enum PaginationConfig {
    /// Number of items per page
    static let pageSize: Int = 20

    /// Number of items from end to trigger prefetch
    static let prefetchThreshold: Int = 5
}
