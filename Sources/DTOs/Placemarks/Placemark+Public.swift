//
//  Placemark+Public.swift
//  DTOs
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import Models
import MonkiMapModel

extension PlacemarkModel {
	
	public func asPublic(on database: Database) throws -> EventLoopFuture<Placemark.Public> {
		let kind = Placemark.Kind(rawValue: self.kind.humanId)
		
		let detailsFuture = try Details.query(on: database)
			.filter(\.$placemark.$id == self.requireID())
			.first()
			.unwrap(or: Abort(
				.internalServerError,
				reason: "We could not find the details for this placemark."
			))
			.flatMapThrowing { try $0.asPublic(on: database) }
			.flatMap { $0 }
		
		return detailsFuture.flatMapThrowing { details in
			try .init(
				id: self.requireID(),
				name: self.name,
				latitude: self.latitude,
				longitude: self.longitude,
				kind: kind,
				category: Placemark.Category(for: kind),
				state: self.state,
				creator: self.creator.requireID(),
				details: details,
				createdAt: self.createdAt.require(),
				updatedAt: self.updatedAt.require()
			)
		}
	}
	
}

extension Placemark.Public: Content {}
