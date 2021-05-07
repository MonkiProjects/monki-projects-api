//
//  PlacemarkProperty+Localized.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 10/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

extension PlacemarkModel.Property {
	
	// FIXME: Localize in custom language
	public func localized(in locale: Locale) throws -> Placemark.Property.Localized {
		switch Placemark.Property.Kind(rawValue: self.kind.rawValue) {
		case .feature:
			return try Placemark.Property.feature(self.humanId).localized(in: locale)
		case .technique:
			return try Placemark.Property.technique(self.humanId).localized(in: locale)
		case .benefit:
			return try Placemark.Property.benefit(self.humanId).localized(in: locale)
		case .hazard:
			return try Placemark.Property.hazard(self.humanId).localized(in: locale)
		case .none:
			throw Abort(
				.internalServerError,
				reason: "We could not decode a property kind for id '\(self.kind.rawValue)'."
			)
		}
	}
	
}

extension Placemark.Property.Localized: Content {}
