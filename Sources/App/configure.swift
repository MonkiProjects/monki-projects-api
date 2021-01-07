//
//  UserController.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
	// uncomment to serve files from /Public folder
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	
	app.databases.use(.postgres(
		hostname: Environment.get("DATABASE_HOST") ?? "localhost",
		port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
		username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
		password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
		database: Environment.get("DATABASE_NAME") ?? "vapor_database"
	), as: .psql)
	
	if app.environment == .testing {
		try app.autoRevert().wait()
	}
	
	app.migrations.add(User.Migrations.all)
	
	try app.autoMigrate().wait()
	
	// register routes
	try routes(app)
}
