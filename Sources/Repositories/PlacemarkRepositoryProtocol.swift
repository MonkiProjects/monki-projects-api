//
//  PlacemarkRepositoryProtocol.swift
//  Repositories
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import MonkiMapModel
import Fluent

public protocol PlacemarkRepositoryProtocol {
	
	func all() -> EventLoopFuture<[Placemark.Public]>
	
	func paged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<Placemark.Public>>
	
	func all(
		state: Placemark.State?,
		creator: UUID?
	) -> EventLoopFuture<[Placemark.Public]>
	
	func paged(
		state: Placemark.State?,
		creator: UUID?,
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Page<Placemark.Public>>
	
}
