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
			return req.placemarks.getAllPaged(state: state, creator: userId, pageRequest)
				.asPublic(on: req.db)
		case .submitted, .published, .rejected:
			return req.placemarks.getAllPaged(state: state, creator: nil, pageRequest)
				.asPublic(on: req.db)
		}
	}
	
	func createPlacemark() throws -> EventLoopFuture<Placemark.Public> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		// Validate and decode data
		try Placemark.Create.validate(content: req)
		let create = try req.content.decode(Placemark.Create.self)
		
		// Do additional validations
		// TODO: Check for near spots (e.g. < 20m)
		
		let placemarkKindFuture = req.placemarkKinds.get(humanId: create.kind.rawValue)
		
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
				.sequencedFlatMapEach { kind, propertyIds -> EventLoopFuture<Void> in
					req.eventLoop.makeSucceededFuture(propertyIds)
						.sequencedFlatMapEach { propertyId -> EventLoopFuture<Void> in
							// Find property
							req.placemarkProperties.unsafeGet(kind: kind, humanId: propertyId)
								// Abort if invalid
								.unwrap(or: Abort(
									.badRequest,
									reason: "Invalid property: { \"kind\": \"\(kind)\", \"id\": \"\(propertyId)\" }"
								))
								// Add property
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
			.passthroughAfter { placemark in
				req.queues(.placemarks)
					.dispatch(
						PlacemarkSatelliteViewJob.self,
						.init(
							placemarkId: try placemark.requireID(),
							latitude: placemark.latitude,
							longitude: placemark.longitude
						)
					)
			}
		
		// Trigger location reverse geocoding
		let reverseGeocodeLocationFuture = loadSatelliteViewFuture
			.passthroughAfter { placemark in
				req.queues(.placemarks)
					.dispatch(
						PlacemarkLocationJob.self,
						.init(
							placemarkId: try placemark.requireID(),
							latitude: placemark.latitude,
							longitude: placemark.longitude
						)
					)
			}
		
		return reverseGeocodeLocationFuture
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func getPlacemark() throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		return req.placemarks.get(placemarkId)
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func deletePlacemark() throws -> EventLoopFuture<HTTPStatus> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		let placemarkFuture = req.placemarks.get(placemarkId)
		
		// Do additional validations
		let guardAuthorizedFuture = placemarkFuture.guard({ placemark in
			placemark.$creator.id == user.id
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's placemark!"))
		
		let deleteDetailsFuture = guardAuthorizedFuture
			.passthroughAfter { _ in
				req.placemarkDetails.delete(for: placemarkId, force: false)
			}
		
		return deleteDetailsFuture
			.flatMap { $0.delete(on: req.db) }
			.transform(to: .noContent)
	}
	
	func listProperties() throws -> EventLoopFuture<[Placemark.Property.Localized]> {
		let kind = try req.query.get(Placemark.Property.Kind.self, at: "kind")
		
		return req.placemarkProperties.getAll(kind: kind)
			.flatMapEachThrowing { try $0.localized(in: .en) }
	}
	
}
