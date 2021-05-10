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
		let passwordProtected = routes.grouped(UserModel.authenticator())
		// POST /auth/v1/login
		passwordProtected.post("login", use: login)
	}
	
	func login(req: Request) throws -> EventLoopFuture<User.Token.Private> {
		let user = try req.auth.require(UserModel.self, with: .basic, in: req)
		let token = try user.generateToken()
		
		return token.save(on: req.db)
			.flatMapThrowing { try token.asPrivate() }
	}
	
}
