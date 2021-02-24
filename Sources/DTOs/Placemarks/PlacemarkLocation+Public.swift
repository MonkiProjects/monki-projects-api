//
//  PlacemarkLocation+Public.swift
//  DTOs
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Models
import MonkiMapModel

extension PlacemarkModel.Location {
	
	public func asPublic() -> Placemark.Location.Public {
		.init(
			city: self.city,
			country: self.country
		)
	}
	
}

extension Placemark.Location.Public: Content {}
