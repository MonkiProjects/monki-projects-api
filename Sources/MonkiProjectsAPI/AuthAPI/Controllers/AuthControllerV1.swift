//
//  AuthControllerV1.swift
//  AuthAPI
//
//  Created by Rémi Bardon on 08/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiProjectsModel

internal struct AuthControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let passwordProtected = routes.grouped([
			AuthErrorMiddleware(type: "Basic", realm: "Basic authentication required."),
			UserModel.authenticator(),
		])
		// POST /auth/v1/login
		passwordProtected.post("login", use: login)
		
		let tokenProtected = routes.grouped([
			AuthErrorMiddleware(type: "Bearer", realm: "Bearer authentication required."),
			UserModel.Token.authenticator(),
		])
		// GET /auth/v1/me
		tokenProtected.get("me", use: getMe)
	}
	
	func login(req: Request) throws -> EventLoopFuture<User.Token.Private> {
		let user = try req.auth.require(UserModel.self, with: .basic, in: req)
		let token = try user.generateToken()
		
		return token.save(on: req.db)
			.flatMapThrowing { try token.asPrivate() }
	}
	
	func getMe(req: Request) throws -> EventLoopFuture<User.Private> {
		let user = try req.auth.require(UserModel.self, with: .bearer, in: req)
		
		return req.eventLoop
			.tryFuture { try user.asPrivate() }
	}
	
}
