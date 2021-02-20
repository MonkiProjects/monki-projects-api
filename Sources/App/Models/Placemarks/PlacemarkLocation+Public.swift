//
//  PlacemarkLocation+Public.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Models.Placemark.Location {
	
	func asPublic() -> Placemark.Location.Public {
		return .init(
			city: self.city,
			country: self.country
		)
	}
	
}

extension Placemark.Location.Public: Content {}
