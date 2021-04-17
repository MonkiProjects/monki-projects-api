//
//  PlacemarkKindRepository+Factory.swift
//  App
//
//  Created by Rémi Bardon on 17/04/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Repositories
import Vapor

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct PlacemarkKindRepositoryFactory {
	
	var make: ((Request) -> PlacemarkKindRepositoryProtocol)?
	
	mutating func use(_ make: @escaping ((Request) -> PlacemarkKindRepositoryProtocol)) {
		self.make = make
	}
	
}

extension Application {
	
	private struct PlacemarkKindRepositoryKey: StorageKey {
		typealias Value = PlacemarkKindRepositoryFactory
	}
	
	var placemarkKinds: PlacemarkKindRepositoryFactory {
		get {
			self.storage[PlacemarkKindRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[PlacemarkKindRepositoryKey.self] = newValue
		}
	}
	
}

extension Request {
	
	var placemarkKinds: PlacemarkKindRepositoryProtocol {
		guard let make = self.application.placemarkKinds.make else {
			preconditionFailure("`app.placemarkKinds.use` required in `configure.swift`.")
		}
		return make(self)
	}
	
}
