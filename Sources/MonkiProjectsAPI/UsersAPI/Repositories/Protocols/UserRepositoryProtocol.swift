//
//  UserRepositoryProtocol.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation
import Fluent
import MonkiProjectsModel

public protocol UserRepositoryProtocol {
	
	func getAll() -> EventLoopFuture<[UserModel]>
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Fluent.Page<UserModel>>
	
	func get(_ userId: UserModel.IDValue) -> EventLoopFuture<UserModel>
	
}
