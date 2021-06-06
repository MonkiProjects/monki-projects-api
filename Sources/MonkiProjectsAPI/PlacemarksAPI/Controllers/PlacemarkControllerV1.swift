//
//  PlacemarkControllerV1.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

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
		
		// GET /placemarks/v1/properties
		routes.get("properties", use: listPlacemarkProperties)
	}
	
	func listPlacemarks(req: Request) throws -> EventLoopFuture<Page<Placemark.Public>> {
		let pageRequest = try req.query.decode(PageRequest.self)
		struct Params: Content {
			let state: Placemark.State?
		}
		let state = try req.query.decode(Params.self).state ?? .published
		
		return req.placemarkService
			.listPlacemarks(
				state: state,
				pageRequest: pageRequest,
				requesterId: { try req.auth.require(UserModel.self, with: .bearer, in: req).requireID() }
			)
			.asPublic(on: req)
	}
	
	func createPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		// Validate and decode data
		try Placemark.Create.validate(content: req)
		let create = try req.content.decode(Placemark.Create.self)
		
		return req.placemarkService.createPlacemark(create, creatorId: userId)
			.flatMap { $0.asPublic(on: req) }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemark(req: Request) throws -> EventLoopFuture<Placemark.Public> {
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		return req.placemarkRepository.get(placemarkId)
			.flatMap { $0.asPublic(on: req) }
	}
	
	func deletePlacemark(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let userId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let placemarkId = try req.parameters.require("placemarkId", as: UUID.self)
		
		return req.placemarkService.deletePlacemark(placemarkId, requesterId: userId)
			.transform(to: .noContent)
	}
	
	func listPlacemarkProperties(req: Request) throws -> EventLoopFuture<[Placemark.Property.Localized]> {
		let kind = try req.query.get(Placemark.Property.Kind.ID.self, at: "kind")
		
		return req.placemarkPropertyRepository.getAll(kind: kind)
			.flatMapEachThrowing { try $0.localized(in: .en) }
	}
	
}
