//
//  Placemark+Property.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark {
	
	final class Property: Model {
		
		static let schema = "placemark_properties"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "type")
		var type: PropertyType
		
		@Field(key: "human_id")
		var humanId: String
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$property, to: \.$placemark)
		var placemarks: [Placemark]
		
		init() {}
		
		init(id: UUID? = nil, type: PropertyType, humanId: String) {
			self.id = id
			self.type = type
			self.humanId = humanId
		}
		
	}
	
}
