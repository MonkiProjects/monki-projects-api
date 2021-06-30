//
//  PlaceKindRepositoryFactory.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlaceKindRepositoryFactory {
	
	typealias Builder = (Database) -> PlaceKindRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlaceKindRepositoryKey: StorageKey {
		typealias Value = PlaceKindRepositoryFactory
	}
	
	var placeKindRepository: PlaceKindRepositoryFactory {
		get {
			self.storage[PlaceKindRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlaceKindRepositoryKey.self] = newValue
		}
	}
	
	func placeKindRepository(for database: Database) -> PlaceKindRepositoryProtocol {
		guard let make = self.placeKindRepository.make else {
			preconditionFailure("`app.placeKindRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placeKindRepository: PlaceKindRepositoryProtocol {
		self.application.placeKindRepository(for: self.db)
	}
	
}
