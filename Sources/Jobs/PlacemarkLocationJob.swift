//
//  PlacemarkLocationJob.swift
//  Jobs
//
//  Created by Rémi Bardon on 21/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import Queues
import Models
import APIs

public struct PlacemarkLocationJobPayload: Codable {
	
	let placemarkId: PlacemarkModel.IDValue
	let latitude, longitude: Double
	
	public init(placemarkId: PlacemarkModel.IDValue, latitude: Double, longitude: Double) {
		self.placemarkId = placemarkId
		self.latitude = latitude
		self.longitude = longitude
	}
	
}

public struct PlacemarkLocationJob: Job {
	
	public typealias Payload = PlacemarkLocationJobPayload
	
	public func dequeue(_ context: QueueContext, _ payload: Payload) -> EventLoopFuture<Void> {
		// Get reverse geocoding URL
		let reverseGeocodingUrlFuture = context.eventLoop.makeSucceededFuture((payload.latitude, payload.longitude))
			.flatMapThrowing { lat, long in
				try mapboxApi.reverseGeocodeLocation(lat: lat, long: long).requireURI()
			}
		
		struct ReverseGeocodingResponse: Content {
			struct Feature: Content {
				struct Context: Content {
					let id: String
					let text: String
				}
				let text: String
				let context: [Context]
			}
			let features: [Feature]
		}
		
		// Call reverse geocoding API
		let reverseGeocodingFuture = reverseGeocodingUrlFuture
			.flatMap { context.application.client.get($0) }
			.flatMapThrowing { (res: ClientResponse) -> ReverseGeocodingResponse in
				guard res.status == .ok else {
					throw Abort(.internalServerError, reason: "Could not call reverse geocoding API.")
				}
				
				// Map "application/vnd.geo+json" to "application/json" (to fix decoding)
				var jsonRes = res
				if jsonRes.headers.contentType?.subType == "vnd.geo+json" {
					jsonRes.headers.contentType = HTTPMediaType.json
				}
				return try jsonRes.content.decode(ReverseGeocodingResponse.self)
			}
		
		// Update Location in Details
		return reverseGeocodingFuture
			.flatMap { response in
				PlacemarkModel.Details.query(on: context.application.db)
					.filter(\.$placemark.$id == payload.placemarkId)
					.first()
					.unwrap(or: Abort(.internalServerError, reason: "Cannot find placemark details."))
					.map { (response, $0) }
			}
			.flatMapThrowing { response, details -> PlacemarkModel.Location in
				let feature = response.features[0]
				let city = feature.text
				let country = try feature.context
					.first(where: { $0.id.starts(with: "country") })
					.require()
					.text
				
				return try .init(
					detailsId: details.requireID(),
					city: city,
					country: country
				)
			}
			.flatMap { $0.create(on: context.application.db) }
	}
	
}
