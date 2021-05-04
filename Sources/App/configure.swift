//
//  configure.swift
//  App
//
//  Created by Rémi Bardon on 07/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import FluentPostgresDriver
import QueuesRedisDriver

/// Configures your application
public func configure(_ app: Application) throws {
	// Configure encoder & decoder
	let encoder = JSONEncoder()
	encoder.keyEncodingStrategy = .convertToSnakeCase
	encoder.dateEncodingStrategy = .iso8601
	ContentConfiguration.global.use(encoder: encoder, for: .json)
	
	let decoder = JSONDecoder()
	decoder.keyDecodingStrategy = .convertFromSnakeCase
	decoder.dateDecodingStrategy = .iso8601
	ContentConfiguration.global.use(decoder: decoder, for: .json)
	
	// Register middlewares
	if app.environment == .development {
		app.middleware.use(RouteLoggingMiddleware(logLevel: .debug))
	}
	
	// Register database
	if app.environment != .testing {
		app.databases.use(.postgres(
			hostname: Environment.get("DATABASE_HOST") ?? "localhost",
			port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
			username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
			password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
			database: Environment.get("DATABASE_NAME") ?? "vapor_database"
		), as: .psql)
	}
	
	// Migrate database
	app.migrations.add(UserModel.Migrations.all)
	app.migrations.add(PlacemarkModel.Migrations.all)
	try app.autoMigrate().wait()
	
	// Configure Repositories
	app.placemarks.use { req in
		PlacemarkRepository(database: req.db)
	}
	app.placemarkKinds.use { req in
		PlacemarkKindRepository(database: req.db)
	}
	app.placemarkDetails.use { req in
		PlacemarkDetailsRepository(database: req.db)
	}
	app.placemarkProperties.use { req in
		PlacemarkPropertyRepository(database: req.db)
	}
	
	// Configure queues
	try app.queues.use(.redis(url: Environment.get("REDIS_URL") ?? "redis://127.0.0.1:6379"))
	
	if app.environment != .testing {
		// Start workers
		Jobs.addAll(to: app)
		try app.queues.startInProcessJobs(on: .default)
		try app.queues.startInProcessJobs(on: .placemarks)
//		try app.queues.startScheduledJobs()
	}
	
	// Register routes
	try routes(app)
}
