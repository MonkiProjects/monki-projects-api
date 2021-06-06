//
//  UserControllerV1.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import MonkiProjectsModel

internal struct UserControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		// GET /users/v1
		routes.get(use: listUsers)
		// POST /users/v1
		routes.post(use: createUser)
		
		routes.group(":userId") { user in
			// GET /users/v1/{userId}
			user.get(use: getUser)
			
			let tokenProtected = user.grouped(UserModel.Token.authenticator())
			// PATCH /users/v1/{userId}
			tokenProtected.patch(use: updateUser)
			// DELETE /users/v1/{userId}
			tokenProtected.delete(use: deleteUser)
		}
	}
	
	func listUsers(req: Request) throws -> EventLoopFuture<Fluent.Page<User.Public.Small>> {
		let pageRequest = try req.query.decode(PageRequest.self)
		let filters = try req.query.decode(User.QueryFilters.self)
		
		let usersFuture: EventLoopFuture<Fluent.Page<UserModel>>
		if filters.isEmpty {
			usersFuture = req.userService.listUsers(pageRequest: pageRequest)
		} else {
			usersFuture = req.userService.findUsers(with: filters, pageRequest: pageRequest)
		}
		
		return usersFuture
			.flatMapThrowing { page in
				try page.map { try $0.asPublicSmall() }
			}
	}
	
	func createUser(req: Request) throws -> EventLoopFuture<Response> {
		do {
			try User.Create.validate(content: req)
		} catch let error as ValidationsError {
			if error.failures.contains(where: { $0.key.stringValue == "username" }) {
				let reason = error.reason
					.replacingOccurrences(of: "(allowed: )", with: "(allowed: a-z, 0-9, '.', '_', '-')")
				throw Abort(error.status, headers: error.headers, reason: reason)
			}
			throw error
		}
		let create = try req.content.decode(User.Create.self)
		
		return req.userService.createUser(create)
			.flatMapThrowing { try $0.asPrivate() }
			.flatMap { $0.encodeResponse(status: .created, for: req) }
	}
	
	func getUser(req: Request) throws -> EventLoopFuture<User.Public.Full> {
		let userId = try req.parameters.require("userId", as: UUID.self)
		
		return req.userRepository.get(userId)
			.flatMapThrowing { try $0.asPublicFull() }
	}
	
	func updateUser(req: Request) throws -> EventLoopFuture<User.Public.Full> {
		let requesterId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let userId = try req.parameters.require("userId", as: UUID.self)
		let update = try req.content.decode(User.Update.self)
		
		return req.userService.updateUser(userId, with: update, requesterId: requesterId)
			.flatMapThrowing { try $0.asPublicFull() }
	}
	
	func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		let requesterId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let userId = try req.parameters.require("userId", as: UUID.self)
		
		return req.userService.deleteUser(userId, requesterId: requesterId)
			.transform(to: .noContent)
	}
	
}
