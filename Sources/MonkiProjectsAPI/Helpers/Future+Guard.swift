//
//  Future+Guard.swift
//  MonkiProjectsAPI
//
//  Created by Rémi Bardon on 15/05/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import NIO

extension EventLoopFuture where Value == Bool {
	
	public func `guard`(else error: @escaping @autoclosure () -> Error) -> EventLoopFuture<Value> {
		self.guard({ $0 }, else: error())
	}
	
}
