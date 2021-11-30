//
//  UserService.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import FluentSQL
import MonkiProjectsModel

internal struct UserService: Service, UserServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func listUsers(pageRequest: Fluent.PageRequest) async throws -> Fluent.Page<UserModel> {
		try await self.make(self.app.userRepository).getAllPaged(pageRequest)
	}
	
	func createUser(_ create: User.Create) async throws -> UserModel {
		guard create.password == create.confirmPassword else {
			throw Abort(.badRequest, reason: "Passwords do not match")
		}
		try await self.checkEmailAvailable(create.email)
		try await self.checkUsernameAvailable(create.username)
		
		// Create user object
		let user = try UserModel(
			username: create.username,
			displayName: create.displayName,
			email: create.email,
			passwordHash: Bcrypt.hash(create.password)
		)
		
		// Save user in database
		try await user.create(on: self.db)
		
		return user
	}
	
	func updateUser(
		_ userId: UserModel.IDValue,
		with update: User.Update,
		requesterId: UserModel.IDValue
	) async throws -> UserModel {
		// Perform validations
		let canUpdate: Bool = await self.make(self.app.authorizationService)
			.user(requesterId, can: .update, user: userId)
		guard canUpdate else {
			throw Abort(.forbidden, reason: "You cannot update someone else's account!")
		}
		if let username = update.username {
			try await self.checkUsernameAvailable(username)
			// FIXME: Validate username
		}
		// FIXME: Validate displayName
		
		let user: UserModel = try await self.make(self.app.userRepository).get(userId)
		
		if let username = update.username {
			user.username = username
		}
		if let displayName = update.displayName {
			user.displayName = displayName
		}
		
		try await user.update(on: self.db)
		return user
	}
	
	func findUsers(
		with filters: User.QueryFilters,
		pageRequest: Fluent.PageRequest
	) async throws -> Fluent.Page<UserModel> {
		var query = UserModel.query(on: self.db)
		
		if let username = filters.username?.lowercased() {
			if self.db is SQLDatabase {
				query = query.filter(.sql(raw: "LOWER(username) LIKE '%\(username)%'"))
			} else {
				throw Abort(.internalServerError, reason: "Database is not SQL")
			}
		}
		if let displayName = filters.displayName?.lowercased() {
			if self.db is SQLDatabase {
				query = query.filter(.sql(raw: "LOWER(display_name) LIKE '%\(displayName)%'"))
			} else {
				throw Abort(.internalServerError, reason: "Database is not SQL")
			}
		}
		
		return try await query.paginate(pageRequest)
	}
	
	func deleteUser(
		_ userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) async throws {
		// Perform validations
		let canDelete: Bool = await self.make(self.app.authorizationService)
			.user(requesterId, can: .delete, user: userId)
		guard canDelete else {
			throw Abort(.forbidden, reason: "You cannot delete someone else's account!")
		}
		
		let user: UserModel = try await self.make(self.app.userRepository).get(userId)
		
		// Delete tokens
		try await self.make(self.app.userTokenService)
			.deleteAllTokens(for: userId, requesterId: requesterId)
		
		try await user.delete(on: self.db)
	}
	
	func checkEmailAvailable(_ email: String) async throws {
		let user: UserModel? = try await self.make(self.app.userRepository).unsafeGet(email: email)
		
		// Abort if existing email
		guard user == nil else {
			throw Abort(.forbidden, reason: "Email already taken")
		}
	}
	
	func checkUsernameAvailable(_ username: String) async throws {
		let user: UserModel? = try await self.make(self.app.userRepository).unsafeGet(username: username)
		
		// Abort if existing username
		guard user == nil else {
			throw Abort(.forbidden, reason: "Username already taken")
		}
	}
	
}
