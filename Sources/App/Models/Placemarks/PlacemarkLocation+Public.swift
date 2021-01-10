//
//  PlacemarkLocation+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Location {
	
	struct Public: Content, Equatable {
		
		let city: String
		let country: String
		
	}
	
	func asPublic() -> Public {
		Public(
			city: self.city,
			country: self.country
		)
	}
	
}
