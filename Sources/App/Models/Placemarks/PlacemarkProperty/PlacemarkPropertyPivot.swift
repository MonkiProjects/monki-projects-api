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
	
	typealias Details = Models.Placemark.Details
	typealias Property = Models.Placemark.Property
	
	static let schema = "placemark+property"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "details_id")
	var details: Details
	
	@Parent(key: "property_id")
	var property: Property
	
	init() {}
	
	init(id: IDValue? = nil, detailsId: Details.IDValue, propertyId: Property.IDValue) {
		self.id = id
		self.$details.id = detailsId
		self.$property.id = propertyId
	}
	
}
