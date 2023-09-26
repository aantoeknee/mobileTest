//
//  HomeModel.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation

struct VideoResponseModel: Codable {
    let data: VideoModel
    let statistics: VideoStatistics?
    let id: String?

    enum CodingKeys: String, CodingKey {
        case data = "snippet"
        case statistics
        case id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(VideoModel.self, forKey: .data)
        self.statistics = try container.decodeIfPresent(VideoStatistics.self, forKey: .statistics)
        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? container.decode(VideoId.self, forKey: .id).videoId {
            self.id = id
        } else {
            self.id = nil
        }
    }
}

struct VideoId: Codable {
    let videoId: String?
}

struct VideoStatistics: Codable {
    let viewCount: String?
}

struct VideoModel: Codable {
    let title: String
    let channelId: String
    let description: String
    let channelTitle: String
    let thumbnails: VideoThumbnail
    var viewCount: String?
    var id: String?
    var channelIcon: String?
}

struct VideoThumbnail: Codable {
    let `default`: VideoThumbnailInfo?
    let medium: VideoThumbnailInfo?
    let high: VideoThumbnailInfo?
    let standard: VideoThumbnailInfo?
    let maxres: VideoThumbnailInfo?
}

struct VideoThumbnailInfo: Codable {
    let url: String?
}


struct ChannelResponseModel: Codable {
    let data: ChannelModel
    let id: String

    enum CodingKeys: String, CodingKey {
        case data = "snippet"
        case id
    }
}

struct ChannelModel: Codable {
    let title: String?
    let thumbnails: VideoThumbnail?
    var id: String?
}
