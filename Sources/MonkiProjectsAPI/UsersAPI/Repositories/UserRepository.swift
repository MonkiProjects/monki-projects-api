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
		_ pageRequest: Fluent.PageRequest
	) -> EventLoopFuture<Fluent.Page<UserModel>> {
		UserModel.query(on: self.database)
			.paginate(pageRequest)
	}
	
	func get(_ userId: UserModel.IDValue) -> EventLoopFuture<UserModel> {
		UserModel.find(userId, on: self.database)
			.unwrap(or: Abort(.notFound, reason: "User not found"))
	}
	
	func unsafeGet(email: String) -> EventLoopFuture<UserModel?> {
		UserModel.query(on: self.database)
			.filter(\.$email == email)
			.first()
	}
	
	func get(email: String) -> EventLoopFuture<UserModel> {
		self.unsafeGet(email: email)
			.unwrap(or: Abort(.notFound, reason: "No user with email '\(email)' found."))
	}
	
	func unsafeGet(username: String) -> EventLoopFuture<UserModel?> {
		UserModel.query(on: self.database)
			.filter(\.$username == username)
			.first()
	}
	
	func get(username: String) -> EventLoopFuture<UserModel> {
		self.unsafeGet(username: username)
			.unwrap(or: Abort(.notFound, reason: "No user with username '\(username)' found."))
	}
	
}
