//
//  Place+Kind.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

extension PlaceModel {
	
	public final class Kind: Model {
		
		public typealias Category = PlaceModel.Category
		
		public static let schema = "place_kinds"
		
		@ID(key: .id)
		public var id: UUID?
		
		@Field(key: "human_id")
		public var humanId: String
		
		@Parent(key: "category_id")
		public var category: Category
		
		public init() {}
		
		public init(
			id: PlaceModel.Kind.IDValue? = nil,
			humanId: String,
			categoryId: Category.IDValue
		) {
			self.id = id
			self.humanId = humanId
			self.$category.id = categoryId
		}
		
	}
	
}
