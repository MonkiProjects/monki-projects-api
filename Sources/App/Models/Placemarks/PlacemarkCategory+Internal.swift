//
//  PlacemarkCategory+Internal.swift
//  App
//
//  Created by Rémi Bardon on 24/06/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation

extension Placemark.Category {
	
	struct Internal: Decodable {
		
		let id, title: String
		
		static func all() throws -> [Self] {
			let url = try Bundle.app.url(forResource: "PlacemarkCategories", withExtension: "plist").require()
			let data = try Data(contentsOf: url)
			return try PropertyListDecoder().decode([Self].self, from: data)
		}
		
	}
	
}
