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

public actor PetFinderReauthenticationHandler: NetworkingInterceptor {

    private let reauthenticationRoute = API.PetFinder.Routes.Authenticate()
    private var activeReauthenticationTask: Task<NetworkingRetrierResult, Never>?

    // MARK: - RequestAdapter

    public func adapt(urlRequest: URLRequest) async throws -> URLRequest {
        guard isAuthorizationRequired(for: urlRequest) else { return urlRequest }

        try await validateAccessToken()

        if await isAuthorizationValid(for: urlRequest) {
            return urlRequest
        }

        var urlRequest = urlRequest
        try await setAuthorization(for: &urlRequest)
        return urlRequest
    }

    // MARK: - RequestRetrier

    public func retry(urlRequest: URLRequest?,
                      dueTo error: any Error,
                      urlResponse: URLResponse?,
                      retryCount: Int) async -> NetworkingRetrierResult {
        let reauthorizationResult = await shouldReauthenticate(urlRequest: urlRequest,
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

    private func reauthenticate() async -> NetworkingRetrierResult {

        if let activeReauthenticationTask = activeReauthenticationTask, !activeReauthenticationTask.isCancelled {
            return await activeReauthenticationTask.value
        }
        else {
            let reauthTask = createReauthenticationTask()
            activeReauthenticationTask = reauthTask
            return await reauthTask.value
        }
    }

    private func createReauthenticationTask() -> Task<NetworkingRetrierResult, Never> {
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

    private var serverAuthentication: Models.PetFinder.ApiAccess { get async { await API.PetFinder.StoredApiAccess.Shared.instance.access } }
    private var tokenIsExpired: Bool { get async { await serverAuthentication.expiration.compare(Date()) == .orderedAscending } }

    func validateAccessToken() async throws {
        if await tokenIsExpired {
            throw PetFinderAccessTokenError.accessTokenIsInvalid
        }
    }

    func isAuthorizationRequired(for urlRequest: URLRequest) -> Bool {
        return true
    }

    func isAuthorizationValid(for urlRequest: URLRequest) async -> Bool {
        urlRequest.allHTTPHeaderFields?["Authorization"] == "\(await serverAuthentication.tokenType) \(await serverAuthentication.accessToken)"
    }

    func setAuthorization(for urlRequest: inout URLRequest) async throws {
        urlRequest.allHTTPHeaderFields?["Authorization"] = "\(await serverAuthentication.tokenType) \(await serverAuthentication.accessToken)"
    }

    func shouldReauthenticate(urlRequest: URLRequest?, dueTo error: Error, urlResponse: URLResponse?, retryCount: Int) async -> ReauthorizationMethod {
        let requestIsUnauthorized = (urlResponse as? HTTPURLResponse)?.statusCode == 401 || (error as? PetFinderAccessTokenError) == .accessTokenIsInvalid
        let requestAuthDoesNotMatchCurrentAuth = urlRequest?.allHTTPHeaderFields?["Authorization"]?.contains(await API.PetFinder.StoredApiAccess.Shared.instance.access.accessToken) == false
        if requestAuthDoesNotMatchCurrentAuth {
            return .retryRequest
        } else if requestIsUnauthorized && retryCount < 3 {
            return .refreshAuthorization
        } else {
            return .doNothing
        }
    }

    func saveReauthentication(result: Result<Models.PetFinder.ApiAccess, Error>) async -> Bool {
        switch result {
            case .success(let updatedAuthorization):
                await APIAccessActor.run { API.PetFinder.StoredApiAccess.Shared.instance.access = updatedAuthorization }
            return true
            case .failure(let error):
                print("reauthentication failure reason: \(error)")
            return false
        }
    }
}
