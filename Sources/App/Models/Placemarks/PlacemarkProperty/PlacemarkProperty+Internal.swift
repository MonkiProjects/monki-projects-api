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
			print("[DEBUG][PACKAGE_RESOURCES] Did find 'PlacemarkProperties' file at \(url)")
			let data = try Data(contentsOf: url)
			print("[DEBUG][PACKAGE_RESOURCES] Did find data")
			let result = try PropertyListDecoder().decode([Self].self, from: data)
			print("[DEBUG][PACKAGE_RESOURCES] Did decode \(result)")
			return result
		}
		
	}
	
}
