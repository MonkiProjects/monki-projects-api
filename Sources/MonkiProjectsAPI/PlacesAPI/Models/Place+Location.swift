//
//  Place+Location.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension PlaceModel {
	
	public final class Location: Model {
		
		public typealias Details = PlaceModel.Details
		
		public static let schema = "place_locations"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Parent(key: "details_id")
		public var details: Details
		
		@Field(key: "city")
		public var city: String
		
		@Field(key: "country")
		public var country: String
		
		public init() {}
		
		public init(
			id: PlaceModel.Location.IDValue? = nil,
			detailsId: Details.IDValue,
			city: String,
			country: String
		) {
			self.id = id
			self.$details.id = detailsId
			self.city = city
			self.country = country
		}
		
	}
	
}
