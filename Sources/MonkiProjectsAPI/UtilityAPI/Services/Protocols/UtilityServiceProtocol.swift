//
//  UtilityServiceProtocol.swift
//  UtilityAPI
//
//  Created by Rémi Bardon on 13/01/2022.
//  Copyright © 2022 Monki Projects. All rights reserved.
//

import Fluent
import Foundation
import MonkiMapModel

public protocol UtilityServiceProtocol {
	
	func getCoordinatesFromGoogleMapsUrl(_ url: URL) async throws -> Coordinate?
	
}
