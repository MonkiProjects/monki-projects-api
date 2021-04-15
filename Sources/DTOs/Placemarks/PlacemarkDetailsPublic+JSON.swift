//
//  PlacemarkDetailsPublic+JSON.swift
//  DTOs
//
//  Created by Rémi Bardon on 14/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import MonkiMapModel
import GEOSwift

extension Placemark.Details.Public {
	
	public func asJSON() -> JSON {
		let location: JSON = self.location.map { $0.asJSON() } ?? JSON.null
		var properties = [String: JSON]()
		for (kind, array) in self.properties {
			properties[kind.rawValue] = JSON.array(array.map { $0.asJSON() })
		}
		
		return JSON.object([
			"caption": JSON.string(self.caption),
			"satelliteImage": JSON.string(self.satelliteImage.absoluteString),
			"images": JSON.array(self.images.map { JSON.string($0.absoluteString) }),
			"location": location,
			"properties": JSON.object(properties),
		])
	}
	
}
