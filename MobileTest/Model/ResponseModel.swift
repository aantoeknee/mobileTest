//
//  ResponseModel.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation

struct ResponseModel<T: Codable>: Codable {
    let data: T?
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case data = "items"
        case nextPageToken
    }
}
