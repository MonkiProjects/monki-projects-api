//
//  AuthController.swift
//  App
//
//  Created by Rémi Bardon on 08/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor
import Models
import DTOs

internal struct AuthController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let auth = routes.grouped("auth")
		
		let passwordProtected = auth.grouped(UserModel.authenticator())
		// POST /auth/login
		passwordProtected.post("login", use: login)
	}
	
	func login(req: Request) throws -> EventLoopFuture<UserModel.Token.Private> {
		let user = try req.auth.require(UserModel.self)
		let token = try user.generateToken()
		
		return token.save(on: req.db)
			.flatMap { token.$user.load(on: req.db) }
			.flatMapThrowing { try token.asPrivate() }
	}
	
}
