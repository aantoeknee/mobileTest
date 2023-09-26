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
        case fetchData
        case fetchSearch(String)
    }
    enum Output {
        case fetchDataSuccess([VideoModel])
        case fetchSearchDataSuccess([VideoModel])
        case showLoading(Bool)
        case showError(String)
    }

    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables: Set<AnyCancellable> = []
    private let service: HomeService

    init(service: HomeService = HomeServiceImp()) {
        self.service = service
    }

    func bind(_ input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .fetchData:
                self.getMostPopular()
            case .fetchSearch(let keyword):
                self.getSearch(keyword: keyword)

            }
        }
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}

// MARK: - Private Functions
extension HomeViewModelImp {

    private func getMostPopular() {
        let parameter: RequestParameter = [
            "part": "snippet%2Cstatistics",
            "chart": "mostPopular",
            "regionCode": "PH",
            "maxResults": 5,
            "type": "video",
            "key": HomeServiceImp.Constants.apiKey
        ]

        output.send(.showLoading(true))
        service.getVideos(parameter)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.output.send(.showLoading(false))
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.retrieveChannelInfo(data)
            }.store(in: &cancellables)
    }

    private func retrieveChannelInfo(_ videoModels: [VideoModel]) {
        var models: [VideoModel] = []
        videoModels.forEach { videoModel in
            let channelParameter: RequestParameter = [
                "part": "snippet",
                "id": videoModel.channelId,
                "key": HomeServiceImp.Constants.apiKey
            ]
            service.getChannels(channelParameter)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    self.output.send(.showLoading(false))
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.output.send(.showError(error.localizedDescription))
                    }
                } receiveValue: { channels in
                    var tempVideo = videoModel
                    tempVideo.channelIcon = channels.first?.thumbnails?.high?.url
                    models.append(tempVideo)
                    self.output.send(.fetchDataSuccess(models))
                }.store(in: &cancellables)
        }
    }

    private func getSearch(keyword: String) {
        let parameter: RequestParameter = [
            "part": "snippet",
            "regionCode": "PH",
            "q": keyword,
            "maxResults": 5,
            "type": "video",
            "key": HomeServiceImp.Constants.apiKey
        ]
        output.send(.showLoading(true))
        service.searchVideos(parameter)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.output.send(.showLoading(false))
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.retrieveStatistics(videoModels: data)
            }.store(in: &cancellables)
    }

    private func retrieveStatistics(videoModels: [VideoModel]) {
        var models: [VideoModel] = []
        videoModels.forEach {
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
                    switch completion {
                    case .finished:
                        print("finished")
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
                    models.append(contentsOf: tempVideos)
                    self.output.send(.fetchSearchDataSuccess(models))
                }.store(in: &cancellables)
        }
    }
}

