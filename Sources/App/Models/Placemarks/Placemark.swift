//
//  Placemark.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

final class Placemark: Model {
	
	static let schema = "placemarks"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "latitude")
	var latitude: Double
	
	@Field(key: "longitude")
	var longitude: Double
	
	@Parent(key: "type_id")
	var type: PlacemarkType
	
	@Field(key: "state")
	var state: State
	
	@Parent(key: "creator_id")
	var creator: User
	
	@Field(key: "caption")
	var caption: String
	
	@Field(key: "satellite_image")
	var satelliteImage: String
	
	@Field(key: "images")
	var images: [String]
	
	@OptionalParent(key: "location_id")
	var location: Location?
	
	@Siblings(through: PlacemarkPropertyPivot.self, from: \.$placemark, to: \.$property)
	var properties: [Property]
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	@Timestamp(key: "deleted_at", on: .delete)
	var deletedAt: Date?
	
	init() {}
	
	init(
		id: UUID? = nil,
		name: String,
		latitude: Double,
		longitude: Double,
		typeId: PlacemarkType.IDValue,
		state: State = .submitted,
		creatorId: User.IDValue,
		caption: String,
		images: [String] = []
	) {
		self.id = id
		self.name = name
		self.latitude = latitude
		self.longitude = longitude
		self.$type.id = typeId
		self.state = state
		self.$creator.id = creatorId
		self.caption = caption
		self.satelliteImage = "https://monkiprojects.com/images/satellite-view-placeholder.jpg"
		self.images = images
	}
	
	// FIXME: Add a method to trigger location reverse geocoding
	
}
