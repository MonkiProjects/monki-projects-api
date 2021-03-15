//
//  UserController.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Fluent
import Vapor

internal func routes(_ app: Application) throws {
	
	app.get { req in
		req.redirect(to: "https://github.com/MonkiProjects/mp-api-specs")
	}
	
	try app.routes.grouped("users").grouped("v1").register(collection: UserControllerV1())
	try app.routes.grouped("auth").grouped("v1").register(collection: AuthControllerV1())
	try app.routes.grouped("placemarks").grouped("v1").register(collection: PlacemarkControllerV1())
	
}
