//
//  API+PetFinder+Networking+Reauthentication.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

extension API.PetFinder {
    class PetFinderAccessTokenVerifier: AccessTokenVerification {

        enum PetFinderAccessTokenError: Error {
            case accessTokenIsInvalid
        }

        private var serverAuthentication: Models.PetFinder.ApiAccess { API.PetFinder.StoredApiAccess.apiAccess }
        private var tokenIsExpired: Bool { serverAuthentication.expiration.compare(Date()) == .orderedAscending }
        private(set) var reauthenticationRoute = API.PetFinder.Routes.Authenticate()

        func validateAccessToken() throws {
            if tokenIsExpired {
                throw PetFinderAccessTokenError.accessTokenIsInvalid
            }
        }

        func isAuthorizationRequired(for urlRequest: URLRequest) -> Bool {
            return true
        }

        func isAuthorizationValid(for urlRequest: URLRequest) -> Bool {
            urlRequest.allHTTPHeaderFields?["Authorization"] == "\(serverAuthentication.tokenType) \(serverAuthentication.accessToken)"
        }

        func setAuthorization(for urlRequest: inout URLRequest) throws {
            urlRequest.allHTTPHeaderFields?["Authorization"] = "\(serverAuthentication.tokenType) \(serverAuthentication.accessToken)"
        }

        func shouldReauthenticate(urlRequest: URLRequest?, dueTo error: Error, urlResponse: HTTPURLResponse?, retryCount: Int) -> Bool {
            let requestIsUnauthorized = urlResponse?.statusCode == 401 || (error as? PetFinderAccessTokenError) == .accessTokenIsInvalid
            return requestIsUnauthorized && retryCount < 3
        }

        func saveReauthentication(result: Result<Models.PetFinder.ApiAccess, Error>) async -> Bool {
            switch result {
                case .success(let authorizationModel):
                    API.PetFinder.StoredApiAccess.apiAccess = authorizationModel
                case .failure(let error):
                    print("reauthentication failure reason: \(error)")
            }
            return true
        }
    }
}
