//
//  DetailService.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation
import Combine

protocol DetailService {
    func getComments(
        _ parameter: RequestParameter
    ) -> Future<[CommentModel], Error>
}

class DetailServiceImp: DetailService {
    private var cancellables: Set<AnyCancellable> = []

    func getComments(
        _ parameter: RequestParameter
    ) -> Future<[CommentModel], Error> {

        return Future<[CommentModel], Error> { promise in
            NetworkManager.shared.processData(
                endpoint: .getComments,
                queryParameter: parameter,
                type: ResponseModel<[CommentResponseModel]>.self
            ).sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    promise(.failure(error))
                }
            } receiveValue: { response in
                guard let data = response.data else { return }
                let comments = data.map {
                    var tempComment = $0.data.topLevelComment.data
                    tempComment.pageToken = response.nextPageToken
                    return tempComment
                }
                promise(.success(comments))
            }.store(in: &self.cancellables)
        }
    }
}
