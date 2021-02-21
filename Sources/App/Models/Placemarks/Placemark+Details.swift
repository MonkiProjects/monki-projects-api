//
//  Placemark+Details.swift
//  App
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Models.Placemark {
	
	final class Details: Model {
		
		typealias Placemark = Models.Placemark
		typealias Location = Placemark.Location
		typealias Property = Placemark.Property
		
		static let schema = "placemark_details"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "placemark_id")
		var placemark: Placemark
		
		@Field(key: "caption")
		var caption: String
		
		@Field(key: "satellite_image")
		var satelliteImageId: String
		
		@Field(key: "images")
		var images: [String]
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$details, to: \.$property)
		var properties: [Property]
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: IDValue? = nil,
			placemarkId: Placemark.IDValue,
			caption: String,
			images: [String] = [],
			satelliteImageId: String? = nil
		) {
			self.id = id
			self.$placemark.id = placemarkId
			self.caption = caption
			self.satelliteImageId = satelliteImageId ?? "satellite_images/satellite-view-placeholder.jpg"
			self.images = images
		}
		
	}
	
	func updateSatelliteImage(on req: Request) -> EventLoopFuture<String> {
		return req.eventLoop.makeSucceededFuture((self.latitude, self.longitude))
			.flatMapThrowing { lat, long in
				try mapboxApi.satelliteImage(lat: lat, long: long).requireURL()
			}
			.flatMapThrowing { url in
				try cloudinaryApi.uploadSateliteImage(from: url).requireURI()
			}
			.flatMap { req.client.post($0) }
			.flatMapThrowing { (res: ClientResponse) in
				guard res.status == .ok else {
					throw Abort(.internalServerError, reason: "Could not upload satellite image.")
				}
				
				struct UploadResponse: Content {
					let publicId: String
				}
				return try res.content.decode(UploadResponse.self).publicId
			}
	}
	
}
