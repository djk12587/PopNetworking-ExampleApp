//
//  PetFinderReauthenticationHandler.swift
//  PopNetworkingExampleApp
//
//  Created by Dan_Koza on 9/17/22.
//

import Foundation
import PopNetworking

extension PetFinderReauthenticationHandler {
    enum ReauthorizationMethod {
        /// Your access token is invalid and needs to be refreshed. Once reauthorization is complete your request will be retried
        case refreshAuthorization

        /// Your access token is valid, retry the request
        case retryRequest

        /// Do nothing and let the request fail
        case doNothing
    }
}

public actor PetFinderReauthenticationHandler: NetworkingRequestInterceptor {

    private let reauthenticationRoute = API.PetFinder.Routes.Authenticate()
    private var activeReauthenticationTask: Task<NetworkingRequestRetrierResult, Never>?

    // MARK: - RequestAdapter

    public func adapt(urlRequest: URLRequest) throws -> URLRequest {
        guard isAuthorizationRequired(for: urlRequest) else { return urlRequest }

        try validateAccessToken()

        if isAuthorizationValid(for: urlRequest) {
            return urlRequest
        }

        var urlRequest = urlRequest
        try setAuthorization(for: &urlRequest)
        return urlRequest
    }

    // MARK: - RequestRetrier

    public func retry(urlRequest: URLRequest?,
                      dueTo error: Error,
                      urlResponse: HTTPURLResponse?,
                      retryCount: Int) async -> NetworkingRequestRetrierResult {
        let reauthorizationResult = shouldReauthenticate(urlRequest: urlRequest,
                                                         dueTo: error,
                                                         urlResponse: urlResponse,
                                                         retryCount: retryCount)
        switch reauthorizationResult {
            case .refreshAuthorization:
                return await reauthenticate()
            case .retryRequest:
                return .retry
            case .doNothing:
                return .doNotRetry
        }
    }

    private func reauthenticate() async -> NetworkingRequestRetrierResult {

        if let activeReauthenticationTask = activeReauthenticationTask, !activeReauthenticationTask.isCancelled {
            return await activeReauthenticationTask.value
        }
        else {
            let reauthTask = createReauthenticationTask()
            activeReauthenticationTask = reauthTask
            return await reauthTask.value
        }
    }

    private func createReauthenticationTask() -> Task<NetworkingRequestRetrierResult, Never> {
        Task {
            defer { activeReauthenticationTask = nil }

            let reauthResult = await reauthenticationRoute.result

            let saveWasSuccessful = await saveReauthentication(result: reauthResult)
            switch reauthResult {
                case .success where saveWasSuccessful:
                    return .retry
                default:
                    return .doNotRetry
            }
        }
    }
}

extension PetFinderReauthenticationHandler {

    enum PetFinderAccessTokenError: Error {
        case accessTokenIsInvalid
    }

    private var serverAuthentication: Models.PetFinder.ApiAccess { API.PetFinder.StoredApiAccess.apiAccess }
    private var tokenIsExpired: Bool { serverAuthentication.expiration.compare(Date()) == .orderedAscending }


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

    func shouldReauthenticate(urlRequest: URLRequest?, dueTo error: Error, urlResponse: HTTPURLResponse?, retryCount: Int) -> ReauthorizationMethod {
        let requestIsUnauthorized = urlResponse?.statusCode == 401 || (error as? PetFinderAccessTokenError) == .accessTokenIsInvalid
        return requestIsUnauthorized && retryCount < 3 ? .refreshAuthorization : .doNothing
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
