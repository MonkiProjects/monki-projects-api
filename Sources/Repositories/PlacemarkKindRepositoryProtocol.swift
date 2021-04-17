//
//  PlacemarkKindRepositoryProtocol.swift
//  Repositories
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import MonkiMapModel
import Models

public protocol PlacemarkKindRepositoryProtocol {
	
	func get(humanId: String) -> EventLoopFuture<PlacemarkModel.Kind>
	
	func getAll() -> EventLoopFuture<[PlacemarkModel.Kind]>
	
}
