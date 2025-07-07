//
//  API+PetFinder+Network+Routes.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

extension API {
    enum PetFinder {}
}

extension API.PetFinder {
    enum Routes {}
}

extension API.PetFinder.Routes {

    struct Authenticate: PetFinderRoute {
        let path = "/v2/oauth2/token"
        let method: NetworkingRouteHttpMethod = .post
        let requiresAuthentication = false

        var parameterEncoding: NetworkingRequestParameterEncoding? {
            .url(params: ["grant_type" : "client_credentials",
                          "client_id" : "FfGxWGrneKMaCIggH0BHnCX6JwBt2JoR0TJvDz5oFpef6chyV4",
                          "client_secret" : "eBNUdOzchjAYxPTd1Ec8w9GESW69G3LoX1al7HlF"])
        }

        var responseSerializer: NetworkingResponseSerializers.DecodableResponseAndErrorSerializer<Models.PetFinder.ApiAccess, Models.PetFinder.ApiError> {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .custom({ decoder in
                let container = try decoder.singleValueContainer()
                let expiresIn = try container.decode(Int.self)
                return Date(timeIntervalSinceNow: Double(expiresIn))
            })
            return NetworkingResponseSerializers.DecodableResponseAndErrorSerializer<Models.PetFinder.ApiAccess, Models.PetFinder.ApiError>(jsonDecoder: jsonDecoder)
        }
    }

    struct GetAnimals: PetFinderRoute {
        let animalType: AnimalType

        let path = "/v2/animals"
        let method: NetworkingRouteHttpMethod = .get
        let requiresAuthentication = true
        var parameterEncoding: NetworkingRequestParameterEncoding? {
            .url(params: ["type" : animalType.rawValue])
        }
        let responseSerializer = NetworkingResponseSerializers.DecodableResponseAndErrorSerializer<Models.PetFinder.GetAnimalsResponse, Models.PetFinder.ApiError>()

        enum AnimalType: String {
            case cat = "Cat"
            case dog = "Dog"
            case bird = "Bird"
        }
    }

    struct GetAnimal: PetFinderRoute {
        let animalId: Int

        var path: String { "/v2/animals/\(animalId)"}
        let method: NetworkingRouteHttpMethod = .get
        let requiresAuthentication = true
        let parameterEncoding: NetworkingRequestParameterEncoding? = nil
        let responseSerializer = NetworkingResponseSerializers.DecodableResponseAndErrorSerializer<Models.PetFinder.GetAnimalResponse, Models.PetFinder.ApiError>()
    }
}
