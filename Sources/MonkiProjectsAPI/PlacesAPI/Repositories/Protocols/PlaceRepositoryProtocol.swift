//
//  PlaceRepositoryProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import MonkiMapModel

public protocol PlaceRepositoryProtocol {
	
	func getAll() -> EventLoopFuture<[PlaceModel]>
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlaceModel>>
	
	func getAll(
		state: Place.State?,
		creator: UUID?
	) -> EventLoopFuture<[PlaceModel]>
	
	func getAllPaged(
		state: Place.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlaceModel>>
	
	func get(_ placeId: UUID) -> EventLoopFuture<PlaceModel>
	
}
