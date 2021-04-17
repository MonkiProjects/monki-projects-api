//
//  PlacemarkPropertyRepository+Factory.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Repositories
import Vapor

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkPropertyRepositoryFactory {
	
	var make: ((Request) -> PlacemarkPropertyRepositoryProtocol)?
	
	mutating func use(_ make: @escaping ((Request) -> PlacemarkPropertyRepositoryProtocol)) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkPropertyRepositoryKey: StorageKey {
		typealias Value = PlacemarkPropertyRepositoryFactory
	}
	
	var placemarkProperties: PlacemarkPropertyRepositoryFactory {
		get {
			self.storage[PlacemarkPropertyRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkPropertyRepositoryKey.self] = newValue
		}
	}
	
}

extension Request {
	
	var placemarkProperties: PlacemarkPropertyRepositoryProtocol {
		guard let make = self.application.placemarkProperties.make else {
			preconditionFailure("`app.placemarkProperties.use` required in `configure.swift`.")
		}
		return make(self)
	}
	
}
