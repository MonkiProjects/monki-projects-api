//
//  Placemark+Kind.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Models.Placemark {
	
	final class Kind: Model {
		
		typealias Category = Models.Placemark.Category
		
		static let schema = "placemark_kinds"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "human_id")
		var humanId: String
		
		@Parent(key: "category_id")
		var category: Category
		
		init() {}
		
		init(
			id: IDValue? = nil,
			humanId: String,
			categoryId: Category.IDValue
		) {
			self.id = id
			self.humanId = humanId
			self.$category.id = categoryId
		}
		
	}
	
}
