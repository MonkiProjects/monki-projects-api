//
//  PlacemarkDetails+Public.swift
//  DTOs
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlacemarkModel.Details {
	
	public func asPublic(
		on database: Database
	) throws -> EventLoopFuture<MonkiMapModel.Placemark.Details.Public> {
		let locationFuture = try Location.query(on: database)
			.filter(\.$details.$id == self.requireID())
			.first()
		// FIXME: Trigger a call to reverse geocode location
		
		let loadRelationsFuture = locationFuture
			.passthroughAfter { _ in self.$properties.load(on: database) }
		
		return loadRelationsFuture.flatMapThrowing { location in
			try MonkiMapModel.Placemark.Details.Public(
				caption: self.caption,
				satelliteImage: cloudinary.image(withId: self.satelliteImageId).requireURL(),
				images: self.images.map(URL.init(string:)).compactMap { $0 },
				location: location?.asPublic(),
				properties: self.properties.map { try $0.localized(in: .en) }
			)
		}
	}
	
}

extension Placemark.Details.Public: Content {}
