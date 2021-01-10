//
//  Placemark+Location.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark {
	
	final class Location: Model {
		
		static let schema = "placemark_locations"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "city")
		var city: String
		
		@Field(key: "country")
		var country: String
		
		init() {}
		
		init(
			id: UUID? = nil,
			city: String,
			country: String
		) {
			self.id = id
			self.city = city
			self.country = country
		}
		
	}
	
}
