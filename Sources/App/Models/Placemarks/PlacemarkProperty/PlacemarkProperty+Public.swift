//
//  PlacemarkProperty+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension Placemark.Property {
	
	struct Public: Content, Equatable {
		
		let id: String
		
	}
	
	func asPublic() -> Public {
		Public(
			id: self.humanId
		)
	}
	
}
