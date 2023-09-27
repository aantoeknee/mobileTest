//
//  IntExtensions.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation
import UIKit

extension Double {
    func reduceScale(to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = Double(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
}

extension Int {

    func getFormattedString(_ suffix: String) -> String {
        let num = abs(Double(self))
        let sign = self < 0 ? "-" : ""

        switch num {
        case 1_000_000_000...:
            return "\(sign)\((num / 1_000_000_000).reduceScale(to: 1))B \(suffix)"
        case 1_000_000...:
            return "\(sign)\((num / 1_000_000).reduceScale(to: 1))M \(suffix)"
        case 1_000...:
            return "\(sign)\((num / 1_000).reduceScale(to: 1))K \(suffix)"
        case 0...:
            return "\(self) \(suffix)"
        default:
            return "\(sign)\(self) \(suffix)"
        }
    }
}
