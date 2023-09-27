//
//  HomeCellViewModel.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation

protocol HomeCellViewModel {
    var title: String? { get }
    var channel: String? { get }
    var viewCount: String? { get }
    var thumbnail: URL? { get }
    var channelIcon: URL? { get }
}

class HomeCellViewModelImp: HomeCellViewModel {

    private var model: VideoModel? = nil

    init(model: VideoModel) {
        self.model = model
    }

    var title: String? {
        return model?.title
    }

    var channel: String? {
        return model?.channelTitle.truncated(limit: 20)
    }

    var viewCount: String? {
        guard let formattedString = Int(
            model?.viewCount ?? .empty
        )?.getFormattedString("views") else {
            return .empty
        }

        return formattedString
    }

    var thumbnail: URL? {
        guard let thumbnail = model?.thumbnails.high?.url,
              let url = URL(string: thumbnail) else {
            return nil
        }
        return url
    }

    var channelIcon: URL? {
        guard let channelIcon = model?.channelIcon,
              let url = URL(string: channelIcon) else {
            return nil
        }
        return url
    }
}
