//
//  PlaceRepositoryFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 16/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlaceRepositoryFactory {
	
	typealias Builder = (Database) -> PlaceRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlaceRepositoryKey: StorageKey {
		typealias Value = PlaceRepositoryFactory
	}
	
	var placeRepository: PlaceRepositoryFactory {
		get {
			self.storage[PlaceRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlaceRepositoryKey.self] = newValue
		}
	}
	
	func placeRepository(for database: Database) -> PlaceRepositoryProtocol {
		guard let make = self.placeRepository.make else {
			preconditionFailure("`app.placeRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placeRepository: PlaceRepositoryProtocol {
		self.application.placeRepository(for: self.db)
	}
	
}
