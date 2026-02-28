//
//  MockHTTPClient.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Foundation
@testable import Discogs

final class MockHTTPClient: HTTPClientProtocol {
    var lastRequest: APIRequest?
    private let result: Any

    init(result: Any) {
        self.result = result
    }

    func send<T>(_ request: APIRequest, as type: T.Type) async throws -> T where T: Decodable {
        lastRequest = request
        return result as! T
    }
}
