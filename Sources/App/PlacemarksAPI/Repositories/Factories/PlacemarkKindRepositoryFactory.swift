//
//  PlacemarkKindRepositoryFactory.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkKindRepositoryFactory {
	
	typealias Builder = (Database) -> PlacemarkKindRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkKindRepositoryKey: StorageKey {
		typealias Value = PlacemarkKindRepositoryFactory
	}
	
	var placemarkKindRepository: PlacemarkKindRepositoryFactory {
		get {
			self.storage[PlacemarkKindRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkKindRepositoryKey.self] = newValue
		}
	}
	
	func placemarkKindRepository(for database: Database) -> PlacemarkKindRepositoryProtocol {
		guard let make = self.placemarkKindRepository.make else {
			preconditionFailure("`app.placemarkKindRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var placemarkKindRepository: PlacemarkKindRepositoryProtocol {
		self.application.placemarkKindRepository(for: self.db)
	}
	
}
