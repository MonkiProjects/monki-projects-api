//
//  PlacemarkLocationPublic+JSON.swift
//  DTOs
//
//  Created by Rémi Bardon on 15/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import MonkiMapModel
import GEOSwift

extension Placemark.Location.Public {
	
	public func asJSON() -> JSON {
		JSON.object([
			"city": JSON.string(self.city),
			"country": JSON.string(self.country),
		])
	}
	
}
