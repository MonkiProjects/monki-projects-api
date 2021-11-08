//
//  PlaceDetailsRepositoryProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlaceDetailsRepositoryProtocol {
	
	func get(for placeId: Place.ID) async throws -> PlaceModel.Details
	
	func unsafeGetAll(for placeId: Place.ID) async throws -> [PlaceModel.Details]
	
	func delete(for placeId: Place.ID, force: Bool) async throws
	
}
