//
//  HomeService.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation
import Combine

protocol HomeService {
    func getVideos(_ parameter: RequestParameter) -> Future<[VideoModel], Error>
    func searchVideos(_ parameter: RequestParameter) -> Future<[VideoModel], Error>
    func getChannels(_ parameter: RequestParameter) -> Future<[ChannelModel], Error>
}


class HomeServiceImp: HomeService {

    private var cancellables: Set<AnyCancellable> = []

    func getVideos(_ parameter: RequestParameter) -> Future<[VideoModel], Error> {
        return Future<[VideoModel], Error> { promise in
            NetworkManager.shared.processData(endpoint: .getMostPopular,
                                              queryParameter: parameter,
                                              type: ResponseModel<[VideoResponseModel]>.self)
            
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    promise(.failure(error))
                }
            } receiveValue: { response in
                guard let data = response.data else { return }
                let videos = data.map {
                    var data = $0.data
                    data.viewCount = $0.statistics?.viewCount
                    data.id = $0.id
                    data.pageToken = response.nextPageToken
                    return data
                }
                promise(.success(videos))
            }.store(in: &self.cancellables)
        }
    }

    func searchVideos(_ parameter: RequestParameter) -> Future<[VideoModel], Error> {
        return Future<[VideoModel], Error> { promise in
            NetworkManager.shared.processData(endpoint: .searchVideos,
                                              queryParameter: parameter,
                                              type: ResponseModel<[VideoResponseModel]>.self)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    guard let data = response.data, !data.isEmpty else {
                        promise(.failure(CustomError.empty))
                        return
                    }
                    let videos = data.map {
                        var data = $0.data
                        data.viewCount = $0.statistics?.viewCount
                        data.id = $0.id
                        data.pageToken = response.nextPageToken
                        return data
                    }
                    promise(.success(videos))
                }.store(in: &self.cancellables)
        }
    }

    func getChannels(_ parameter: RequestParameter) -> Future<[ChannelModel], Error> {
        return Future<[ChannelModel], Error> { promise in
            NetworkManager.shared.processData(endpoint: .getChannels,
                                              queryParameter: parameter,
                                              type: ResponseModel<[ChannelResponseModel]>.self)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    guard let data = response.data else { return }
                    let channels = data.map {
                        var data = $0.data
                        data.id = $0.id
                        return data
                    }
                    promise(.success(channels))
                }.store(in: &self.cancellables)
        }
    }
}
