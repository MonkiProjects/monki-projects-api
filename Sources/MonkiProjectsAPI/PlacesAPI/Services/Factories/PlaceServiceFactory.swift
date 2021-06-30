//
//  PlaceServiceFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlaceServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> PlaceServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlaceServiceKey: StorageKey {
		typealias Value = PlaceServiceFactory
	}
	
	var placeService: PlaceServiceFactory {
		get {
			self.storage[PlaceServiceKey.self] ?? .init()
		}
		set {
			self.storage[PlaceServiceKey.self] = newValue
		}
	}
	
	func placeService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> PlaceServiceProtocol {
		guard let make = self.placeService.make else {
			preconditionFailure("`app.placeService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var placeService: PlaceServiceProtocol {
		self.application.placeService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
