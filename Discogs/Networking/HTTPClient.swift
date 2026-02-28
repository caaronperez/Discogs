//
//  HTTPClient.swift
//  Discogs
//
//  Created by Cristian Perez on 2/26/26.
//

import Foundation

// A request object used by the HTTP client.
struct APIRequest {
    let path: String
    var method: String = "GET"
    var queryItems: [URLQueryItem] = []
    var body: Data?
}

protocol HTTPClientProtocol {
    @MainActor
    func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T
}

// Sends authenticated requests to the Discogs API.
final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let tokenProvider: TokenProviding

    init(session: URLSession, tokenProvider: TokenProviding) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    convenience init() {
        self.init(session: .shared, tokenProvider: UserDefaultsTokenProvider())
    }

    func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T {
        guard var components = URLComponents(url: try baseURL(), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }

        components.path = request.path

        let token = tokenProvider.token
        let hasOAuthCredential = DiscogsOAuthManager.shared.isAuthenticated

        var queryItems = request.queryItems
        if !hasOAuthCredential, token.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: APIConfig.consumerKey))
            queryItems.append(URLQueryItem(name: "secret", value: APIConfig.consumerSecret))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.setValue(APIConfig.userAgent, forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if hasOAuthCredential,
           let oauthHeader = DiscogsOAuthManager.shared.authorizationHeader(
            method: request.method,
            url: url,
            queryItems: []
           ) {
            urlRequest.setValue(oauthHeader, forHTTPHeaderField: "Authorization")
        } else if !token.isEmpty {
            urlRequest.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if let mappedError = APIError.from(statusCode: httpResponse.statusCode) {
                throw mappedError
            }

            if data.isEmpty, let emptyResponse = EmptyResponse() as? T {
                return emptyResponse
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(description: error.localizedDescription)
        }
    }

    private func baseURL() throws -> URL {
        guard let baseURL = APIConfig.baseURL else {
            throw APIError.invalidURL
        }
        return baseURL
    }
}

private struct EmptyResponse: Decodable {
    init() {}
}
