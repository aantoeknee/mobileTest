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
    case getComments

    var urlString: String {
        switch self {
        case .searchVideos:
            return "https://youtube.googleapis.com/youtube/v3/search"
        case .getMostPopular:
            return "https://youtube.googleapis.com/youtube/v3/videos"
        case .getChannels:
            return "https://youtube.googleapis.com/youtube/v3/channels"
        case .getComments:
            return "https://youtube.googleapis.com/youtube/v3/commentThreads"
        }
    }
}
