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
	
	func getAll() async throws -> [UserModel] {
		try await UserModel.query(on: self.database)
			.all()
	}
	
	func getAllPaged(
		_ pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<UserModel> {
		try await UserModel.query(on: self.database)
			.paginate(pageRequest)
	}
	
	func get(_ userId: UserModel.IDValue) async throws -> UserModel {
		try await UserModel.find(userId, on: self.database)
			.unwrap(or: Abort(.notFound, reason: "User not found"))
	}
	
	func unsafeGet(email: String) async throws -> UserModel? {
		try await UserModel.query(on: self.database)
			.filter(\.$email == email)
			.first()
	}
	
	func get(email: String) async throws -> UserModel {
		try await self.unsafeGet(email: email)
			.unwrap(or: Abort(.notFound, reason: "No user with email '\(email)' found."))
	}
	
	func unsafeGet(username: String) async throws -> UserModel? {
		try await UserModel.query(on: self.database)
			.filter(\.$username == username)
			.first()
	}
	
	func get(username: String) async throws -> UserModel {
		try await self.unsafeGet(username: username)
			.unwrap(or: Abort(.notFound, reason: "No user with username '\(username)' found."))
	}
	
}
