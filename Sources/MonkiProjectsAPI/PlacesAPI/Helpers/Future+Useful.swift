//
//  Future+Useful.swift
//  PlacesAPI
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension EventLoopFuture where Value == [PlaceModel] {
	
	func asPublic(on req: Request) -> EventLoopFuture<[Place.Public]> {
		self
			.mapEach {
				$0.asPublic(on: req)
					// Map `Place.Public` to `Place.Public?` to allow `nil` recover
					.map(Optional.init)
					// Recover errors by mapping to `nil`
					.recover { _ in nil }
			}
			// Skip `nil` values
			.flatMapEachCompact(on: req.eventLoop) { $0 }
	}
	
}

extension EventLoopFuture where Value == Page<PlaceModel> {
	
	func asPublic(on req: Request) -> EventLoopFuture<Page<Place.Public>> {
		self
			.flatMap { page in
				req.eventLoop.makeSucceededFuture(page.items)
					.asPublic(on: req)
					.map { Page(items: $0, metadata: page.metadata) }
			}
	}
	
}

extension EventLoopFuture where Value == [PlaceModel.Submission.Review] {
	
	func asPublic(on req: Request) -> EventLoopFuture<[Place.Submission.Review.Public]> {
		self
			.flatMapEachCompact(on: req.eventLoop) {
				$0.asPublic(on: req)
					.recoverWithNil()
			}
	}
	
}

extension EventLoopFuture where Value == Page<PlaceModel.Submission.Review> {
	
	func asPublic(on req: Request) -> EventLoopFuture<Page<Place.Submission.Review.Public>> {
		self
			.flatMap { page in
				req.eventLoop.makeSucceededFuture(page.items)
					.asPublic(on: req)
					.map { Page(items: $0, metadata: page.metadata) }
			}
	}
	
}
