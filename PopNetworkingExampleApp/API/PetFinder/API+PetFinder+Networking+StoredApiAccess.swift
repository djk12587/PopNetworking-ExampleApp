//
//  API+PetFinder+Networking+StoredApiAccess.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation

@globalActor
actor APIAccessActor {
    static let shared = APIAccessActor()
}

extension APIAccessActor {
    public static func run<T>(resultType: T.Type = T.self, body: @APIAccessActor @Sendable () throws -> T) async rethrows -> T where T : Sendable {
        return try await body()
    }
}

extension API.PetFinder {
    enum StoredApiAccess {}
}

extension API.PetFinder.StoredApiAccess {

    @APIAccessActor
    class Shared {
        static let instance = Shared()

        private init () {}

        var access = Models.PetFinder.ApiAccess(tokenType: "Bearer",
                                               expiration: Date(timeIntervalSinceNow: 100),
                                               accessToken: "Unauthorized!@#!@#")


    }

}
