//
//  PlacemarkDetailsRepositoryProtocol.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

public protocol PlacemarkDetailsRepositoryProtocol {
	
	func get(for placemarkId: UUID) -> EventLoopFuture<PlacemarkModel.Details>
	
	func unsafeGetAll(for placemarkId: UUID) -> EventLoopFuture<[PlacemarkModel.Details]>
	
	func delete(for placemarkId: UUID, force: Bool) -> EventLoopFuture<Void>
	
}
