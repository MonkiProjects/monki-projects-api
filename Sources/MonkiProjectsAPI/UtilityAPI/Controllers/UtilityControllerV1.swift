//
//  UtilityControllerV1.swift
//  UtilityAPI
//
//  Created by Rémi Bardon on 13/01/2022.
//  Copyright © 2022 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

internal struct UtilityControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		// GET /utility/v1/coordinates-from-google-maps-url
		routes.get("coordinates-from-google-maps-url", use: getCoordinatesFromGoogleMapsUrl)
	}
	
	func getCoordinatesFromGoogleMapsUrl(req: Request) async throws -> Response {
		let urlString = try req.query.get(String.self, at: "url")
			// `req.query.get` removes percent encoding
			// we need to add it back to construct a `URL`
			.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
			.unwrap(or: Abort(.internalServerError, reason: "Could not decode query keeping percent encoding"))
		req.logger.trace("Received URL string '\(urlString)'")
		
		guard let url = URL(string: urlString) else {
			throw Abort(.badRequest, reason: "The given URL is invalid. Make sure it's correctly URL-encoded.")
		}
		req.logger.trace("URL decoded to <\(url)>")
		
		let coordinates = try await req.utilityService.getCoordinatesFromGoogleMapsUrl(url)
		
		if let coordinates = coordinates {
			return try await coordinates.encodeResponse(for: req)
		} else {
			return Response(status: .noContent)
		}
	}
	
}
