//
//  Placemark+Category.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension PlacemarkModel {
	
	public final class Category: Model {
		
		public static let schema = "placemark_categories"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Field(key: "human_id")
		public var humanId: String
		
		public init() {}
		
		public init(id: IDValue? = nil, humanId: String) {
			self.id = id
			self.humanId = humanId
		}
		
	}
	
}
