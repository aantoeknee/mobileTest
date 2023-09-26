//
//  CustomRequest.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/26/23.
//

import Foundation
import UIKit

enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class CustomRequest {
    private var defaultHeader: [String: String] = ["Content-Type": "application/json"]
    private let method: RequestMethod
    private let body: [String: Any]
    private let queryParamter: [String: Any]
    private let endpoint: Endpoint

    private var urlString: String {
        var urlParamString = endpoint.urlString + "?"
        if !queryParamter.isEmpty {
            for (key, value) in queryParamter {
                urlParamString.append("\(key)=\(value)&")
            }
        }
        return String(urlParamString.dropLast().replacingOccurrences(of: " ", with: "%20"))
    }

    public var urlRequest: URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        for (key, value) in defaultHeader {
            request.addValue(value, forHTTPHeaderField: key)
        }

        if method == .post {
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        }
        switch method {
        case .post, .put:
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        default: break
        }
        return request
    }

    public init(endpoint: Endpoint,
                method: RequestMethod,
                queryParameter: [String: Any],
                body: [String: Any] = [:]) {
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.queryParamter = queryParameter
    }
}
