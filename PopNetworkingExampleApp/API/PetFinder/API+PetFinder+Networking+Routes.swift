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
                          "client_id" : "C8AyYGAfbPPZ084CwurANYcVI8G3mbyZ8jW6TAMY7O4ZNETjX6",
                          "client_secret" : "g4fSDxEYpOW8g2620lUMYXHyt0nqRfD4J4vE5mEk"])
        }

        var responseSerializer: NetworkingResponseSerializers.DecodableResponseWithErrorSerializer<Models.PetFinder.ApiAccess, Models.PetFinder.ApiError> {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .custom({ decoder in
                let container = try decoder.singleValueContainer()
                let expiresIn = try container.decode(Int.self)
                return Date(timeIntervalSinceNow: Double(expiresIn))
            })
            return NetworkingResponseSerializers.DecodableResponseWithErrorSerializer<Models.PetFinder.ApiAccess, Models.PetFinder.ApiError>(jsonDecoder: jsonDecoder)
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
        let responseSerializer = NetworkingResponseSerializers.DecodableResponseWithErrorSerializer<Models.PetFinder.GetAnimalsResponse, Models.PetFinder.ApiError>()

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
        let responseSerializer = NetworkingResponseSerializers.DecodableResponseWithErrorSerializer<Models.PetFinder.GetAnimalResponse, Models.PetFinder.ApiError>()
    }
}
