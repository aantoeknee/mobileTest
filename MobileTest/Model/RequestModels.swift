//
//  RequestModels.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation

struct RequestModel: Encodable {
    var id: String?
    var part: String?
    var chart: String?
    var regionCode: String?
    var q: String?
    var maxResults: Int?
    var type: String?
    var pageToken: String?
    var order: String?
    var videoId: String?
    var key: String?

    func generateParameter() -> [String: Any] {
        return self.dictionary ?? [:]
    }
}
