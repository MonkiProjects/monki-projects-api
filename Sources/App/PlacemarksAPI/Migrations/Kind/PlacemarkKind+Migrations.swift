//
//  PlacemarkKind+Migrations.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkModel.Kind {
	
	enum Migrations {
		
		typealias Migrated = PlacemarkModel.Kind
		
		static var all: [Migration] {
			Category.Migrations.all
				+ [CreatePlacemarkKind(), AddInitialKinds()]
		}
		
	}
	
}
