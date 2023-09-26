//
//  NetworkManager.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Combine
import Foundation
import UIKit

typealias RequestParameter = [String: Any]?

class NetworkManager {
    private enum Constants {
        static let defaultErrorMessage = "Something Went Wrong"
    }
    static let shared = NetworkManager()
    private let successCodes = [200, 201, 202, 203]
    private var cancellables: Set<AnyCancellable> = []

    func processData<T: Decodable>(method: RequestMethod = .get,
                                   body: [String: Any] = [:],
                                   endpoint: Endpoint,
                                   queryParameter: [String: Any]? = [:],
                                   type: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self,
                  let request = CustomRequest(endpoint: endpoint,
                                              method: method,
                                              queryParameter: queryParameter ?? [:],
                                              body: body).urlRequest else {
                return promise(.failure(URLError(.badURL)))
            }

            if endpoint == .getMostPopular {
                print(request.cURL())
            }

            URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { result in
                    guard let httpResponse = result.response as? HTTPURLResponse,
                          self.successCodes.contains(httpResponse.statusCode) else {
                        throw CustomError.errorWithMessage(Constants.defaultErrorMessage)
                    }
                    return result.data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { (completion) in
                    if case let .failure(error) = completion {
                        switch error {
                        case let decodingError as DecodingError:
                            promise(.failure(decodingError))
                        case let customError as CustomError:
                            promise(.failure(customError))
                        default:
                            promise(.failure(CustomError.unknown))
                        }
                    }
                }, receiveValue: {
                    promise(.success($0))
                })
                .store(in: &self.cancellables)
        }
    }

}
