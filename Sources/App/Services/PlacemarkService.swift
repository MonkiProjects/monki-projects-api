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
import Jobs

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
	
	func createPlacemark() throws -> EventLoopFuture<Placemark.Public> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		// Validate and decode data
		try Placemark.Create.validate(content: req)
		let create = try req.content.decode(Placemark.Create.self)
		
		// Do additional validations
		// TODO: Check for near spots (e.g. < 20m)
		
		let placemarkKindFuture = PlacemarkModel.Kind.query(on: req.db)
			.filter(\.$humanId == create.kind.rawValue)
			.first()
			.unwrap(or: Abort(.notFound, reason: "Placemark type not found"))
		
		// Create Placemark object
		let placemarkFuture = placemarkKindFuture.flatMapThrowing { kind in
			try PlacemarkModel(
				name: create.name,
				latitude: create.latitude,
				longitude: create.longitude,
				kindId: kind.requireID(),
				state: .private,
				creatorId: user.requireID()
			)
		}
		
		// Save Placemark in database
		let createPlacemarkFuture = placemarkFuture.passthroughAfter { $0.create(on: req.db) }
		
		// Add properties
		let addPropertiesFuture = { (details: PlacemarkModel.Details) -> EventLoopFuture<Void> in
			req.eventLoop.makeSucceededFuture(create.properties)
				.sequencedFlatMapEach { kind, propertyIds in
					req.eventLoop.makeSucceededFuture(propertyIds)
						.sequencedFlatMapEach { propertyId in
							PlacemarkModel.Details.Property.query(on: req.db)
								.filter(\.$kind == kind)
								.filter(\.$humanId == propertyId)
								.first()
								.unwrap(or: Abort(
									.badRequest,
									reason: "Invalid property: { \"kind\": \"\(kind)\", \"id\": \"\(propertyId)\" }"
								))
								.flatMap { property in
									details.$properties.attach(property, method: .ifNotExists, on: req.db)
								}
						}
				}
		}
		
		// Create placemark details
		let createDetailsFuture = createPlacemarkFuture
			.passthroughAfter { placemark -> EventLoopFuture<Void> in
				let details = try PlacemarkModel.Details(
					placemarkId: placemark.requireID(),
					caption: create.caption,
					images: (create.images ?? []).map { $0.absoluteString }
				)
				
				return details.create(on: req.db)
					.transform(to: details)
					.flatMap(addPropertiesFuture)
			}
		
		// Trigger satellite view loading
		let loadSatelliteViewFuture = createDetailsFuture
			.passthroughAfter { placemark -> EventLoopFuture<Void> in
				if req.application.environment == .testing {
					return req.eventLoop.makeSucceededFuture(())
				} else {
					return req.queues(.placemarks)
						.dispatch(
							PlacemarkSatelliteViewJob.self,
							.init(
								placemarkId: try placemark.requireID(),
								latitude: placemark.latitude,
								longitude: placemark.longitude
							)
						)
				}
			}
		
		// Trigger location reverse geocoding
		let reverseGeocodeLocationFuture = loadSatelliteViewFuture
			.passthroughAfter { placemark -> EventLoopFuture<Void> in
				if req.application.environment == .testing {
					return req.eventLoop.makeSucceededFuture(())
				} else {
					return req.queues(.placemarks)
						.dispatch(
							PlacemarkLocationJob.self,
							.init(
								placemarkId: try placemark.requireID(),
								latitude: placemark.latitude,
								longitude: placemark.longitude
							)
						)
				}
			}
		
		return reverseGeocodeLocationFuture
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func getPlacemark() throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		return PlacemarkModel.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func deletePlacemark() throws -> EventLoopFuture<HTTPStatus> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		let placemarkFuture = PlacemarkModel.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
		
		// Do additional validations
		let guardAuthorizedFuture = placemarkFuture.guard({ placemark in
			placemark.$creator.id == user.id
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's placemark!"))
		
		let deleteDetailsFuture = guardAuthorizedFuture
			.passthroughAfter { _ in
				PlacemarkModel.Details.query(on: req.db)
					.with(\.$placemark)
					.filter(\.$placemark.$id == placemarkId)
					.all()
					.flatMap { $0.delete(on: req.db) }
			}
		
		return deleteDetailsFuture
			.flatMap { $0.delete(on: req.db) }
			.transform(to: .noContent)
	}
	
	func listProperties() throws -> EventLoopFuture<[Placemark.Property.Localized]> {
		let kind = try req.query.get(Placemark.Property.Kind.self, at: "kind")
		
		return PlacemarkModel.Property.query(on: req.db)
			.filter(\.$kind == kind)
			.all()
			.flatMapEachThrowing { try $0.localized(in: .en) }
	}
	
}
