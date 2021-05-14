//
//  Future+Useful.swift
//  PlacemarksAPI
//
//  Created by Rémi Bardon on 27/02/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Vapor
import Fluent
import MonkiMapModel

extension EventLoopFuture where Value == [PlacemarkModel] {
	
	func asPublic(on req: Request) -> EventLoopFuture<[Placemark.Public]> {
		self
			.mapEach {
				$0.asPublic(on: req)
					// Map `Placemark.Public` to `Placemark.Public?` to allow `nil` recover
					.map(Optional.init)
					// Recover errors by mapping to `nil`
					.recover { _ in nil }
			}
			// Skip `nil` values
			.flatMapEachCompact(on: req.eventLoop) { $0 }
	}
	
}

extension EventLoopFuture where Value == Page<PlacemarkModel> {
	
	func asPublic(on req: Request) -> EventLoopFuture<Page<Placemark.Public>> {
		self
			.flatMap { page in
				req.eventLoop.makeSucceededFuture(page.items)
					.asPublic(on: req)
					.map { Page(items: $0, metadata: page.metadata) }
			}
	}
	
}

extension EventLoopFuture where Value == [PlacemarkModel.Submission.Review] {
	
	func asPublic(on req: Request) -> EventLoopFuture<[Placemark.Submission.Review.Public]> {
		self
			.flatMapEachCompact(on: req.eventLoop) {
				$0.asPublic(on: req)
					.recoverWithNil()
			}
	}
	
}

extension EventLoopFuture where Value == Page<PlacemarkModel.Submission.Review> {
	
	func asPublic(on req: Request) -> EventLoopFuture<Page<Placemark.Submission.Review.Public>> {
		self
			.flatMap { page in
				req.eventLoop.makeSucceededFuture(page.items)
					.asPublic(on: req)
					.map { Page(items: $0, metadata: page.metadata) }
			}
	}
	
}
