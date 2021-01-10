//
//  Placemark+Type.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Placemark {
	
	final class PlacemarkType: Model {
		
		static let schema = "placemark_types"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "human_id")
		var humanId: String
		
		@Parent(key: "category_id")
		var category: Placemark.Category
		
		init() {}
		
		init(
			id: UUID? = nil,
			humanId: String,
			categoryId: Placemark.Category.IDValue
		) {
			self.id = id
			self.humanId = humanId
			self.$category.id = categoryId
		}
		
	}
	
}
