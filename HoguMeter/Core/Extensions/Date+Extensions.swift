//
//  Date+Extensions.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

extension Date {

    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func formattedDateTime() -> String {
        formatted(as: "yyyy-MM-dd HH:mm:ss")
    }

    func formattedDate() -> String {
        formatted(as: "yyyy-MM-dd")
    }

    func formattedTime() -> String {
        formatted(as: "HH:mm")
    }
}
