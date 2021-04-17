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

        let setup: String
        let punchline: String

        init(sourceModel: Models.Jokes.Joke) {
            self.setup = sourceModel.setup
            self.punchline = sourceModel.punchline
        }
    }
}
