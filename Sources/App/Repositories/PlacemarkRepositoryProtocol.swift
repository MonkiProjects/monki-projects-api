//
//  PlacemarkRepositoryProtocol.swift
//  Repositories
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import MonkiMapModel

public protocol PlacemarkRepositoryProtocol {
	
	func getAll() -> EventLoopFuture<[PlacemarkModel]>
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlacemarkModel>>
	
	func getAll(
		state: Placemark.State?,
		creator: UUID?
	) -> EventLoopFuture<[PlacemarkModel]>
	
	func getAllPaged(
		state: Placemark.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<PlacemarkModel>>
	
	func get(_ placemarkId: UUID) -> EventLoopFuture<PlacemarkModel>
	
}
