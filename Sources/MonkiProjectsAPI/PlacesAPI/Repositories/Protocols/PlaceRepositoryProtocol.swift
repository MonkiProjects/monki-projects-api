//
//  PlaceRepositoryProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import MonkiProjectsModel
import MonkiMapModel

public protocol PlaceRepositoryProtocol {
	
	func getAll() async throws -> [PlaceModel]
	
	func getAllPaged(
		_ pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<PlaceModel>
	
	func getAll(
		state: Place.State?,
		creator: User.ID?
	) async throws -> [PlaceModel]
	
	func getAllPaged(
		state: Place.State?,
		creator: User.ID?,
		_ pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<PlaceModel>
	
	func get(_ placeId: Place.ID) async throws -> PlaceModel
	
}
