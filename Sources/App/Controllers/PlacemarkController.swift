//
//  PlacemarkController.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

struct PlacemarkController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let placemarks = routes.grouped("placemarks")
		
		let tokenProtected = placemarks.grouped(UserModel.Token.authenticator())
		// POST /placemarks
		tokenProtected.post(use: createPlacemark)
		
		// GET /placemarks
		placemarks.get(use: listPlacemarks)
		
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
		case .private:
			// TODO: Return user's private placemarks if a token was provided
			throw Abort(.notImplemented, reason: "Fetching your private placemarks is not yet possible")
		case .submitted, .published, .rejected:
			return try listPlacemarks(state: state, in: req.db)
		}
	}
	
	func listPlacemarks(state: Placemark.State, in database: Database) throws -> EventLoopFuture<[Placemark.Public]> {
		return Placemark.query(on: database)
			.filter(\.$state == state)
			.with(\.$type) { type in
				type.with(\.$category)
			}
			.with(\.$creator)
			.with(\.$properties)
			.all()
			.flatMapEachThrowing { try $0.asPublic() }
	}
	
	func createPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		let user = try req.auth.require(UserModel.self)
		// Validate and decode data
		try Placemark.Create.validate(content: req)
		let create = try req.content.decode(Placemark.Create.self)
		
		// Do additional validations
		// TODO: Check for near spots (e.g. < 20m)
		
		let placemarkTypeFuture = Placemark.PlacemarkType.query(on: req.db)
			.filter(\.$humanId == create.type)
			.first()
			.unwrap(or: Abort(.notFound, reason: "Placemark type not found"))
		
		// Create Placemark object
		let placemarkFuture = placemarkTypeFuture.flatMapThrowing { type in
			try Placemark(
				name: create.name,
				latitude: create.latitude,
				longitude: create.longitude,
				typeId: type.requireID(),
				state: .private,
				creatorId: user.requireID(),
				caption: create.caption,
				images: (create.images ?? []).map { $0.absoluteString }
			)
		}
		
		// FIXME: Add properties
		
		// Save Placemark in database
		let createPlacemarkFuture = placemarkFuture.flatMap { placemark in
			placemark.create(on: req.db)
				.flatMap { placemark.$type.load(on: req.db) }
				.flatMap { placemark.type.$category.load(on: req.db) }
				.flatMap { placemark.$creator.load(on: req.db) }
				.flatMap { placemark.$properties.load(on: req.db) }
				.transform(to: placemark)
		}
		
		return createPlacemarkFuture
			.flatMapThrowing { try $0.asPublic() }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemark(req: Request) throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		return Placemark.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
			.flatMap { placemark in
				placemark.$type.load(on: req.db)
					.flatMap { placemark.type.$category.load(on: req.db) }
					.flatMap { placemark.$creator.load(on: req.db) }
					.flatMap { placemark.$properties.load(on: req.db) }
					.transform(to: placemark)
			}
			.flatMapThrowing { try $0.asPublic() }
	}
	
	func deletePlacemark(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let user = try req.auth.require(UserModel.self)
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		let placemarkFuture = Placemark.find(placemarkId, on: req.db)
			.unwrap(or: Abort(.notFound, reason: "Placemark not found"))
		
		// Do additional validations
		let guardAuthorizedFuture = placemarkFuture.guard({ placemark in
			placemark.$creator.id == user.id
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's placemark!"))
		
		let deletePropertiesFuture = guardAuthorizedFuture
			.flatMap { placemark in
				PlacemarkPropertyPivot.query(on: req.db)
					.filter(\.$placemark.$id == placemarkId)
					.all()
					.flatMap { $0.delete(on: req.db) }
					.transform(to: placemark)
			}
		
		return deletePropertiesFuture
			.flatMap { $0.delete(on: req.db) }
			.transform(to: .ok)
	}
	
	func listPlacemarkFeatures(req: Request) -> EventLoopFuture<[Placemark.Property.Public]> {
		listProperties(ofType: .feature, in: req.db)
	}
	
	func listPlacemarkTechniques(req: Request) -> EventLoopFuture<[Placemark.Property.Public]> {
		listProperties(ofType: .technique, in: req.db)
	}
	
	func listPlacemarkBenefits(req: Request) -> EventLoopFuture<[Placemark.Property.Public]> {
		listProperties(ofType: .benefit, in: req.db)
	}
	
	func listPlacemarkHazards(req: Request) -> EventLoopFuture<[Placemark.Property.Public]> {
		listProperties(ofType: .hazard, in: req.db)
	}
	
	private func listProperties(
		ofType type: Placemark.Property.PropertyType,
		in database: Database
	) -> EventLoopFuture<[Placemark.Property.Public]> {
		Placemark.Property.query(on: database)
			.filter(\.$type == type)
			.all()
			.mapEach { $0.asPublic() }
	}
	
}
