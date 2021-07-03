//
//  PlaceControllerV1.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

internal struct PlaceControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let tokenProtected = routes.grouped([
			AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
			UserModel.Token.authenticator(),
		])
		// POST /places/v1
		tokenProtected.post(use: createPlace)
		
		// GET /places/v1
		tokenProtected
			.grouped(RequireAuthForPrivatePlaceStates())
			.get(use: listPlaces)
		
		try routes.group(":placeId") { place in
			// GET /places/v1/{placeId}
			place.get(use: getPlace)
			
			let tokenProtectedPlace = place.grouped([
				AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
				UserModel.Token.authenticator(),
			])
			// DELETE /places/v1/{placeId}
			tokenProtectedPlace.delete(use: deletePlace)
			
			try place.register(collection: PlaceSubmissionControllerV1())
		}
		
		// GET /places/v1/properties
		routes.get("properties", use: listPlaceProperties)
	}
	
	func listPlaces(req: Request) throws -> EventLoopFuture<Page<Place.Public>> {
		let pageRequest = try req.query.decode(PageRequest.self)
		struct Params: Content {
			let state: Place.State?
		}
		let state = try req.query.decode(Params.self).state ?? .published
		
		return req.placeService
			.listPlaces(
				state: state,
				pageRequest: pageRequest,
				requesterId: { try req.auth.require(UserModel.self, with: .bearer, in: req).requireID() }
			)
			.asPublic(on: req)
	}
	
	func createPlace(req: Request) throws -> EventLoopFuture<Response> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		// Validate and decode data
		try Place.Create.validate(content: req)
		let create = try req.content.decode(Place.Create.self)
		
		return req.placeService.createPlace(create, creatorId: userId)
			.flatMap { $0.asPublic(on: req) }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlace(req: Request) throws -> EventLoopFuture<Place.Public> {
		let placeId = try req.parameters.require("placeId", as: Place.ID.self)
		
		return req.placeRepository.get(placeId)
			.flatMap { $0.asPublic(on: req) }
	}
	
	func deletePlace(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placeId = try req.parameters.require("placeId", as: Place.ID.self)
		
		return req.placeService.deletePlace(placeId, requesterId: userId)
			.transform(to: .noContent)
	}
	
	func listPlaceProperties(req: Request) throws -> EventLoopFuture<[Place.Property.Localized]> {
		let kind = try req.query.get(Place.Property.Kind.ID.self, at: "kind")
		
		return req.placePropertyRepository.getAll(kind: kind)
			.flatMapEachThrowing { try $0.localized(in: .en) }
	}
	
}
