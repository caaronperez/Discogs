//
//  APIError.swift
//  Discogs
//
//  Created by Cristian Perez on 2/26/26.
//

import Foundation

// Represents errors surfaced by the Discogs API layer.
enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case unauthorized
    case forbidden
    case notFound
    case methodNotAllowed
    case unprocessableEntity
    case internalServerError
    case httpStatus(code: Int)
    case network(description: String)
    case oauthConfigurationMissing
    case oauthPendingTokenMissing
    case oauthVerifierMissing
    case oauthResponseInvalid

    //User-Friendly messages
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .decodingFailed:
            return "The app could not process server data."
        case .unauthorized:
            return "Authentication failed. Add a valid Discogs token."
        case .forbidden:
            return "You don’t have permission to perform this action."
        case .notFound:
            return "The requested resource could not be found."
        case .methodNotAllowed:
            return "This operation is not supported by the server."
        case .unprocessableEntity:
            return "The request was valid, but contains unsupported values."
        case .internalServerError:
            return "Discogs is temporarily unavailable. Try again in a moment."
        case .httpStatus(let code):
            return "The request failed with status code \(code)."
        case .network(let description):
            return description
        case .oauthConfigurationMissing:
            return "OAuth is not configured. Add Discogs consumer key and secret in APIConfig."
        case .oauthPendingTokenMissing:
            return "Start authorization before exchanging a verifier code."
        case .oauthVerifierMissing:
            return "Enter the verifier code shown by Discogs to finish sign in."
        case .oauthResponseInvalid:
            return "Discogs returned an invalid authentication response."
        }
    }

    // Information from developer portal in 'Why am I getting a particular HTTP response?' section
    static func from(statusCode: Int) -> APIError? {
        switch statusCode {
        case 200, 201, 204:
            return nil
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 405:
            return .methodNotAllowed
        case 422:
            return .unprocessableEntity
        case 500:
            return .internalServerError
        default:
            return .httpStatus(code: statusCode)
        }
    }
}
