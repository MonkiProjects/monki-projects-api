//
//  Placemark+Public.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension PlacemarkModel {
	
	public func asPublic(on req: Request) -> EventLoopFuture<Placemark.Public> {
		let loadRelationsFuture = EventLoopFuture.andAllSucceed([
			self.$kind.load(on: req.db)
				.flatMap { self.kind.$category.load(on: req.db) },
			self.$creator.load(on: req.db),
		], on: req.eventLoop)
		
		let detailsFuture = loadRelationsFuture
			.flatMapThrowing {
				try req.placemarkDetailsRepository.get(for: self.requireID())
					.flatMap { $0.asPublic(on: req) }
			}
			.flatMap { $0 }
		
		return detailsFuture.flatMapThrowing { details -> Placemark.Public in
			let kind = Placemark.Kind(rawValue: self.kind.humanId)
			
			return try .init(
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
