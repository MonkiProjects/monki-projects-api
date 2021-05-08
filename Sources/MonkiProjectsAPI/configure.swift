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
	
	// Configure repositories
	app.placemarkRepository.use(PlacemarkRepository.init(database:))
	app.placemarkKindRepository.use(PlacemarkKindRepository.init(database:))
	app.placemarkDetailsRepository.use(PlacemarkDetailsRepository.init(database:))
	app.placemarkPropertyRepository.use(PlacemarkPropertyRepository.init(database:))
	
	// Configure services
	app.placemarkService.use(PlacemarkService.init(db:app:eventLoop:logger:))
	app.placemarkDetailsService.use(PlacemarkDetailsService.init(db:app:eventLoop:logger:))
	
	// Configure jobs
	try app.queues.use(.redis(url: Environment.get("REDIS_URL") ?? "redis://127.0.0.1:6379"))
	Jobs.addAll(to: app)
	
	if Environment.get("START_IN_PROCESS_JOBS") == "true" {
		try app.queues.startInProcessJobs(on: .default)
		try app.queues.startInProcessJobs(on: .placemarks)
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
