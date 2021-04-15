//
//  PlacemarkPropertyLocalized+JSON.swift
//  DTOs
//
//  Created by Rémi Bardon on 15/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import MonkiMapModel
import GEOSwift

extension Placemark.Property.Localized {
	
	public func asJSON() -> JSON {
		JSON.object([
			"id": JSON.string(self.id),
			"title": JSON.string(self.title),
			"kind": JSON.string(self.kind.rawValue),
		])
	}
	
}
