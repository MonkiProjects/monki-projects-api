//
//  Placemark.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

typealias PlacemarkModel = Placemark.Model

extension Placemark {
	
	final class Model: Fluent.Model {
		
		static let schema = "placemarks"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "name")
		var name: String
		
		@Field(key: "latitude")
		var latitude: Double
		
		@Field(key: "longitude")
		var longitude: Double
		
		@Parent(key: "kind_id")
		var kind: Kind
		
		@Field(key: "state")
		var state: State
		
		@Parent(key: "creator_id")
		var creator: UserModel
		
		@Timestamp(key: "created_at", on: .create)
		var createdAt: Date?
		
		@Timestamp(key: "updated_at", on: .update)
		var updatedAt: Date?
		
		@Timestamp(key: "deleted_at", on: .delete)
		var deletedAt: Date?
		
		init() {}
		
		init(
			id: IDValue? = nil,
			name: String,
			latitude: Double,
			longitude: Double,
			kindId: Kind.IDValue,
			state: State = .private,
			creatorId: UserModel.IDValue
		) {
			self.id = id
			self.name = name
			self.latitude = latitude
			self.longitude = longitude
			self.$kind.id = kindId
			self.state = state
			self.$creator.id = creatorId
		}
		
		// FIXME: Add a method to trigger location reverse geocoding
		
	}
	
}
