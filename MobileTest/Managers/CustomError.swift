//
//  CustomError.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation

enum CustomError: Error {
    case unknown
    case empty
    case errorWithMessage(String)
}

extension CustomError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .errorWithMessage(let message):
            return NSLocalizedString(message, comment: "My error")
        case .empty:
            return NSLocalizedString("No results found.", comment: "My error")
        case .unknown:
            return NSLocalizedString("Something went wrong", comment: "My error")
        }
    }
}

