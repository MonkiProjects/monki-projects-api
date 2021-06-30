//
//  PlaceProperty+Localized.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension PlaceModel.Property {
	
	// FIXME: Localize in custom language
	public func localized(in locale: Locale) throws -> Place.Property.Localized {
		switch Place.Property.Kind.ID(rawValue: self.kind.rawValue) {
		case .feature:
			return try Place.Property.feature(self.humanId).localized(in: locale)
		case .technique:
			return try Place.Property.technique(self.humanId).localized(in: locale)
		case .benefit:
			return try Place.Property.benefit(self.humanId).localized(in: locale)
		case .hazard:
			return try Place.Property.hazard(self.humanId).localized(in: locale)
		case .none:
			throw Abort(
				.internalServerError,
				reason: "We could not decode a property kind for id '\(self.kind.rawValue)'."
			)
		}
	}
	
}

extension Place.Property.Localized: Content {}
