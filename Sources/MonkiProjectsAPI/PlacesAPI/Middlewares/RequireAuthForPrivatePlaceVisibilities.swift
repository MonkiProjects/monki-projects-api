//
//  RequireAuthForPrivatePlaceVisibilities.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

internal struct RequireAuthForPrivatePlaceVisibilities: Middleware {
	
	func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
		let authorized: [Place.Visibility] = [.public]
		let visibility = try? request.query.get(Place.Visibility.self, at: "visibility")
		
		// Note: We check `!authorized.contains(visibility)` and not `unauthorized.contains(visibility)`
		//       to avoid security breaches if we add a new private visibility.
		if let visibility = visibility, !authorized.contains(visibility) {
			guard request.auth.has(UserModel.self) else {
				return request.eventLoop.future(error: Abort(.unauthorized))
			}
		}
		
		return next.respond(to: request)
	}
	
}
