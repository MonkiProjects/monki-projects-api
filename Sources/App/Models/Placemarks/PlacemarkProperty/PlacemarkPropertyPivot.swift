//
//  PlacemarkPropertyPivot.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

final class PlacemarkPropertyPivot: Model {
	
	static let schema = "placemark+property"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "placemark_id")
	var placemark: Placemark
	
	@Parent(key: "property_id")
	var property: Placemark.Property
	
	init() {}
	
	init(
		id: UUID? = nil,
		placemarkId: Placemark.IDValue,
		propertyId: Placemark.Property.IDValue
	) {
		self.id = id
		self.$placemark.id = placemarkId
		self.$property.id = propertyId
	}
	
}
