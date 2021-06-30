//
//  PlaceKindRepositoryProtocol.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel

public protocol PlaceKindRepositoryProtocol {
	
	func get(humanId: String) -> EventLoopFuture<PlaceModel.Kind>
	
	func getAll() -> EventLoopFuture<[PlaceModel.Kind]>
	
}
