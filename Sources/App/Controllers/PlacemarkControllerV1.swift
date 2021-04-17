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
		
		// GET /placemarks/v1/properties
		routes.get("properties", use: listPlacemarkProperties)
	}
	
	func listPlacemarks(req: Request) throws -> EventLoopFuture<Page<GEOSwift.Feature>> {
		try PlacemarkService(req: req).listPlacemarks()
			.flatMapThrowing { page in
				try page.map { try $0.asGeoJSON() }
			}
	}
	
	func createPlacemark(req: Request) throws -> EventLoopFuture<Response> {
		try PlacemarkService(req: req).createPlacemark()
			.flatMapThrowing { try $0.asGeoJSON() }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getPlacemark(req: Request) throws -> EventLoopFuture<GEOSwift.Feature> {
		try PlacemarkService(req: req).getPlacemark()
			.flatMapThrowing { try $0.asGeoJSON() }
	}
	
	func deletePlacemark(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		try PlacemarkService(req: req).deletePlacemark()
	}
	
	func listPlacemarkProperties(req: Request) throws -> EventLoopFuture<[Placemark.Property.Localized]> {
		try PlacemarkService(req: req).listProperties()
	}
	
}
