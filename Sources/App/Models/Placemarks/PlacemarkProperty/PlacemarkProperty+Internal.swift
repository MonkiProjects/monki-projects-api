//
//  PlacemarkCategory+Internal.swift
//  App
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation

extension Placemark.Property {
	
	struct Internal: Decodable {
		
		let id, title: String
		let type: Placemark.Property.PropertyType
		
		static func all() throws -> [Self] {
			let url = try Bundle.module.url(forResource: "PlacemarkProperties", withExtension: "plist").require()
			let data = try Data(contentsOf: url)
			return try PropertyListDecoder().decode([Self].self, from: data)
		}
		
	}
	
}
