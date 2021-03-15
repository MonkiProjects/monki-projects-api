//
//  AuthControllerV1.swift
//  App
//
//  Created by Rémi Bardon on 08/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import Models
import DTOs

internal struct AuthControllerV1: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let passwordProtected = routes.grouped(UserModel.authenticator())
		// POST /auth/v1/login
		passwordProtected.post("login", use: login)
	}
	
	func login(req: Request) throws -> EventLoopFuture<UserModel.Token.Private> {
		let user = try req.auth.require(UserModel.self, with: .basic, in: req)
		let token = try user.generateToken()
		
		return token.save(on: req.db)
			.flatMap { token.asPrivate(on: req.db) }
	}
	
}
