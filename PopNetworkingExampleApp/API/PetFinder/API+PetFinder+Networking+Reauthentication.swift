//
//  API+PetFinder+Networking+Reauthentication.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

extension API.PetFinder {

    class ReauthenticationHandler: NetworkingRequestInterceptor {

        private var isRefreshingToken = false
        private var requestsWaitingForReauthentication: [(NetworkingRequestRetrierResult) -> Void] = []
        private let maxRetryCount = 3

        // MARK: - RequestAdapter

        ///This gives you a chance to modify the `urlRequest` before it gets sent over the wire. This is the spot where you update the authorization for the `urlRequest`. Or, if you know the access token is expired, then throw an error. That error will get sent to the retry() function allowing you to refresh
        func adapt(urlRequest: URLRequest) throws -> URLRequest {
            let storedApiAccess = API.PetFinder.StoredApiAccess.apiAccess
            let savedAccesToken = "\(storedApiAccess.tokenType) \(storedApiAccess.accessToken)"

            guard let requestsAccessToken = urlRequest.allHTTPHeaderFields?["Authorization"] else {
                //urlRequest doesnt have the Authorization header, so there is no need to modify it
                return urlRequest
            }

            guard !savedAccesToken.contains("Unauthorized") else {
                //We know the access token is unauthorized, so throw an error. This triggers retry() to be called
                throw NSError(domain: "Unauthorized", code: 401, userInfo: nil)
            }

            guard requestsAccessToken == savedAccesToken else {
                var adaptedRequest = urlRequest
                //update the adaptedRequest's Authorization header with the savedAccesToken
                adaptedRequest.allHTTPHeaderFields?["Authorization"] = savedAccesToken
                return adaptedRequest
            }

            return urlRequest
        }

        // MARK: - RequestRetrier

        ///If your request fails due to 401 error, then reauthenticate with the API & return `.retry` to retry the `urlRequest`
        func retry(urlRequest: URLRequest, dueTo error: Error, urlResponse: HTTPURLResponse, retryCount: Int, completion: @escaping (NetworkingRequestRetrierResult) -> Void) {

            //Check if the error is due to unauthorized access
            let isUnauthorized = urlResponse.statusCode == 401 || (error as NSError).code == 401
            guard isUnauthorized,
                  retryCount < maxRetryCount else {
                completion(.doNotRetry)
                return
            }

            //hold onto the completion block so we can wait for performReauthentication to complete
            requestsWaitingForReauthentication.append(completion)

            //performReauthentication should run only one at a time
            guard !isRefreshingToken else { return }

            performReauthentication { [weak self] succeeded in
                guard let self = self else { return }

                //this retry() function can be recursive. So, we want to make a copy of requestsWaitingForReauthentication, then call removeAll() on requestsWaitingForReauthentication.
                let temporaryCopy = self.requestsWaitingForReauthentication
                self.requestsWaitingForReauthentication.removeAll()

                //trigger the cached completion blocks. This informs the request if it needs to be retried or not.
                temporaryCopy.forEach { $0(succeeded ? .retry : .doNotRetry) }
            }
        }

        // MARK: - Private - Authenticate with your API

        private func performReauthentication(completion: @escaping (_ succeeded: Bool) -> Void) {
            guard !isRefreshingToken else { return }

            isRefreshingToken = true

            API.PetFinder.Routes.Authenticate().request { [weak self] authenticationResult in
                guard case .success(let petFinderAuth) = authenticationResult else {
                    self?.isRefreshingToken = false
                    completion(false)
                    return
                }

                API.PetFinder.StoredApiAccess.apiAccess = petFinderAuth
                self?.isRefreshingToken = false
                completion(true)
            }
        }
    }
}
