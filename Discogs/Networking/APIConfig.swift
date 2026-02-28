//
//  APIConfig.swift
//  Discogs
//
//  Created by Cristian Perez on 2/26/26.
//

import Foundation

// Configuration values used by the Discogs networking layer ... this information was obtained in developer documentation
struct APIConfig {
    static let baseURL = URL(string: "https://api.discogs.com")
    static let perPage = 30
    static let tokenUserDefaultsKey = "discogsToken"
    static let userAgent = "DiscogsExplorer/1.0 +https://github.com/example/discogs-explorer"

    static let consumerKey = "VdynVFuDRrtbeaZCrOnc"
    static let consumerSecret = "KWEceCpQLBcgrMFTINREbeGsCAcMcXPB"

    static let requestTokenURL = URL(string: "https://api.discogs.com/oauth/request_token")
    static let authorizeURL = URL(string: "https://www.discogs.com/oauth/authorize")
    static let accessTokenURL = URL(string: "https://api.discogs.com/oauth/access_token")

    static let oauthCallback = "oob"

    static let keychainService = "com.discogs.explorer.auth"
    static let oauthCredentialKey = "discogsOAuthCredential"
}

protocol TokenProviding {
    var token: String { get }
}

struct UserDefaultsTokenProvider: TokenProviding {
    var token: String {
        UserDefaults.standard.string(forKey: APIConfig.tokenUserDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
