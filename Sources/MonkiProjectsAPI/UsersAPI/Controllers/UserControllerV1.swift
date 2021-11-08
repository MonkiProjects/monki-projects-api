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
			
			let tokenProtectedUser = user.grouped([
				AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
				UserModel.Token.authenticator(),
			])
			// PATCH /users/v1/{userId}
			tokenProtectedUser.patch(use: updateUser)
			// DELETE /users/v1/{userId}
			tokenProtectedUser.delete(use: deleteUser)
		}
	}
	
	func listUsers(req: Request) async throws -> Fluent.Page<User.Public.Small> {
		let pageRequest = try req.query.decode(PageRequest.self)
		let filters = try req.query.decode(User.QueryFilters.self)
		
		let users: Fluent.Page<UserModel>
		if filters.isEmpty {
			users = try await req.userService.listUsers(pageRequest: pageRequest)
		} else {
			users = try await req.userService.findUsers(with: filters, pageRequest: pageRequest)
		}
		
		return try users.asPublicSmall()
	}
	
	func createUser(req: Request) async throws -> Response {
		do {
			try User.Create.validate(content: req)
		} catch let error as ValidationsError {
			// TODO: Remove this workaround
			if error.failures.contains(where: { $0.key.stringValue == "username" }) {
				let reason = error.reason
					.replacingOccurrences(of: "(allowed: )", with: "(allowed: a-z, 0-9, '.', '_', '-')")
				throw Abort(error.status, headers: error.headers, reason: reason)
			}
			throw error
		}
		let create = try req.content.decode(User.Create.self)
		
		let user = try await req.userService.createUser(create)
		
		return try await user.asPrivate().encodeResponse(status: .created, for: req)
	}
	
	func getUser(req: Request) async throws -> User.Public.Full {
		let userId = try req.parameters.require("userId", as: User.ID.self)
		
		let user = try await req.userRepository.get(userId)
		
		return try user.asPublicFull()
	}
	
	func updateUser(req: Request) async throws -> User.Public.Full {
		let requesterId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let userId = try req.parameters.require("userId", as: User.ID.self)
		let update = try req.content.decode(User.Update.self)
		
		let user = try await req.userService.updateUser(userId, with: update, requesterId: requesterId)
		
		return try user.asPublicFull()
	}
	
	func deleteUser(req: Request) async throws -> HTTPStatus {
		let requesterId = try req.auth.require(UserModel.self, with: .bearer, in: req).requireID()
		let userId = try req.parameters.require("userId", as: User.ID.self)
		
		try await req.userService.deleteUser(userId, requesterId: requesterId)
		
		return HTTPStatus.noContent
	}
	
}
