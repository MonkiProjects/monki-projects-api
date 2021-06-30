//
//  PlaceDetailsServiceFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 07/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlaceDetailsServiceFactory {
	
	typealias Builder = (Database, Application, EventLoop, Logger) -> PlaceDetailsServiceProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlaceDetailsServiceKey: StorageKey {
		typealias Value = PlaceDetailsServiceFactory
	}
	
	var placeDetailsService: PlaceDetailsServiceFactory {
		get {
			self.storage[PlaceDetailsServiceKey.self] ?? .init()
		}
		set {
			self.storage[PlaceDetailsServiceKey.self] = newValue
		}
	}
	
	func placeDetailsService(
		database: Database,
		application: Application,
		eventLoop: EventLoop,
		logger: Logger
	) -> PlaceDetailsServiceProtocol {
		guard let make = self.placeDetailsService.make else {
			preconditionFailure("`app.placeDetailsService.use` required in `configure.swift`.")
		}
		return make(database, application, eventLoop, logger)
	}
	
}

extension Request {
	
	var placeDetailsService: PlaceDetailsServiceProtocol {
		self.application.placeDetailsService(
			database: self.db,
			application: self.application,
			eventLoop: self.eventLoop,
			logger: self.logger
		)
	}
	
}
