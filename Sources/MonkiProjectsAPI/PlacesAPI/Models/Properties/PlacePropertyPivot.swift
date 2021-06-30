//
//  PlacePropertyPivot.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

public final class PlacePropertyPivot: Model {
	
	public typealias Details = PlaceModel.Details
	public typealias Property = PlaceModel.Property
	
	public static let schema = "place+property"
	
	@ID(key: .id)
	public var id: UUID?
	
	@Parent(key: "details_id")
	public var details: Details
	
	@Parent(key: "property_id")
	public var property: Property
	
	public init() {}
	
	public init(id: IDValue? = nil, detailsId: Details.IDValue, propertyId: Property.IDValue) {
		self.id = id
		self.$details.id = detailsId
		self.$property.id = propertyId
	}
	
}
