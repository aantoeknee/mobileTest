//
//  HomeViewModel.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Combine
import Foundation

protocol HomeViewModel {
    func bind(_ input: AnyPublisher<HomeViewModelImp.Input, Never>) -> AnyPublisher<HomeViewModelImp.Output, Never>
}

class HomeViewModelImp: HomeViewModel {
    enum Input {
        case fetchData(isForce: Bool)
        case fetchSearch(String)
        case loadMore
    }
    enum Output {
        case fetchDataSuccess([VideoModel], isForce: Bool)
        case fetchSearchDataSuccess([VideoModel], isForce: Bool)
        case showLoading(Bool)
        case showError(String)
    }

    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables: Set<AnyCancellable> = []
    private let service: HomeService
    private var isSearchState: Bool = false
    private var currentPageToken: String = .empty
    private var videoModels: [VideoModel] = []
    private var keyword: String = .empty

    init(service: HomeService = HomeServiceImp()) {
        self.service = service
    }

    func bind(_ input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .fetchData(let showLoader):
                self.getMostPopular(showLoader)
            case .fetchSearch(let keyword):
                self.videoModels.removeAll()
                self.keyword = keyword
                self.isSearchState = true
                self.getSearch(keyword: keyword)
            case .loadMore:
                self.loadMore()
            }
        }
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}

// MARK: - Private Functions
extension HomeViewModelImp {

    private func getMostPopular(_ isForce: Bool = false) {
        let parameter: RequestParameter = [
            "part": "snippet%2Cstatistics",
            "chart": "mostPopular",
            "regionCode": "PH",
            "maxResults": 5,
            "type": "video",
            "key": HomeServiceImp.Constants.apiKey
        ]
        if isForce {
            self.videoModels.removeAll()
            self.isSearchState = false
        }
        output.send(.showLoading(!isForce))
        service.getVideos(parameter)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.currentPageToken = data.first?.pageToken ?? .empty
                self.retrieveChannelInfo(data, isForce: isForce)
            }.store(in: &cancellables)
    }

    private func retrieveChannelInfo(_ videoModels: [VideoModel], isForce: Bool) {
        let group = DispatchGroup()
        videoModels.forEach { videoModel in
            group.enter()
            let channelParameter: RequestParameter = [
                "part": "snippet",
                "id": videoModel.channelId,
                "key": HomeServiceImp.Constants.apiKey
            ]
            service.getChannels(channelParameter)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    self.output.send(.showLoading(false))
                    group.leave()
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.output.send(.showError(error.localizedDescription))
                    }
                } receiveValue: { channels in
                    var tempVideo = videoModel
                    tempVideo.channelIcon = channels.first?.thumbnails?.high?.url
                    self.videoModels.append(tempVideo)
                }.store(in: &cancellables)
        }
        group.notify(queue: .main) {
            self.output.send(.fetchDataSuccess(self.videoModels, isForce: isForce))
        }
    }

    private func getSearch(keyword: String, pageToken: String = .empty) {
        let parameter: RequestParameter = [
            "part": "snippet",
            "regionCode": "PH",
            "q": keyword,
            "maxResults": 5,
            "type": "video",
            "pageToken": pageToken,
            "key": HomeServiceImp.Constants.apiKey
        ]
        output.send(.showLoading(true))
        service.searchVideos(parameter)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.currentPageToken = data.first?.pageToken ?? .empty
                self.retrieveStatistics(videoModels: data, isForce: pageToken.isEmpty)
            }.store(in: &cancellables)
    }

    private func retrieveStatistics(videoModels: [VideoModel], isForce: Bool) {
        let group = DispatchGroup()

        videoModels.forEach {
            group.enter()
            let parameter: RequestParameter = [
                "part": "snippet%2Cstatistics",
                "id": $0.id ?? .empty,
                "key": HomeServiceImp.Constants.apiKey
            ]

            let channelParameter: RequestParameter = [
                "part": "snippet",
                "id": $0.channelId,
                "key": HomeServiceImp.Constants.apiKey
            ]

            let getVideoPublisher = service.getVideos(parameter).eraseToAnyPublisher()
            let getChannelPublisher = service.getChannels(channelParameter).eraseToAnyPublisher()

            Publishers.Zip(getVideoPublisher, getChannelPublisher)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    self.output.send(.showLoading(false))
                    group.leave()
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.output.send(.showError(error.localizedDescription))
                    }
                } receiveValue: { videos, channels in
                    var tempVideos = videos
                    for (index, item) in tempVideos.enumerated() {
                        if let icon = channels.first(where: { channel in
                            channel.id == item.channelId
                        })?.thumbnails?.high {
                            tempVideos[index].channelIcon = icon.url
                        }
                    }
                    self.videoModels.append(contentsOf: tempVideos)
                }.store(in: &cancellables)
        }
        group.notify(queue: .main) {
            self.output.send(.fetchSearchDataSuccess(self.videoModels, isForce: isForce))
        }
    }

    private func loadMore() {
        if isSearchState {
            getSearch(keyword: keyword, pageToken: currentPageToken)
        } else {
            let parameter: RequestParameter = [
                "part": "snippet%2Cstatistics",
                "chart": "mostPopular",
                "regionCode": "PH",
                "maxResults": 5,
                "type": "video",
                "pageToken": currentPageToken,
                "key": HomeServiceImp.Constants.apiKey
            ]
            output.send(.showLoading(true))
            service.getVideos(parameter)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.output.send(.showError(error.localizedDescription))
                    }
                } receiveValue: { data in
                    self.currentPageToken = data.first?.pageToken ?? .empty
                    self.retrieveChannelInfo(data, isForce: false)
                }.store(in: &cancellables)
        }
    }
}

