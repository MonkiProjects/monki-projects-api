//
//  AuthController.swift
//  App
//
//  Created by Rémi Bardon on 08/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

struct AuthController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		let auth = routes.grouped("auth")
		
		let passwordProtected = auth.grouped(User.authenticator())
		/// `POST /auth/login`
		passwordProtected.post("login", use: login)
	}
	
	func login(req: Request) throws -> EventLoopFuture<User.Token> {
		let user = try req.auth.require(User.self)
		let token = try user.generateToken()
		
		return token.save(on: req.db)
			.map { token }
	}
	
}
