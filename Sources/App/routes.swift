//
//  UserController.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

func routes(_ app: Application) throws {
	
	app.get { req in
		return req.redirect(to: "https://github.com/MonkiProjects/mp-api-specs")
	}
	
	let v1 = app.routes.grouped("v1")
	
	try v1.register(collection: UserController())
	try v1.register(collection: AuthController())
	
}
