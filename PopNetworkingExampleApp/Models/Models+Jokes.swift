//
//  Models+Jokes.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

extension Models {
    enum Jokes {}
}

extension Models.Jokes {
    struct Joke: Codable {
        let id: Int
        let type: String
        let setup: String
        let punchline: String
    }

    struct JokeViewModel: MappableModel  {
        typealias SourceModel = Joke

        let anotherId: Int
        let aPunchline: String

        init(sourceModel: Models.Jokes.Joke) {
            anotherId = sourceModel.id
            aPunchline = sourceModel.punchline
        }
    }
}

extension Models.Jokes {
    struct JokeApiError: Codable, Error {
        let code: Int
        let failureReason: String
    }

    struct JokeViewModelError: MappableModel, Error  {
        typealias SourceModel = JokeApiError

        let reason: String

        init(sourceModel: JokeApiError) {
            reason = sourceModel.failureReason
        }
    }
}
