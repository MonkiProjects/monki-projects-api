//
//  Placemark+Public.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension Placemark.Model {
	
	func asPublic(on database: Database) throws -> Placemark.Public {
		let kind = Placemark.Kind(rawValue: self.kind.humanId)
		
		let details = try Details.query(on: database)
			.filter(\.$placemark.$id == self.requireID())
			.first()
			.unwrap(or: Abort(.internalServerError,
				reason: "We could not find the details for this placemark."
			))
			.wait()
		
		return try .init(
			id: self.requireID(),
			name: self.name,
			latitude: self.latitude,
			longitude: self.longitude,
			kind: kind,
			category: Placemark.Category(for: kind),
			state: self.state,
			creator: self.creator.requireID(),
			details: details.asPublic(on: database),
			createdAt: self.createdAt.require(),
			updatedAt: self.updatedAt.require()
		)
	}
	
}

extension Placemark.Public: Content {}
