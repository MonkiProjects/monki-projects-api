//
//  PlacemarkControllerV1.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import Models
import Jobs
import MonkiMapModel
import GEOSwift

internal struct PlacemarkControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let tokenProtected = routes.grouped(UserModel.Token.authenticator())
		// POST /placemarks/v1
		tokenProtected.post(use: createPlacemark)
		
		// GET /placemarks/v1
		tokenProtected
			.grouped(RequireAuthForPrivatePlacemarkStates())
			.get(use: listPlacemarks)
		
		try routes.group(":placemarkId") { placemark in
			// GET /placemarks/v1/{placemarkId}
			placemark.get(use: getPlacemark)
			
			let tokenProtected = placemark.grouped(UserModel.Token.authenticator())
			// DELETE /placemarks/v1/{placemarkId}
			tokenProtected.delete(use: deletePlacemark)
			
			try placemark.register(collection: PlacemarkSubmissionControllerV1())
		}
		
		// GET /placemarks/v1/features
		routes.get("features", use: listPlacemarkFeatures)
		// GET /placemarks/v1/techniques
		routes.get("techniques", use: listPlacemarkTechniques)
		// GET /placemarks/v1/benefits
		routes.get("benefits", use: listPlacemarkBenefits)
		// GET /placemarks/v1/hazards
		routes.get("hazards", use: listPlacemarkHazards)
	}
	
	func listPlacemarksRaw(req: Request) throws -> EventLoopFuture<Page<Placemark.Public>> {
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
	
	func listPlacemarks(req: Request) throws -> EventLoopFuture<Page<GEOSwift.Feature>> {
		try listPlacemarksRaw(req: req).flatMapThrowing { page in
			try Page(items: page.items.map { try $0.asGeoJSON() }, metadata: page.metadata)
		}
	}
	
	func createPlacemarkRaw(req: Request) throws -> EventLoopFuture<Placemark.Public> {
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
//			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func createPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		try self.createPlacemarkRaw(req: req)
			.flatMapThrowing { try $0.asGeoJSON() }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemarkRaw(req: Request) throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		return PlacemarkModel.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func getPlacemark(req: Request) throws -> EventLoopFuture<GEOSwift.Feature> {
		try getPlacemarkRaw(req: req).flatMapThrowing { try $0.asGeoJSON() }
	}
	
	func deletePlacemark(req: Request) throws -> EventLoopFuture<HTTPStatus> {
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
	
	func listPlacemarkFeatures(req: Request) -> EventLoopFuture<[Placemark.Property.Localized]> {
		listProperties(ofKind: .feature, in: req.db)
	}
	
	func listPlacemarkTechniques(req: Request) -> EventLoopFuture<[Placemark.Property.Localized]> {
		listProperties(ofKind: .technique, in: req.db)
	}
	
	func listPlacemarkBenefits(req: Request) -> EventLoopFuture<[Placemark.Property.Localized]> {
		listProperties(ofKind: .benefit, in: req.db)
	}
	
	func listPlacemarkHazards(req: Request) -> EventLoopFuture<[Placemark.Property.Localized]> {
		listProperties(ofKind: .hazard, in: req.db)
	}
	
	private func listProperties(
		ofKind kind: Placemark.Property.Kind,
		in database: Database
	) -> EventLoopFuture<[Placemark.Property.Localized]> {
		PlacemarkModel.Property.query(on: database)
			.filter(\.$kind == kind)
			.all()
			.flatMapEachThrowing { try $0.localized(in: .en) }
	}
	
}
