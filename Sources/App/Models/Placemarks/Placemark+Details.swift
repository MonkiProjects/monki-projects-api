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
		var satelliteImage: String
		
		@Field(key: "images")
		var images: [String]
		
		@OptionalParent(key: "location_id")
		var location: Location?
		
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
			satelliteImage: String? = nil,
			locationId: Location.IDValue? = nil
		) {
			self.id = id
			self.$placemark.id = placemarkId
			self.caption = caption
			self.satelliteImage = satelliteImage ?? "https://monkiprojects.com/images/satellite-view-placeholder.jpg"
			self.images = images
			self.$location.id = locationId
		}
		
	}
	
}
