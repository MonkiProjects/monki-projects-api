//
//  Placemark+Location.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Models.Placemark {
	
	final class Location: Model {
		
		typealias Details = Models.Placemark.Details
		
		static let schema = "placemark_locations"
		
		@ID(key: .id)
		var id: UUID?
		
		@Parent(key: "details_id")
		var details: Details
		
		@Field(key: "city")
		var city: String
		
		@Field(key: "country")
		var country: String
		
		init() {}
		
		init(
			id: IDValue? = nil,
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
