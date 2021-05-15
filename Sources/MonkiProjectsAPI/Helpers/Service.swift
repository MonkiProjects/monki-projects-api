//
//  Service.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

internal protocol Service {
	
	var db: Database { get }
	var app: Application { get }
	var eventLoop: EventLoop { get }
	var logger: Logger { get }
	
	func make<T>(
		_ init: (Database) -> T,
		database: Database?
	) -> T
	
	func make<T>(
		_ init: (Database, Application, EventLoop, Logger) -> T,
		database: Database?
	) -> T
	
}

extension Service {
	
	func make<T>(
		_ init: (Database) -> T,
		database: Database? = nil
	) -> T {
		`init`(database ?? self.db)
	}
	
	func make<T>(
		_ init: (Database, Application, EventLoop, Logger) -> T,
		database: Database? = nil
	) -> T {
		`init`(database ?? self.db, self.app, self.eventLoop, self.logger)
	}
	
}
