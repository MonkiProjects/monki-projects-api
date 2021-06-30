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
	) -> EventLoopFuture<MonkiMapModel.Place.Details.Public> {
		let loadRelationsFuture = EventLoopFuture.andAllSucceed([
			self.$properties.load(on: req.db),
		], on: req.eventLoop)
		
		return loadRelationsFuture
			.flatMapThrowing {
				try Location.query(on: req.db)
					.filter(\.$details.$id == self.requireID())
					.first()
			}
			.flatMap { $0 }
			// FIXME: Trigger a call to reverse geocode location
			.flatMapThrowing { location in
				try MonkiMapModel.Place.Details.Public(
					caption: self.caption,
					satelliteImage: cloudinary.image(withId: self.satelliteImageId).requireURL(),
					images: self.images.map(URL.init(string:)).compactMap { $0 },
					location: location?.asPublic(),
					properties: self.properties.map { try $0.localized(in: .en) }
				)
			}
	}
	
}

extension Place.Details.Public: Content {}
