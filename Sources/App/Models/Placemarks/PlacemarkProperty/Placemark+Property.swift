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

extension Models.Placemark {
	
	final class Property: Model {
		
		typealias Kind = MonkiMapModel.Placemark.Property.Kind
		
		static let schema = "placemark_properties"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "kind")
		var kind: Kind
		
		@Field(key: "human_id")
		var humanId: String
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$property, to: \.$details)
		var details: [Details]
		
		init() {}
		
		init(id: IDValue? = nil, kind: Kind, humanId: String) {
			self.id = id
			self.kind = kind
			self.humanId = humanId
		}
		
	}
	
}
