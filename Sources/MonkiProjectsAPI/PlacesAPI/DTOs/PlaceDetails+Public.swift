//
//  PlaceDetails+Public.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlaceModel.Details {
	
	public func asPublic(
		on req: Request
	) async throws-> MonkiMapModel.Place.Details.Public {
		// Load relations
		try await self.$properties.load(on: req.db)
		
		let location = try await Location.query(on: req.db)
			.filter(\.$details.$id == self.requireID())
			.first()
		
		// TODO: Trigger a call to reverse geocode location
		
		return try MonkiMapModel.Place.Details.Public(
			caption: self.caption,
			satelliteImage: cloudinary.image(withId: self.satelliteImageId).requireURL(),
			images: self.images.map(URL.init(string:)).compactMap { $0 },
			location: location?.asPublic(),
			properties: self.properties.map { try $0.localized(in: .en) }
		)
	}
	
}

extension Place.Details.Public: Content {}
