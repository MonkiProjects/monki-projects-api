//
//  UserRepository.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct UserRepository: UserRepositoryProtocol {
	
	let database: Database
	
	init(database: Database) {
		self.database = database
	}
	
	func getAll() -> EventLoopFuture<[UserModel]> {
		UserModel.query(on: self.database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: PageRequest
	) -> EventLoopFuture<Fluent.Page<UserModel>> {
		UserModel.query(on: self.database)
			.paginate(pageRequest)
	}
	
	func get(_ userId: UserModel.IDValue) -> EventLoopFuture<UserModel> {
		UserModel.find(userId, on: self.database)
			.unwrap(or: Abort(.notFound, reason: "User not found"))
	}
	
}
