//
//  UserController.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import Models
import MonkiProjectsModel

internal struct UserController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let users = routes.grouped("users")
		
		// GET /users
		users.get(use: listUsers)
		// POST /users
		users.post(use: createUser)
		users.group(":userId") { user in
			// GET /users/{userId}
			user.get(use: getUser)
			
			let tokenProtected = user.grouped(UserModel.Token.authenticator())
			// DELETE /users/{userId}
			tokenProtected.delete(use: deleteUser)
		}
	}
	
	func listUsers(req: Request) throws -> EventLoopFuture<[User.Public.Small]> {
		UserModel.query(on: req.db)
			.all()
			.flatMapEachThrowing { try $0.asPublicSmall() }
	}
	
	func createUser(req: Request) throws -> EventLoopFuture<Response> {
		// Validate and decode data
		do {
			try User.Create.validate(content: req)
		} catch {
			// Fix error message not showing '.' and '_' for some reason
			var message = String(describing: error)
			let suffix = "(allowed: a-z, 0-9)"
			if message.hasSuffix(suffix) {
				message.removeLast(suffix.count)
				message.append("(allowed: a-z, 0-9, '.', '_')")
				throw Abort(.badRequest, reason: message)
			}
			throw error
		}
		let create = try req.content.decode(User.Create.self)
		
		// Do additional validations
		guard create.password == create.confirmPassword else {
			throw Abort(.badRequest, reason: "Passwords do not match")
		}
		
		// Check for existing email
		let emailCheckFuture = UserModel.query(on: req.db)
			// Get User with same email
			.filter(\.$email == create.email)
			.first()
			// Abort if existing email
			.guard(\.isNil, else: Abort(.forbidden, reason: "Email or username already taken"))
		
		// Check for existing username
		let usernameCheckFuture = emailCheckFuture.flatMap { _ in
			UserModel.query(on: req.db)
				// Get User with same username
				.filter(\.$username == create.username)
				.first()
				// Abort if existing username
				.guard(\.isNil, else: Abort(.forbidden, reason: "Email or username already taken"))
		}
		
		// Create User object
		let newUserFuture = usernameCheckFuture.flatMapThrowing { _ in
			try UserModel(
				username: create.username,
				email: create.email,
				passwordHash: Bcrypt.hash(create.password)
			)
		}
		
		// Save User in database
		return newUserFuture.flatMap { user in
			user.create(on: req.db)
				.flatMapThrowing { try user.asPrivate() }
				.flatMap { $0.encodeResponse(status: .created, for: req) }
		}
	}
	
	func getUser(req: Request) throws -> EventLoopFuture<User.Public.Full> {
		let userId = try req.parameters.require("userId", as: UUID.self)
		return UserModel.find(userId, on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMapThrowing { try $0.asPublicFull() }
	}
	
	func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		let userId = try req.parameters.require("userId", as: UUID.self)
		
		// Do additional validations
		guard user.id == userId else {
			throw Abort(.forbidden, reason: "You cannot delete someone else's account!")
		}
		
		let deleteTokensFuture = UserModel.Token.query(on: req.db)
			.with(\.$user)
			.filter(\.$user.$id == userId)
			.all()
			.flatMap { $0.delete(on: req.db) }
		
		let deleteUserFuture = deleteTokensFuture.flatMap {
			UserModel.find(userId, on: req.db)
				.unwrap(or: Abort(.notFound))
				.flatMap { $0.delete(on: req.db) }
		}
		
		return deleteUserFuture.transform(to: .ok)
	}
	
}
