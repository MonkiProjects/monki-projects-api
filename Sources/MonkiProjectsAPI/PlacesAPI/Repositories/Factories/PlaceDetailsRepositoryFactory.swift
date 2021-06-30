//
//  PlaceDetailsRepositoryFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlaceDetailsRepositoryFactory {
	
	typealias Builder = (Database) -> PlaceDetailsRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlaceDetailsRepositoryKey: StorageKey {
		typealias Value = PlaceDetailsRepositoryFactory
	}
	
	var placeDetailsRepository: PlaceDetailsRepositoryFactory {
		get {
			self.storage[PlaceDetailsRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlaceDetailsRepositoryKey.self] = newValue
		}
	}
	
	func placeDetailsRepository(for database: Database) -> PlaceDetailsRepositoryProtocol {
		guard let make = self.placeDetailsRepository.make else {
			preconditionFailure("`app.placeDetailsRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placeDetailsRepository: PlaceDetailsRepositoryProtocol {
		self.application.placeDetailsRepository(for: self.db)
	}
	
}
