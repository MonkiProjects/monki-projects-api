//
//  Place+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel
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
		
		let metadata = try Place.Metadata(
			visibility: self.visibility,
			isDraft: self.isDraft,
			creator: self.creator.id,
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
		
		return try Place.Public(
			id: self.requireID(),
			name: self.name,
			coordinate: Coordinate(latitude: self.latitude, longitude: self.longitude),
			kind: kind,
			category: Place.Category.ID(for: kind),
			details: details,
			metadata: metadata
		)
	}
	
}

extension Place.Public: Content {}
