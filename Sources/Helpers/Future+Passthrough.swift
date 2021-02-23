//
//  Future+Passthrough.swift
//  Helpers
//
//  Created by Rémi Bardon on 19/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

public extension EventLoopFuture {
	
	func passthrough<T>(_ callback: @escaping (Value) -> T) -> EventLoopFuture<Value> {
		return self.map(callback).transform(to: self)
	}
	
	func passthrough<T>(_ callback: @escaping (Value) throws -> T) -> EventLoopFuture<Value> {
		return self.flatMapThrowing(callback).transform(to: self)
	}
	
	func passthroughAfter<T>(
		_ callback: @escaping (Value) -> EventLoopFuture<T>
	) -> EventLoopFuture<Value> {
		return self.flatMap(callback).transform(to: self)
	}
	
	func passthroughAfter<T>(
		_ callback: @escaping (Value) throws -> EventLoopFuture<T>
	) -> EventLoopFuture<Value> {
		return self.flatMapThrowing(callback).flatMap { $0 }.transform(to: self)
	}
	
}
