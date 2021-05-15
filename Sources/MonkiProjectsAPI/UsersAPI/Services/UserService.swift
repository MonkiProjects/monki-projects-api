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

internal struct UserService: Service, UserServiceProtocol {
	
	let db: Database
	let app: Application
	let eventLoop: EventLoop
	let logger: Logger
	
	func listUsers(pageRequest: PageRequest) -> EventLoopFuture<Fluent.Page<UserModel>> {
		self.make(self.app.userRepository).getAllPaged(pageRequest)
	}
	
	func createUser(_ create: User.Create) -> EventLoopFuture<UserModel> {
		let validationsFuture = EventLoopFuture.andAllSucceed([
			self.eventLoop.tryFuture {
				guard create.password == create.confirmPassword else {
					throw Abort(.badRequest, reason: "Passwords do not match")
				}
			},
			self.checkEmailAvailable(create.email),
			self.checkUsernameAvailable(create.username),
		], on: self.eventLoop)
		
		func newUserFuture() -> EventLoopFuture<UserModel> {
			self.eventLoop.tryFuture {
				try UserModel(
					username: create.username,
					displayName: create.displayName,
					email: create.email,
					passwordHash: Bcrypt.hash(create.password)
				)
			}
		}
		
		return validationsFuture
			// Create user object
			.flatMap(newUserFuture)
			// Save user in database
			.passthroughAfter { $0.create(on: self.db) }
	}
	
	func updateUser(
		_ userId: UserModel.IDValue,
		with update: User.Update,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<UserModel> {
		var validations: [EventLoopFuture<Void>] = [
			self.make(self.app.authorizationService)
				.user(requesterId, can: .update, user: userId)
				.guard(else: Abort(.forbidden, reason: "You cannot update someone else's account!"))
				.transform(to: ()),
		]
		if let username = update.username {
			validations.append(self.checkUsernameAvailable(username))
			// FIXME: Validate username
		}
		// FIXME: Validate displayName
		let validationsFuture = EventLoopFuture.andAllSucceed(validations, on: self.eventLoop)
		
		func userFuture() -> EventLoopFuture<UserModel> {
			self.make(self.app.userRepository).get(userId)
		}
		
		func updateUser(_ user: UserModel) -> UserModel {
			if let username = update.username {
				user.username = username
			}
			if let displayName = update.displayName {
				user.displayName = displayName
			}
			
			return user
		}
		
		return validationsFuture
			.flatMap(userFuture)
			.map(updateUser)
			.passthroughAfter { $0.update(on: self.db) }
	}
	
	func deleteUser(
		_ userId: UserModel.IDValue,
		requesterId: UserModel.IDValue
	) -> EventLoopFuture<Void> {
		let validationsFuture = EventLoopFuture.andAllSucceed([
			self.make(self.app.authorizationService)
				.user(requesterId, can: .delete, user: userId)
				.guard(else: Abort(.forbidden, reason: "You cannot delete someone else's account!")),
		], on: self.eventLoop)
		
		func userFuture() -> EventLoopFuture<UserModel> {
			self.make(self.app.userRepository).get(userId)
		}
		
		func deleteTokensFuture(for user: UserModel) -> EventLoopFuture<Void> {
			self.make(self.app.userTokenService)
				.deleteAllTokens(for: userId, requesterId: requesterId)
		}
		
		return validationsFuture
			.flatMap(userFuture)
			.passthroughAfter(deleteTokensFuture)
			.flatMap { $0.delete(on: self.db) }
	}
	
	func checkEmailAvailable(_ email: String) -> EventLoopFuture<Void> {
		self.make(self.app.userRepository)
			.unsafeGet(email: email)
			// Abort if existing email
			.guard(\.isNil, else: Abort(.forbidden, reason: "Email already taken"))
			.transform(to: ())
	}
	
	func checkUsernameAvailable(_ username: String) -> EventLoopFuture<Void> {
		self.make(self.app.userRepository)
			.unsafeGet(username: username)
			// Abort if existing username
			.guard(\.isNil, else: Abort(.forbidden, reason: "Username already taken"))
			.transform(to: ())
	}
	
}
