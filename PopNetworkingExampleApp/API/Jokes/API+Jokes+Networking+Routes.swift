//
//  API+Jokes+Networking+Routes.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

extension API {
    enum Jokes {}
}

extension API.Jokes {
    enum Routes {}
}

extension API.Jokes.Routes {
    struct GetJoke: JokesRoute {

        let path = "/jokes/random"
        let method: NetworkingRouteHttpMethod = .get
        let parameterEncoding: NetworkingRequestParameterEncoding = .url(params: nil)

        let overrideResult: Bool

        typealias ResponseSerializer = NetworkingResponseSerializers.DecodableResponseSerializer<Models.Jokes.Joke>
        var responseSerializationMode: NetworkingResponseSerializationMode<ResponseSerializer> {
            if overrideResult {
                return .override { networkingRawResponse in
                    .success(Models.Jokes.Joke(id: 0, type: "Mocked Joke",
                                               setup: "Have you heard of the band 923 Megabytes?",
                                               punchline: "Probably not, they haven't had a gig yet."))
                }
            }
            else {
                return .standard(ResponseSerializer())
            }
        }
    }

    struct GetTenJokes: JokesRoute {
        let path = "/jokes/ten"
        let method: NetworkingRouteHttpMethod = .get
        let parameterEncoding: NetworkingRequestParameterEncoding = .url(params: nil)

        typealias ResponseSerializer = NetworkingResponseSerializers.DecodableResponseSerializer<[Models.Jokes.Joke]>
        let responseSerializationMode: NetworkingResponseSerializationMode = .standard(ResponseSerializer())
    }

    struct GetTenJokesMappableResponseModelExample: JokesRoute {
        let path = "/jokes/ten"
        let method: NetworkingRouteHttpMethod = .get
        let parameterEncoding: NetworkingRequestParameterEncoding = .url(params: nil)

        typealias ResponseSerializer = NetworkingResponseSerializers.MappableModelResponse<[Models.Jokes.JokeViewModel],
                                                                                           [Models.Jokes.Joke]>
        let responseSerializationMode: NetworkingResponseSerializationMode = .standard(ResponseSerializer())
    }
}
