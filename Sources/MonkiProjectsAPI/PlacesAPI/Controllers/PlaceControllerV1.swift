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
			.grouped(RequireAuthForPrivatePlaceVisibilities())
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
	
	func listPlaces(req: Request) async throws -> Page<Place.Public> {
		let pageRequest = try req.query.decode(PageRequest.self)
		struct Params: Content {
			let visibility: Place.Visibility?
			let includeDraft: Bool?
		}
		let params = try req.query.decode(Params.self)
		let visibility = params.visibility ?? .public
		let includeDraft = params.includeDraft ?? false
		
		return try await req.placeService
			.listPlaces(
				visibility: visibility,
				includeDraft: includeDraft,
				pageRequest: pageRequest,
				requesterId: { try req.auth.require(UserModel.self, with: .bearer, in: req).requireID() }
			)
			.asPublic(on: req)
	}
	
	func createPlace(req: Request) async throws -> Response {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		// Validate and decode data
		try Place.Create.validate(content: req)
		let create = try req.content.decode(Place.Create.self)
		
		let place = try await req.placeService
			.createPlace(create, creatorId: userId)
			.asPublic(on: req)
		
		return try await place.encodeResponse(status: .created, for: req)
	}
	
	func getPlace(req: Request) async throws -> Place.Public {
		let placeId = try req.parameters.require("placeId", as: Place.ID.self)
		
		return try await req.placeRepository.get(placeId).asPublic(on: req)
	}
	
	func deletePlace(req: Request) async throws -> HTTPStatus {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placeId = try req.parameters.require("placeId", as: Place.ID.self)
		
		try await req.placeService.deletePlace(placeId, requesterId: userId)
		
		return HTTPStatus.noContent
	}
	
	func listPlaceProperties(req: Request) async throws -> [Place.Property.Localized] {
		let kind = try req.query.get(Place.Property.Kind.ID.self, at: "kind")
		
		return try await req.placePropertyRepository.getAll(kind: kind)
			.localized(in: .en)
	}
	
}
