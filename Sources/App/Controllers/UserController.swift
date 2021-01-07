//
//  UserController.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let users = routes.grouped("users")
		users.get(use: index)
		users.post(use: create)
		users.group(":userID") { user in
			user.delete(use: delete)
		}
	}
	
	func index(req: Request) throws -> EventLoopFuture<[User]> {
		return User.query(on: req.db).all()
	}
	
	func create(req: Request) throws -> EventLoopFuture<User> {
		// Validate and decode datado {
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
		let emailCheckFuture = User.query(on: req.db)
			// Get User with same email
			.filter(\.$email == create.email).first()
			// Abort if existing email
			.guard({ $0 == nil }, else: Abort(.badRequest, reason: "Email or username already taken"))
		
		// Check for existing username
		let usernameCheckFuture = emailCheckFuture.flatMap { _ in
			User.query(on: req.db)
				// Get User with same username
				.filter(\.$username == create.username).first()
				// Abort if existing username
				.guard({ $0 == nil }, else: Abort(.badRequest, reason: "Email or username already taken"))
		}
		
		// Create User object
		let newUserFuture = usernameCheckFuture.flatMapThrowing { _ in
			try User(
				username: create.username,
				email: create.email,
				passwordHash: Bcrypt.hash(create.password)
			)
		}
		
		// Save User in database
		return newUserFuture.flatMap { user in
			user.create(on: req.db)
				.map { user }
		}
	}
	
	func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		return User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { $0.delete(on: req.db) }
			.transform(to: .ok)
	}
	
}
