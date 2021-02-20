//
//  PlacemarkProperty+Localized.swift
//  App
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension Models.Placemark.Property {
	
	// FIXME: Localize in custom language
	func localized() throws -> Placemark.Property.Localized {
		switch Placemark.Property.Kind(rawValue: self.kind.rawValue) {
		case .feature:
			return try Placemark.Property.feature(self.humanId).localized()
		case .technique:
			return try Placemark.Property.technique(self.humanId).localized()
		case .benefit:
			return try Placemark.Property.benefit(self.humanId).localized()
		case .hazard:
			return try Placemark.Property.hazard(self.humanId).localized()
		case .none:
			throw Abort(
				.internalServerError,
				reason: "We could not decode a property kind for id '\(self.kind.rawValue)'."
			)
		}
	}
	
}

extension Placemark.Property.Localized: Content {}
