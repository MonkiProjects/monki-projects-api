//
//  Placemark+Details.swift
//  Models
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension PlacemarkModel {
	
	public final class Details: Model {
		
		public typealias Placemark = PlacemarkModel
		public typealias Location = Placemark.Location
		public typealias Property = Placemark.Property
		
		public static let schema = "placemark_details"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "placemark_id")
		public var placemark: Placemark
		
		@Field(key: "caption")
		public var caption: String
		
		@Field(key: "satellite_image")
		public var satelliteImageId: String
		
		@Field(key: "images")
		public var images: [String]
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$details, to: \.$property)
		public var properties: [Property]
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		public var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		public var deletedAt: Date?
		
		public init() {}
		
		public init(
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
	
}
