//
//  Endpoints.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation

enum Endpoint {
    case searchVideos
    case getMostPopular
    case getChannels

    var urlString: String {
        switch self {
        case .searchVideos:
            return "https://youtube.googleapis.com/youtube/v3/search"
        case .getMostPopular:
            return "https://youtube.googleapis.com/youtube/v3/videos"
        case .getChannels:
            return "https://youtube.googleapis.com/youtube/v3/channels"
        }
    }
}
