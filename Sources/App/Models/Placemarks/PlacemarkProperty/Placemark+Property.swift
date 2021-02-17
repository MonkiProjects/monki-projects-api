//
//  Placemark+Property.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension Placemark.Details.Model {
	
	typealias Property = Placemark.Property.Model
	
}

extension Placemark.Property {
	
	final class Model: Fluent.Model {
		
		static let schema = "placemark_properties"
		
		@IDProperty<Placemark.Property.Model, UUID>(key: .id)
		var id: UUID?
		
		@Field(key: "kind")
		var kind: Kind
		
		@Field(key: "human_id")
		var humanId: String
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$property, to: \.$details)
		var details: [Placemark.Details.Model]
		
		init() {}
		
		init(id: IDValue? = nil, kind: Kind, humanId: String) {
			self.id = id
			self.kind = kind
			self.humanId = humanId
		}
		
	}
	
}
