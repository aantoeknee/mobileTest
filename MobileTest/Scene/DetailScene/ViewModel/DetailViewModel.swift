//
//  DetailViewModel.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Combine
import Foundation

protocol DetailViewModel {
    func bind(
        _ input: AnyPublisher<DetailViewModelImp.Input, Never>
    ) -> AnyPublisher<DetailViewModelImp.Output, Never>
}


class DetailViewModelImp: DetailViewModel {

    private enum Constants {
        static let maxResults: Int = 30
    }

    enum Input {
        case requestViewState
        case loadMore
    }
    enum Output {
        case presentViewState(VideoModel)
        case presentComments([CommentModel])
        case showLoading(Bool, String? = nil)
        case showError(String)
    }

    private var currentPageToken: String = .empty
    private var cancellables: Set<AnyCancellable> = []
    private let output: PassthroughSubject<Output, Never> = .init()
    private let model: VideoModel
    private let service: DetailService
    private var comments: [CommentModel] = []

    init(model: VideoModel, service: DetailService = DetailServiceImp()) {
        self.model = model
        self.service = service
    }

    func bind(_ input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .requestViewState:
                self.output.send(.presentViewState(self.model))
                self.getComments()
            case .loadMore:
                if !self.currentPageToken.isEmpty {
                    self.loadMore()
                }
            }
        }
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}

// MARK: - Private Functions
extension DetailViewModelImp {

    private func getComments() {
        self.comments.removeAll()
        let parameter = RequestModel(
            part: "snippet",
            maxResults: Constants.maxResults,
            videoId: model.id,
            key: GlobalConstant.apiKey
        )
        output.send(.showLoading(true))
        service.getComments(parameter.generateParameter())
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.output.send(.showLoading(false))
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { comments in
                self.currentPageToken = comments.first?.pageToken ?? .empty
                self.comments = comments
                self.output.send(.presentComments(comments))
            }.store(in: &cancellables)

    }

    private func loadMore() {
        let parameter = RequestModel(
            part: "snippet",
            maxResults: Constants.maxResults,
            pageToken: currentPageToken,
            videoId: model.id,
            key: GlobalConstant.apiKey
        )

        service.getComments(parameter.generateParameter())
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.output.send(.showLoading(false))
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.output.send(.showError(error.localizedDescription))
                }
            } receiveValue: { comments in
                self.currentPageToken = comments.first?.pageToken ?? .empty
                self.comments.append(contentsOf: comments)
                self.output.send(.presentComments(self.comments))
            }.store(in: &cancellables)

    }
}
