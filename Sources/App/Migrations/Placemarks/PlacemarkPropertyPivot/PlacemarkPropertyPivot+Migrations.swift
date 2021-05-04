//
//  PlacemarkPropertyPivot+Migrations.swift
//  Migrations
//
//  Created by Rémi Bardon on 09/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent

extension PlacemarkPropertyPivot {
	
	enum Migrations {
		
		static var all: [Migration] {
			[CreatePlacemarkPropertyPivot()]
		}
		
	}
	
}
