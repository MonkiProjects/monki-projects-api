//
//  Place+Details.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension PlaceModel {
	
	public final class Details: Model {
		
		public typealias Place = PlaceModel
		public typealias Location = Place.Location
		public typealias Property = Place.Property
		
		public static let schema = "place_details"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "place_id")
		public var place: Place
		
		@Field(key: "caption")
		public var caption: String
		
		@Field(key: "satellite_image")
		public var satelliteImageId: String
		
		@Field(key: "images")
		public var images: [String]
		
		@Siblings(through: PlacePropertyPivot.self, from: \.$details, to: \.$property)
		public var properties: [Property]
		
		@Timestamp(key: "created_at", on: .create)
		public var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		public var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		public var deletedAt: Date?
		
		public init() {}
		
		public init(
			id: PlaceModel.Details.IDValue? = nil,
			placeId: Place.IDValue,
			caption: String,
			images: [String] = [],
			satelliteImageId: String? = nil
		) {
			self.id = id
			self.$place.id = placeId
			self.caption = caption
			self.satelliteImageId = satelliteImageId ?? "satellite_images/satellite-view-placeholder.jpg"
			self.images = images
		}
		
	}
	
}
