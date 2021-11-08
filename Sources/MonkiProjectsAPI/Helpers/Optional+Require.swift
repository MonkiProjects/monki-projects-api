//
//  Optional+Require.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 14/10/2020.
//  Copyright © 2020 Monki Projects. All rights reserved.
//

import Foundation

extension Optional {
	
	public func require() throws -> Wrapped {
		switch self {
		case .some(let wrapped):
			return wrapped
		case .none:
			throw NilError(Self.self)
		}
	}
	
	public func unwrap(or error: Error) throws -> Wrapped {
		switch self {
		case .some(let wrapped):
			return wrapped
		case .none:
			throw error
		}
	}
	
	public func `guard`(_ condition: (Self) -> Bool, `else` error: Error) throws {
		guard condition(self) else {
			throw error
		}
	}
	
}
