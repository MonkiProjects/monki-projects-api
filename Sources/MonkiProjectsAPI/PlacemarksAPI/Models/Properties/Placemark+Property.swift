//
//  Placemark+Property.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiMapModel

extension PlacemarkModel {
	
	public final class Property: Model {
		
		public typealias Kind = Placemark.Property.Kind.ID
		
		public static let schema = "placemark_properties"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Field(key: "kind")
		public var kind: Kind
		
		@Field(key: "human_id")
		public var humanId: String
		
		@Siblings(through: PlacemarkPropertyPivot.self, from: \.$property, to: \.$details)
		public var details: [Details]
		
		public init() {}
		
		public init(id: IDValue? = nil, kind: Kind, humanId: String) {
			self.id = id
			self.kind = kind
			self.humanId = humanId
		}
		
	}
	
}
