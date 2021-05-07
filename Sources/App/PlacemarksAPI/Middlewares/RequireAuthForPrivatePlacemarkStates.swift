//
//  RequireAuthForPrivatePlacemarkStates.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

internal struct RequireAuthForPrivatePlacemarkStates: Middleware {
	
	func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
		let authorized: [Placemark.State] = [.submitted, .published, .rejected]
		let state = try? request.query.get(Placemark.State.self, at: "state")
		
		// Note: We check `!authorized.contains(state)` and not `unauthorized.contains(state)`
		//       to avoid security breaches if we add a new private state.
		if let state = state, !authorized.contains(state) {
			guard request.auth.has(UserModel.self) else {
				return request.eventLoop.future(error: Abort(.unauthorized))
			}
		}
		
		return next.respond(to: request)
	}
	
}
