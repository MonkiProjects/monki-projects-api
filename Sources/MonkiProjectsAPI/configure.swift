//
//  configure.swift
//  MonkiProjectsAPI
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
	app.migrations.add(PlaceModel.Migrations.all)
	if app.environment == .development && Environment.get("WIPE_DATABASE") == "true" {
		try app.autoRevert().wait()
	}
	try app.autoMigrate().wait()
	
	// Configure repositories
	app.userRepository.use(UserRepository.init(database:))
	app.userTokenRepository.use(UserTokenRepository.init(database:))
	app.placeRepository.use(PlaceRepository.init(database:))
	app.placeKindRepository.use(PlaceKindRepository.init(database:))
	app.placeDetailsRepository.use(PlaceDetailsRepository.init(database:))
	app.placePropertyRepository.use(PlacePropertyRepository.init(database:))
	
	// Configure services
	app.userService.use(UserService.init(db:app:eventLoop:logger:))
	app.userTokenService.use(UserTokenService.init(db:app:eventLoop:logger:))
	app.authorizationService.use(AuthorizationService.init(db:app:eventLoop:logger:))
	app.placeService.use(PlaceService.init(db:app:eventLoop:logger:))
	app.placeDetailsService.use(PlaceDetailsService.init(db:app:eventLoop:logger:))
	
	// Configure jobs
	try app.queues.use(.redis(url: Environment.get("REDIS_URL") ?? "redis://127.0.0.1:6379"))
	Jobs.addAll(to: app)
	
	if Environment.get("START_IN_PROCESS_JOBS") == "true" {
		try app.queues.startInProcessJobs(on: .default)
		try app.queues.startInProcessJobs(on: .places)
	} else {
		app.logger.info("Not starting in process jobs, enable them with `START_IN_PROCESS_JOBS`")
	}
	if Environment.get("START_SCHEDULED_JOBS") == "true" {
		try app.queues.startScheduledJobs()
	} else {
		app.logger.info("Not starting scheduled jobs, enable them with `START_SCHEDULED_JOBS`")
	}
	
	// Register routes
	try routes(app)
}
