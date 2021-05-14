//
//  UserRepositoryFactory.swift
//  UsersAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent

// For more information, see <https://docs.vapor.codes/4.0/upgrading/#repositories>

internal struct UserRepositoryFactory {
	
	typealias Builder = (Database) -> UserRepositoryProtocol
	
	var make: Builder?
	
	mutating func use(_ make: @escaping Builder) {
		self.make = make
	}
	
}

extension Application {
	
	private struct UserRepositoryKey: StorageKey {
		typealias Value = UserRepositoryFactory
	}
	
	var userRepository: UserRepositoryFactory {
		get {
			self.storage[UserRepositoryKey.self] ?? .init()
		}
		set {
			self.storage[UserRepositoryKey.self] = newValue
		}
	}
	
	func userRepository(for database: Database) -> UserRepositoryProtocol {
		guard let make = self.userRepository.make else {
			preconditionFailure("`app.userRepository.use` required in `configure.swift`.")
		}
		return make(database)
	}
	
}

extension Request {
	
	var userRepository: UserRepositoryProtocol {
		self.application.userRepository(for: self.db)
	}
	
}
