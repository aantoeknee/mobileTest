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

    private enum Constants {
        static let maxResults: Int = 10
    }
     
    enum Input {
        case fetchData(isForce: Bool)
        case fetchSearch(String)
        case cancelSearch
        case goToDetails(Int)
        case loadMore
    }
    enum Output {
        case fetchDataSuccess([VideoModel])
        case fetchSearchDataSuccess([VideoModel])
        case scrollToTop
        case showLoading(Bool, String? = nil)
        case showError(String)
    }

    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables: Set<AnyCancellable> = []
    private let service: HomeService
    private var coordinator: HomeCoordinator
    private var isSearchState: Bool = false
    private var currentPageToken: String = .empty
    private var videoModels: [VideoModel] = []
    private var keyword: String = .empty

    init(service: HomeService = HomeServiceImp(),
         coordinator: HomeCoordinator) {
        self.service = service
        self.coordinator = coordinator
    }

    func bind(_ input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .fetchData(let isForce):
                if self.isSearchState {
                    self.handleSearch()
                } else {
                    self.getMostPopular(isForce)
                }
            case .fetchSearch(let keyword):
                self.keyword = keyword
                self.handleSearch()
            case .cancelSearch:
                self.isSearchState = false
                self.getMostPopular(true)
            case .goToDetails(let index):
                let model = self.videoModels[index]
                self.coordinator.goToDetails(model)
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

    private func handleSearch() {
        self.videoModels.removeAll()
        self.isSearchState = true
        self.getSearch(keyword: self.keyword)
    }

    private func getMostPopular(_ isForce: Bool = false) {

        let requestParam = RequestModel(
            part: "snippet%2Cstatistics",
            chart: "mostPopular",
            regionCode: "PH",
            maxResults: Constants.maxResults,
            type: "video",
            key: GlobalConstant.apiKey
        )
        if isForce {
            videoModels.removeAll()
            isSearchState = false
        }
        output.send(.showLoading(!isForce))
        service.getVideos(requestParam.generateParameter())
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.currentPageToken = data.first?.pageToken ?? .empty
                self.retrieveChannelInfo(data)
            }.store(in: &cancellables)
    }

    private func retrieveChannelInfo(_ videoModels: [VideoModel]) {
        let group = DispatchGroup()
        videoModels.forEach { videoModel in
            group.enter()
            let requestParam = RequestModel(
                id: videoModel.channelId,
                part: "snippet%2Cstatistics",
                key: GlobalConstant.apiKey
            )
            service.getChannels(requestParam.generateParameter())
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
                    tempVideo.subscribers = channels.first?.statistics?.subscriberCount
                    self.videoModels.append(tempVideo)
                }.store(in: &cancellables)
        }
        group.notify(queue: .main) {
            self.output.send(.fetchDataSuccess(self.videoModels))
        }
    }

    private func getSearch(keyword: String, pageToken: String = .empty) {
        let requestParam = RequestModel(
            part: "snippet",
            regionCode: "PH",
            q: keyword,
            maxResults: Constants.maxResults,
            type: "video",
            pageToken: pageToken,
            key: GlobalConstant.apiKey
        )

        if pageToken.isEmpty {
            self.output.send(.scrollToTop)
            output.send(.showLoading(true))
        } else {
            output.send(.showLoading(true, "Loading more..."))
        }
        service.searchVideos(requestParam.generateParameter())
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { data in
                self.currentPageToken = data.first?.pageToken ?? .empty
                self.retrieveStatistics(videoModels: data)
            }.store(in: &cancellables)
    }

    private func retrieveStatistics(videoModels: [VideoModel]) {
        let group = DispatchGroup()

        videoModels.forEach {
            group.enter()

            let videoParameter = RequestModel(
                id: $0.id ?? .empty,
                part: "snippet%2Cstatistics",
                key: GlobalConstant.apiKey
            )

            let channelParameter = RequestModel(
                id: $0.channelId,
                part: "snippet%2Cstatistics",
                key: GlobalConstant.apiKey
            )

            let getVideoPublisher = service.getVideos(videoParameter.generateParameter()).eraseToAnyPublisher()
            let getChannelPublisher = service.getChannels(channelParameter.generateParameter()).eraseToAnyPublisher()

            Publishers.Zip(getVideoPublisher, getChannelPublisher)
                .sink { [weak self] completion in
                    guard let self = self else { return }
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
                            tempVideos[index].subscribers = channels.first?.statistics?.subscriberCount
                        }
                    }
                    self.videoModels.append(contentsOf: tempVideos)
                }.store(in: &cancellables)
        }
        group.notify(queue: .main) {
            self.output.send(.showLoading(false))
            self.output.send(.fetchSearchDataSuccess(self.videoModels))
        }
    }

    private func loadMore() {
        if isSearchState {
            getSearch(keyword: keyword, pageToken: currentPageToken)
        } else {
            let parameter = RequestModel(
                part: "snippet%2Cstatistics",
                chart: "mostPopular",
                regionCode: "PH",
                maxResults: Constants.maxResults,
                type: "video",
                pageToken: currentPageToken,
                key: GlobalConstant.apiKey
            )

            output.send(.showLoading(true, "Loading more..."))
            service.getVideos(parameter.generateParameter())
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.output.send(.showError(error.localizedDescription))
                    }
                } receiveValue: { data in
                    self.currentPageToken = data.first?.pageToken ?? .empty
                    self.retrieveChannelInfo(data)
                }.store(in: &cancellables)
        }
    }
}

