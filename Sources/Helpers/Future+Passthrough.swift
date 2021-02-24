//
//  Future+Passthrough.swift
//  Helpers
//
//  Created by Rémi Bardon on 19/01/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor

extension EventLoopFuture {
	
	public func passthrough<T>(_ callback: @escaping (Value) -> T) -> EventLoopFuture<Value> {
		self.map(callback).transform(to: self)
	}
	
	public func passthrough<T>(_ callback: @escaping (Value) throws -> T) -> EventLoopFuture<Value> {
		self.flatMapThrowing(callback).transform(to: self)
	}
	
	public func passthroughAfter<T>(
		_ callback: @escaping (Value) -> EventLoopFuture<T>
	) -> EventLoopFuture<Value> {
		self.flatMap(callback).transform(to: self)
	}
	
	public func passthroughAfter<T>(
		_ callback: @escaping (Value) throws -> EventLoopFuture<T>
	) -> EventLoopFuture<Value> {
		self.flatMapThrowing(callback).flatMap { $0 }.transform(to: self)
	}
	
}
