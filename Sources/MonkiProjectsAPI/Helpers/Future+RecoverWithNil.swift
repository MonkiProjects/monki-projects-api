//
//  Future+RecoverWithNil.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 14/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension EventLoopFuture {
	
	func recoverWithNil() -> EventLoopFuture<Value?> {
		self.map(Optional.init) 	// Map `Value` to `Value?` to allow `nil` recover
			.recover { _ in nil } 	// Recover errors by mapping to `nil`
	}
	
}
