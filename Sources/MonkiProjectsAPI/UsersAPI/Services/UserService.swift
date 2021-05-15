//
//  UserService.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct UserService: UserServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func listUsers(pageRequest: PageRequest) -> EventLoopFuture<Fluent.Page<UserModel>> {
		self.app.userRepository(for: self.db).getAllPaged(pageRequest)
	}
	
	func createUser(_ create: User.Create) -> EventLoopFuture<UserModel> {
		// Do additional validations
		guard create.password == create.confirmPassword else {
			return self.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Passwords do not match"))
		}
		
		let checksFuture = EventLoopFuture.andAllSucceed([
			self.checkEmailAvailable(create.email),
			self.checkUsernameAvailable(create.username),
		], on: self.eventLoop)
		
		// Create User object
		let newUserFuture = checksFuture.flatMapThrowing { _ in
			try UserModel(
				username: create.username,
				displayName: create.displayName,
				email: create.email,
				passwordHash: Bcrypt.hash(create.password)
			)
		}
		
		// Save User in database
		return newUserFuture
			.passthroughAfter { $0.create(on: self.db) }
	}
	
	func updateUser(
		_ userId: UserModel.IDValue,
		with update: User.Update,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<UserModel> {
		// Do additional validations
		guard requesterId == userId else {
			return self.eventLoop.makeFailedFuture(
				Abort(.forbidden, reason: "You cannot update someone else's account!")
			)
		}
		
		let userFuture = self.app.userRepository(for: self.db).get(userId)
		
		let userUpdateFuture = userFuture.map { user -> UserModel in
			if let username = update.username {
				user.username = username
			}
			if let displayName = update.displayName {
				user.displayName = displayName
			}
			
			return user
		}
		
		return userUpdateFuture
			.passthroughAfter { $0.update(on: self.db) }
	}
	
	func deleteUser(
		_ userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let userFuture = self.app.userRepository(for: self.db).get(userId)
		
		// Do additional validations
		let guardAuthorizedFuture = userFuture.guard({ user in
			user.id == requesterId
		}, else: Abort(.forbidden, reason: "You cannot delete someone else's account!"))
		
		let deleteTokensFuture = UserModel.Token.query(on: self.db)
			.with(\.$user)
			.filter(\.$user.$id == userId)
			.all()
			.flatMap { $0.delete(on: self.db) }
		
		return guardAuthorizedFuture
			.passthroughAfter(deleteTokensFuture)
			.flatMap { $0.delete(on: self.db) }
	}
	
	/// Check for existing email
	func checkEmailAvailable(_ email: String) -> EventLoopFuture<Void> {
		self.app.userRepository(for: self.db)
			.unsafeGet(email: email)
			// Abort if existing email
			.guard(\.isNil, else: Abort(.forbidden, reason: "Email already taken"))
			.transform(to: ())
	}
	
	/// Check for existing username
	func checkUsernameAvailable(_ username: String) -> EventLoopFuture<Void> {
		self.app.userRepository(for: self.db)
			.unsafeGet(username: username)
			// Abort if existing username
			.guard(\.isNil, else: Abort(.forbidden, reason: "Username already taken"))
			.transform(to: ())
	}
	
}
