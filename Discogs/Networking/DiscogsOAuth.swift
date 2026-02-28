//
//  DiscogsOAuth.swift
//  Discogs
//
//  Created by Cristian Perez on 2/26/26.
//

import CryptoKit
import Foundation
import Security

struct OAuthCredential: Codable {
    let token: String
    let tokenSecret: String
}

final class DiscogsOAuthManager {
    static let shared = DiscogsOAuthManager()

    private let session: URLSession
    private let keychain = KeychainStore(service: APIConfig.keychainService)
    private var pendingRequestToken: OAuthCredential?

    private init(session: URLSession = .shared) {
        self.session = session
    }

    var isAuthenticated: Bool {
        loadCredential() != nil
    }

    func beginAuthorization() async throws -> URL {
        guard !APIConfig.consumerKey.isEmpty, !APIConfig.consumerSecret.isEmpty else {
            throw APIError.oauthConfigurationMissing
        }

        guard let requestTokenURL = APIConfig.requestTokenURL else {
            throw APIError.invalidURL
        }

        let header = makeAuthorizationHeader(
            method: "GET",
            url: requestTokenURL,
            queryItems: [],
            token: nil,
            tokenSecret: nil,
            callback: APIConfig.oauthCallback,
            verifier: nil
        )

        var request = URLRequest(url: requestTokenURL)
        request.httpMethod = "GET"
        request.setValue(APIConfig.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(header, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateOAuthResponse(response)

        let values = parseFormEncodedData(data)
        guard
            let token = values["oauth_token"],
            let tokenSecret = values["oauth_token_secret"],
            let authorizeBaseURL = APIConfig.authorizeURL,
            let authorizeURL = URL(string: "\(authorizeBaseURL.absoluteString)?oauth_token=\(token.oauthEncoded())")
        else {
            throw APIError.oauthResponseInvalid
        }

        pendingRequestToken = OAuthCredential(token: token, tokenSecret: tokenSecret)
        return authorizeURL
    }

    func completeAuthorization(verifier: String) async throws {
        guard !verifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.oauthVerifierMissing
        }

        guard let pending = pendingRequestToken else {
            throw APIError.oauthPendingTokenMissing
        }

        guard let accessTokenURL = APIConfig.accessTokenURL else {
            throw APIError.invalidURL
        }

        let header = makeAuthorizationHeader(
            method: "GET",
            url: accessTokenURL,
            queryItems: [],
            token: pending.token,
            tokenSecret: pending.tokenSecret,
            callback: nil,
            verifier: verifier
        )

        var request = URLRequest(url: accessTokenURL)
        request.httpMethod = "GET"
        request.setValue(APIConfig.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(header, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateOAuthResponse(response)

        let values = parseFormEncodedData(data)
        guard
            let token = values["oauth_token"],
            let tokenSecret = values["oauth_token_secret"]
        else {
            throw APIError.oauthResponseInvalid
        }

        let credential = OAuthCredential(token: token, tokenSecret: tokenSecret)
        try saveCredential(credential)
        pendingRequestToken = nil
    }

    // Clear saved OAuth data and reset the current auth flow state.
    func signOut() {
        keychain.delete(key: APIConfig.oauthCredentialKey)
        pendingRequestToken = nil
    }

    // Build the Authorization header for signed requests when we have credentials.
    func authorizationHeader(method: String, url: URL, queryItems: [URLQueryItem]) -> String? {
        guard let credential = loadCredential() else {
            return nil
        }

        return makeAuthorizationHeader(
            method: method,
            url: url,
            queryItems: queryItems,
            token: credential.token,
            tokenSecret: credential.tokenSecret,
            callback: nil,
            verifier: nil
        )
    }

    private func loadCredential() -> OAuthCredential? {
        guard let data = keychain.read(key: APIConfig.oauthCredentialKey) else {
            return nil
        }
        return try? JSONDecoder().decode(OAuthCredential.self, from: data)
    }

    private func saveCredential(_ credential: OAuthCredential) throws {
        let data = try JSONEncoder().encode(credential)
        keychain.save(data: data, key: APIConfig.oauthCredentialKey)
    }

    private func validateOAuthResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if let mappedError = APIError.from(statusCode: http.statusCode) {
            throw mappedError
        }
    }

    private func parseFormEncodedData(_ data: Data) -> [String: String] {
        guard let string = String(data: data, encoding: .utf8) else { return [:] }

        var result: [String: String] = [:]
        for pair in string.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let key = parts[0].removingPercentEncoding ?? parts[0]
            let value = parts[1].removingPercentEncoding ?? parts[1]
            result[key] = value
        }

        return result
    }

    private func makeAuthorizationHeader(
        method: String,
        url: URL,
        queryItems: [URLQueryItem],
        token: String?,
        tokenSecret: String?,
        callback: String?,
        verifier: String?
    ) -> String {
        var oauth: [String: String] = [
            "oauth_consumer_key": APIConfig.consumerKey,
            "oauth_nonce": UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(Int(Date().timeIntervalSince1970)),
            "oauth_version": "1.0"
        ]

        if let token {
            oauth["oauth_token"] = token
        }

        if let callback {
            oauth["oauth_callback"] = callback
        }

        if let verifier {
            oauth["oauth_verifier"] = verifier
        }

        let signature = oauthSignature(
            method: method,
            url: url,
            oauthParameters: oauth,
            queryItems: queryItems,
            tokenSecret: tokenSecret
        )
        oauth["oauth_signature"] = signature

        let header = oauth
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key.oauthEncoded())=\("\($0.value.oauthEncoded())")" }
            .joined(separator: ", ")

        return "OAuth \(header)"
    }

    private func oauthSignature(
        method: String,
        url: URL,
        oauthParameters: [String: String],
        queryItems: [URLQueryItem],
        tokenSecret: String?
    ) -> String {
        let urlQueryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        var signaturePairs: [(String, String)] = []
        for (key, value) in oauthParameters {
            signaturePairs.append((key, value))
        }

        for item in (queryItems + urlQueryItems) {
            signaturePairs.append((item.name, item.value ?? ""))
        }

        let encodedPairs = signaturePairs.map { pair in
            (pair.0.oauthEncoded(), pair.1.oauthEncoded())
        }

        let sortedPairs = encodedPairs.sorted { lhs, rhs in
            if lhs.0 == rhs.0 {
                return lhs.1 < rhs.1
            }
            return lhs.0 < rhs.0
        }

        let normalized = sortedPairs
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "&")

        let normalizedURL = normalizedBaseURL(url)
        let baseString = [
            method.uppercased().oauthEncoded(),
            normalizedURL.oauthEncoded(),
            normalized.oauthEncoded()
        ].joined(separator: "&")

        let signingKey = "\(APIConfig.consumerSecret.oauthEncoded())&\((tokenSecret ?? "").oauthEncoded())"

        let key = SymmetricKey(data: Data(signingKey.utf8))
        let digest = HMAC<Insecure.SHA1>.authenticationCode(for: Data(baseString.utf8), using: key)
        return Data(digest).base64EncodedString()
    }

    private func normalizedBaseURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        components.query = nil
        components.fragment = nil
        return components.string ?? url.absoluteString
    }
}

private extension String {
    func oauthEncoded() -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

private struct KeychainStore {
    let service: String

    func save(data: Data, key: String) {
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        return item as? Data
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
