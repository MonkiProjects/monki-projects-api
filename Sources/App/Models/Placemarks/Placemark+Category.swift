//
//  Placemark+Category.swift
//  App
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension Models.Placemark {
	
	final class Category: Model {
		
		static let schema = "placemark_categories"
		
		@ID(key: .id)
		var id: UUID?
		
		@Field(key: "human_id")
		var humanId: String
		
		init() {}
		
		init(id: IDValue? = nil, humanId: String) {
			self.id = id
			self.humanId = humanId
		}
		
	}
	
}
