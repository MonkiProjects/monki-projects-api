//
//  PlacemarkSatelliteViewJob.swift
//  Jobs
//
//  Created by Rémi Bardon on 21/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import Queues
import Helpers
import Models
import APIs

public struct PlacemarkSatelliteViewJobPayload: Codable {
	
	let placemarkId: PlacemarkModel.IDValue
	let latitude, longitude: Double
	
	public init(placemarkId: PlacemarkModel.IDValue, latitude: Double, longitude: Double) {
		self.placemarkId = placemarkId
		self.latitude = latitude
		self.longitude = longitude
	}
	
}

public struct PlacemarkSatelliteViewJob: Job {
	
	public typealias Payload = PlacemarkSatelliteViewJobPayload
	
	public func dequeue(_ context: QueueContext, _ payload: Payload) -> EventLoopFuture<Void> {
		// Get upload URL
		let uploadUrlFuture = context.eventLoop.makeSucceededFuture((payload.latitude, payload.longitude))
			.flatMapThrowing { lat, long in
				try mapboxApi.satelliteImage(lat: lat, long: long).requireURL()
			}
			.flatMapThrowing { url in
				try cloudinaryApi.uploadSateliteImage(from: url).requireURI()
			}
		
		struct UploadResponse: Content {
			let publicId: String
		}
		
		// Upload image
		let uploadFuture = uploadUrlFuture
			.flatMap { context.application.client.post($0) }
			.flatMapThrowing { (res: ClientResponse) -> String in
				guard res.status == .ok else {
					// TODO: Add logs
					throw Abort(.internalServerError, reason: "Could not upload satellite image: \(res.status)")
				}
				
				return try res.content.decode(UploadResponse.self).publicId
			}
		
		// Update URL in Details
		return uploadFuture
			.flatMap { (satelliteImageId: String) in
				PlacemarkModel.Details.query(on: context.application.db)
					.filter(\.$placemark.$id == payload.placemarkId)
					.first()
					.unwrap(or: Abort(.internalServerError, reason: "Cannot find placemark details."))
					.passthrough { $0.satelliteImageId = satelliteImageId }
					.flatMap { $0.update(on: context.application.db) }
			}
	}
	
}
