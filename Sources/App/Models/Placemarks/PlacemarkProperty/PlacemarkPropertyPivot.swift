//
//  PlacemarkPropertyPivot.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

final class PlacemarkPropertyPivot: Model {
	
	static let schema = "placemark+property"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "details_id")
	var details: Placemark.Details.Model
	
	@Parent(key: "property_id")
	var property: Placemark.Property.Model
	
	init() {}
	
	init(
		id: IDValue? = nil,
		detailsId: Placemark.Details.Model.IDValue,
		propertyId: Placemark.Property.Model.IDValue
	) {
		self.id = id
		self.$details.id = detailsId
		self.$property.id = propertyId
	}
	
}
