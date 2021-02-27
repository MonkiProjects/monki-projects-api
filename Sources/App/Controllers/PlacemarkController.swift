//
//  PlacemarkController.swift
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

internal struct PlacemarkController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let placemarks = routes.grouped("placemarks")
		
		let tokenProtected = placemarks.grouped(UserModel.Token.authenticator())
		// POST /placemarks
		tokenProtected.post(use: createPlacemark)
		
		// GET /placemarks
		tokenProtected
			.grouped(RequireAuthForPrivatePlacemarkStates())
			.get(use: listPlacemarks)
		
		try placemarks.group(":placemarkId") { placemark in
			// GET /placemarks/{placemarkId}
			placemark.get(use: getPlacemark)
			
			let tokenProtected = placemark.grouped(UserModel.Token.authenticator())
			// DELETE /placemarks/{placemarkId}
			tokenProtected.delete(use: deletePlacemark)
			
			try placemark.register(collection: PlacemarkSubmissionController())
		}
		
		// GET /placemarks/features
		placemarks.get("features", use: listPlacemarkFeatures)
		// GET /placemarks/techniques
		placemarks.get("techniques", use: listPlacemarkTechniques)
		// GET /placemarks/benefits
		placemarks.get("benefits", use: listPlacemarkBenefits)
		// GET /placemarks/hazards
		placemarks.get("hazards", use: listPlacemarkHazards)
	}
	
	func listPlacemarks(req: Request) throws -> EventLoopFuture<[Placemark.Public]> {
		struct Params: Content {
			let state: Placemark.State?
		}
		let state = try req.query.decode(Params.self).state ?? .published
		
		switch state {
		case .unknown:
			throw Abort(.forbidden, reason: "Fetching placemarks in 'unknown' state is impossible.")
		case .draft, .local, .private:
			let userId = try req.auth.require(UserModel.self).requireID()
			return try listUserPlacemarks(userId: userId, state: state, in: req.db)
		case .submitted, .published, .rejected:
			return try listPlacemarks(state: state, in: req.db)
		}
	}
	
	func listPlacemarks(
		state: Placemark.State,
		in database: Database
	) throws -> EventLoopFuture<[Placemark.Public]> {
		PlacemarkModel.query(on: database)
			.filter(\.$state == state)
			.all()
			.asPublic(on: database)
	}
	
	func listUserPlacemarks(
		userId: UserModel.IDValue,
		state: Placemark.State,
		in database: Database
	) throws -> EventLoopFuture<[Placemark.Public]> {
		PlacemarkModel.query(on: database)
			.filter(\.$creator.$id == userId)
			.filter(\.$state == state)
			.all()
			.asPublic(on: database)
	}
	
	func createPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		let user = try req.auth.require(UserModel.self)
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
		
		// FIXME: Add properties
		
		// Create placemark details
		let createDetailsFuture = createPlacemarkFuture
			.passthroughAfter { placemark in
				try PlacemarkModel.Details(
					placemarkId: placemark.requireID(),
					caption: create.caption,
					images: (create.images ?? []).map { $0.absoluteString }
				)
				.create(on: req.db)
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
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemark(req: Request) throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		return PlacemarkModel.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.flatMap { $0.asPublic(on: req.db) }
	}
	
	func deletePlacemark(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let user = try req.auth.require(UserModel.self)
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
