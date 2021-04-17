//
//  PlacemarkService.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel
import Models

internal struct PlacemarkService {
	
	let req: Request
	
	func listPlacemarks() throws -> EventLoopFuture<Page<Placemark.Public>> {
		let pageRequest = try req.query.decode(PageRequest.self)
		struct Params: Content {
			let state: Placemark.State?
		}
		let state = try req.query.decode(Params.self).state ?? .published
		
		switch state {
		case .unknown:
			throw Abort(.forbidden, reason: "Fetching placemarks in 'unknown' state is impossible.")
		case .draft, .local, .private:
			let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
			return req.placemarks.paged(state: state, creator: userId, pageRequest)
		case .submitted, .published, .rejected:
			return req.placemarks.paged(state: state, creator: nil, pageRequest)
		}
	}
	
}
