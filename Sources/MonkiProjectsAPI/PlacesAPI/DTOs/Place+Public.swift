//
//  Place+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlaceModel {
	
	public func asPublic(on req: Request) async throws -> Place.Public {
		try await self.$kind.load(on: req.db)
		try await self.kind.$category.load(on: req.db)
		try await self.$creator.load(on: req.db)
		
		let details = try await req.placeDetailsRepository
			.get(for: self.requireID())
			.asPublic(on: req)
		
		let kind = Place.Kind.ID(rawValue: self.kind.humanId)
		
		return try Place.Public(
			id: self.requireID(),
			name: self.name,
			latitude: self.latitude,
			longitude: self.longitude,
			kind: kind,
			category: Place.Category.ID(for: kind),
			state: self.state,
			creator: self.creator.requireID(),
			details: details,
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}

extension Place.Public: Content {}
