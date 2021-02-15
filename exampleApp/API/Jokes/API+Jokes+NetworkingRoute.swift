//
//  File.swift
//  howToUse
//
//  Created by Dan Koza on 2/14/21.
//

import Foundation
import PopNetworking

///https://github.com/15Dkatz/official_joke_api
protocol JokesRoute: NetworkingRoute {}

extension JokesRoute {
    var baseURL: String { "https://official-joke-api.appspot.com" }
    var headers: NetworkingRouteHttpHeaders? { nil }
    var session: NetworkingSession { API.Jokes.Session.standard }
}
