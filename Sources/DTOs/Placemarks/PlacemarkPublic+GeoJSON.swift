//
//  PlacemarkPublic+GeoJSON.swift
//  DTOs
//
//  Created by Rémi Bardon on 14/04/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation
import MonkiMapModel
import GEOSwift

extension Placemark.Public {
	
	public func asGeoJSON() throws -> GEOSwift.Feature {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		
		let createdAt = try String(data: encoder.encode(self.createdAt), encoding: .utf8).require()
		let updatedAt = try String(data: encoder.encode(self.updatedAt), encoding: .utf8).require()
		
		return GEOSwift.Feature(
			geometry: GEOSwift.Point(x: self.latitude, y: self.longitude),
			properties: [
				"name": JSON.string(self.name),
				"kind": JSON.string(self.kind.rawValue),
				"category": JSON.string(self.category.rawValue),
				"state": JSON.string(self.state.rawValue),
				"creator": JSON.string(self.creator.uuidString),
				"details": self.details.asJSON(),
				"createdAt": JSON.string(createdAt),
				"updatedAt": JSON.string(updatedAt),
			],
			id: .string(self.id.uuidString)
		)
	}
	
}
